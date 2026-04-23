class FeedbackItem {
  final String title;
  final String detail;
  const FeedbackItem({required this.title, required this.detail});

  factory FeedbackItem.fromJson(Map<String, dynamic> j) =>
      FeedbackItem(title: j['title'], detail: j['detail']);
}

class SolutionItem {
  final String weaknessTitle;
  final String exercise;
  final String duration;
  const SolutionItem(
      {required this.weaknessTitle,
      required this.exercise,
      required this.duration});

  factory SolutionItem.fromJson(Map<String, dynamic> j) => SolutionItem(
        weaknessTitle: j['weakness_title'],
        exercise: j['exercise'],
        duration: j['duration'],
      );
}

class TopicItem {
  final String title;
  final String tip;
  const TopicItem({required this.title, required this.tip});

  factory TopicItem.fromJson(Map<String, dynamic> j) =>
      TopicItem(title: j['title'], tip: j['tip']);
}

class SpeechSession {
  final int id;
  final String userId;
  final double durationS;
  final String transcript;
  final double wordsPerMinute;
  final double pauseRatio;
  final int fillerCount;
  final double volumeVariance;
  final double? speechScore;
  final double? relevancyScore;
  final double overallScore;
  final String? topic;
  final List<FeedbackItem> strengths;
  final List<FeedbackItem> weaknesses;
  final List<SolutionItem> solutions;
  final DateTime createdAt;

  const SpeechSession({
    required this.id,
    required this.userId,
    required this.durationS,
    required this.transcript,
    required this.wordsPerMinute,
    required this.pauseRatio,
    required this.fillerCount,
    required this.volumeVariance,
    this.speechScore,
    this.relevancyScore,
    required this.overallScore,
    this.topic,
    required this.strengths,
    required this.weaknesses,
    required this.solutions,
    required this.createdAt,
  });

  factory SpeechSession.fromJson(Map<String, dynamic> j) => SpeechSession(
        id: j['id'],
        userId: j['user_id'],
        durationS: (j['duration_s'] as num).toDouble(),
        transcript: j['transcript'],
        wordsPerMinute: (j['words_per_minute'] as num).toDouble(),
        pauseRatio: (j['pause_ratio'] as num).toDouble(),
        fillerCount: j['filler_count'],
        volumeVariance: (j['volume_variance'] as num).toDouble(),
        speechScore: j['speech_score'] != null ? (j['speech_score'] as num).toDouble() : null,
        relevancyScore: j['relevancy_score'] != null ? (j['relevancy_score'] as num).toDouble() : null,
        overallScore: (j['overall_score'] as num).toDouble(),
        topic: j['topic'],
        strengths: (j['strengths'] as List)
            .map((e) => FeedbackItem.fromJson(e))
            .toList(),
        weaknesses: (j['weaknesses'] as List)
            .map((e) => FeedbackItem.fromJson(e))
            .toList(),
        solutions: (j['solutions'] as List)
            .map((e) => SolutionItem.fromJson(e))
            .toList(),
        createdAt: DateTime.parse(j['created_at']),
      );

  String get formattedDuration {
    final m = (durationS ~/ 60).toString().padLeft(2, '0');
    final s = (durationS % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }
}
