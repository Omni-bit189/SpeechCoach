import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/session.dart';

class ApiService {
  // Backend URL auto-detection:
  // - Web: localhost (same machine)
  // - Android emulator: 10.0.2.2 (maps to host localhost)
  // - Physical device: change to your LAN IP, e.g. 'http://192.168.1.10:8000'
  static String get _base {
    if (kIsWeb) return 'http://localhost:8000';
    // For mobile, default to Android emulator address
    return 'http://10.0.2.2:8000';
  }

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _base,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120), // analysis takes time
    ));
  }

  /// Upload audio and get back the full analysis report.
  Future<SpeechSession> analyseSession({
    required String audioPath,
    String userId = 'anonymous',
    String? topicTitle,
    void Function(int sent, int total)? onProgress,
  }) async {
    MultipartFile filePart;
    if (kIsWeb) {
      final response = await http.get(Uri.parse(audioPath));
      filePart = MultipartFile.fromBytes(response.bodyBytes, filename: 'session.webm');
    } else {
      filePart = await MultipartFile.fromFile(audioPath, filename: 'session.m4a');
    }

    final formDataMap = <String, dynamic>{
      'audio': filePart,
      'user_id': userId,
    };
    if (topicTitle != null) {
      formDataMap['topic'] = topicTitle;
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _dio.post(
      '/sessions/analyse',
      data: formData,
      onSendProgress: onProgress,
    );

    return SpeechSession.fromJson(response.data);
  }

  Future<List<TopicItem>> getTopics() async {
    try {
      final response = await _dio.get('/topics');
      return (response.data['topics'] as List)
          .map((e) => TopicItem.fromJson(e))
          .toList();
    } catch (e) {
      print('Error getting topics: $e');
      return [];
    }
  }

  Future<List<SpeechSession>> listSessions({String userId = 'anonymous'}) async {
    final response =
        await _dio.get('/sessions', queryParameters: {'user_id': userId});
    return (response.data as List)
        .map((e) => SpeechSession.fromJson(e))
        .toList();
  }

  Future<SpeechSession> getSession(int id) async {
    final response = await _dio.get('/sessions/$id');
    return SpeechSession.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getDashboardReview({String userId = 'anonymous'}) async {
    try {
      final response = await _dio.get('/dashboard/review', queryParameters: {'user_id': userId});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting dashboard review: $e');
      return {
        'general_review': 'Failed to load personalized review from server.',
        'strengths': [],
        'weaknesses': [],
        'solutions': []
      };
    }
  }

  Future<void> deleteSession(int id) async {
    await _dio.delete('/sessions/$id');
  }
}
