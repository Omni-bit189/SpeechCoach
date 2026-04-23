import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/session.dart';

class ReportScreen extends StatelessWidget {
  final SpeechSession session;
  const ReportScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Home'),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Score card ─────────────────────────────────────────────────
          _ScoreCard(session: session)
              .animate()
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // ── Metrics row ────────────────────────────────────────────────
          _MetricsRow(session: session)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 28),

          // ── Strengths ──────────────────────────────────────────────────
          _SectionHeader(
              title: 'Strengths', icon: Icons.star_rounded, color: Colors.green),
          ...session.strengths.asMap().entries.map((e) => _FeedbackCard(
                item: e.value,
                color: Colors.green,
                delay: e.key * 80,
              )),

          const SizedBox(height: 20),

          // ── Weaknesses ─────────────────────────────────────────────────
          _SectionHeader(
              title: 'Areas to improve',
              icon: Icons.trending_up_rounded,
              color: Colors.orange),
          ...session.weaknesses.asMap().entries.map((e) => _FeedbackCard(
                item: e.value,
                color: Colors.orange,
                delay: e.key * 80,
              )),

          const SizedBox(height: 20),

          // ── Solutions ──────────────────────────────────────────────────
          _SectionHeader(
              title: 'Exercises',
              icon: Icons.fitness_center_rounded,
              color: theme.colorScheme.primary),
          ...session.solutions.asMap().entries.map((e) => _SolutionCard(
                item: e.value,
                delay: e.key * 80,
              )),

          const SizedBox(height: 20),

          // ── Transcript ─────────────────────────────────────────────────
          _TranscriptSection(transcript: session.transcript),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final SpeechSession session;
  const _ScoreCard({required this.session});

  Color _getColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final hasTopic = session.topic != null;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (hasTopic) ...[
              Text('Topic: ${session.topic}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasTopic) ...[
                  _MiniScore(
                    title: 'Relevancy',
                    score: session.relevancyScore ?? 0,
                    color: _getColor(session.relevancyScore ?? 0),
                  ),
                  const SizedBox(width: 16),
                ],
                Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 50,
                      lineWidth: 8,
                      percent: session.overallScore / 100,
                      center: Text('${session.overallScore.toInt()}',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      progressColor: _getColor(session.overallScore),
                      backgroundColor: _getColor(session.overallScore).withValues(alpha: 0.15),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(height: 8),
                    Text(hasTopic ? 'Total' : 'Overall',
                        style: theme.textTheme.titleSmall),
                  ],
                ),
                if (hasTopic) ...[
                  const SizedBox(width: 16),
                  _MiniScore(
                    title: 'Speech',
                    score: session.speechScore ?? 0,
                    color: _getColor(session.speechScore ?? 0),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _fmtDuration(session.overallScore),
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(double score) => score >= 75
      ? 'Great performance!'
      : score >= 50
          ? 'Good effort, keep going'
          : 'Keep practising!';
}

class _MiniScore extends StatelessWidget {
  final String title;
  final double score;
  final Color color;

  const _MiniScore({required this.title, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 35,
          lineWidth: 5,
          percent: score / 100,
          center: Text('${score.toInt()}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.15),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final SpeechSession session;
  const _MetricsRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(label: 'WPM', value: session.wordsPerMinute.toInt().toString(),
            ideal: '120–160'),
        const SizedBox(width: 10),
        _Metric(label: 'Pauses',
            value: '${(session.pauseRatio * 100).toInt()}%', ideal: '< 20%'),
        const SizedBox(width: 10),
        _Metric(label: 'Fillers',
            value: session.fillerCount.toString(), ideal: '0–3'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String ideal;
  const _Metric(
      {required this.label, required this.value, required this.ideal});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text('ideal: $ideal',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackItem item;
  final Color color;
  final int delay;
  const _FeedbackCard(
      {required this.item, required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(item.detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms);
  }
}

class _SolutionCard extends StatelessWidget {
  final SolutionItem item;
  final int delay;
  const _SolutionCard({required this.item, required this.delay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lightbulb_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(item.weaknessTitle,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(item.duration,
                    style: theme.textTheme.labelSmall),
              )
            ]),
            const SizedBox(height: 8),
            Text(item.exercise,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms);
  }
}

class _TranscriptSection extends StatefulWidget {
  final String transcript;
  const _TranscriptSection({required this.transcript});

  @override
  State<_TranscriptSection> createState() => _TranscriptSectionState();
}

class _TranscriptSectionState extends State<_TranscriptSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_snippet_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text('Transcript',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(_expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(widget.transcript,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
