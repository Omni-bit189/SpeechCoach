import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/session.dart';
import '../services/api_service.dart';

enum RecordingState { idle, recording, uploading, done, error }

class SessionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AudioRecorder _recorder = AudioRecorder();

  RecordingState state = RecordingState.idle;
  int elapsedSeconds = 0;
  int targetSeconds = 120;       // default 2 min session
  double uploadProgress = 0;
  SpeechSession? lastSession;
  String? errorMessage;

  List<TopicItem> topics = [];
  TopicItem? selectedTopic;
  bool isLoadingTopics = false;

  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSubscription;
  String? _recordingPath;
  double currentAmplitude = 0.0;

  bool get isRecording => state == RecordingState.recording;

  SessionProvider() {
    loadTopics();
  }

  Future<void> loadTopics() async {
    isLoadingTopics = true;
    notifyListeners();
    topics = await _api.getTopics();
    isLoadingTopics = false;
    notifyListeners();
  }

  void selectTopic(TopicItem? topic) {
    selectedTopic = topic;
    notifyListeners();
  }

  void setTarget(int seconds) {
    targetSeconds = seconds;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) return;

    if (kIsWeb) {
      _recordingPath = '';
    } else {
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    final config = kIsWeb
        ? const RecordConfig(encoder: AudioEncoder.opus)
        : const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);

    await _recorder.start(config, path: _recordingPath!);

    elapsedSeconds = 0;
    currentAmplitude = 0.0;
    state = RecordingState.recording;
    notifyListeners();

    _ampSubscription = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
      // amplitude max is usually 0.0 dB, min is around -160 dB
      // map roughly -50..0 to 0.0..1.0
      double val = (amp.current + 50) / 50.0;
      currentAmplitude = val.clamp(0.0, 1.0);
      notifyListeners();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      elapsedSeconds++;
      // notifyListeners is handled rapidly by the amplitude stream anyway
      if (elapsedSeconds >= targetSeconds) stopRecording();
    });
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    _ampSubscription?.cancel();
    currentAmplitude = 0.0;
    final path = await _recorder.stop();
    if (path != null) {
      _recordingPath = path;
    }
    state = RecordingState.uploading;
    uploadProgress = 0;
    notifyListeners();

    await _uploadAndAnalyse();
  }

  Future<void> _uploadAndAnalyse() async {
    try {
      lastSession = await _api.analyseSession(
        audioPath: _recordingPath!,
        topicTitle: selectedTopic?.title,
        onProgress: (sent, total) {
          uploadProgress = total > 0 ? sent / total : 0;
          notifyListeners();
        },
      );
      state = RecordingState.done;
    } catch (e) {
      errorMessage = e.toString();
      state = RecordingState.error;
    }
    notifyListeners();
  }

  void reset() {
    state = RecordingState.idle;
    elapsedSeconds = 0;
    uploadProgress = 0;
    lastSession = null;
    errorMessage = null;
    selectedTopic = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
