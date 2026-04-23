import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import 'session_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<SpeechSession> _sessions = [];
  double _averageScore = 0;
  Map<String, dynamic>? _dashboardReview;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _api.listSessions();
      if (!mounted) return;

      if (sessions.isEmpty) {
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
        return;
      }

      final recentSessions = sessions.take(4).toList();
      double totalScore = 0;
      for (var s in recentSessions) {
        totalScore += s.overallScore;
      }

      final review = await _api.getDashboardReview();

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _averageScore = totalScore / recentSessions.length;
        _dashboardReview = review;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text('SpeechCoach',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold))
                            .animate()
                            .fadeIn(duration: 400.ms),
                        Text('Your AI speech therapy companion',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: theme.colorScheme.outline))
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms),
                        const SizedBox(height: 32),

                        // ── Dashboard ─────────────────────────────────────────
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _sessions.isEmpty
                                ? _EmptyDashboard(theme: theme)
                                : _buildDashboard(theme),

                        const Spacer(), // Pushes buttons to the bottom
                        const SizedBox(height: 32),

                        // ── Start session card ──────────────────────────────────────
                        _SessionCard(
                          icon: Icons.mic_rounded,
                          title: 'New session',
                          subtitle: 'Record a speech and get AI feedback',
                          color: theme.colorScheme.primary,
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SessionScreen()));
                            _loadData(); // refresh on return
                          },
                        ).animate().slideY(
                            begin: 0.2, delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 16),

                        // ── History card ────────────────────────────────────────────
                        _SessionCard(
                          icon: Icons.history_rounded,
                          title: 'Past sessions',
                          subtitle: 'Review your progress over time',
                          color: theme.colorScheme.secondary,
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HistoryScreen()));
                            _loadData(); // refresh on return
                          },
                        ).animate().slideY(
                            begin: 0.2, delay: 300.ms, duration: 400.ms),

                        const SizedBox(height: 16),
                        Center(
                          child: Text('Powered by faster-whisper + Ollama',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.outline)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme) {
    if (_dashboardReview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviewText = _dashboardReview?['general_review'] ?? '';
    final List<dynamic> strengths = _dashboardReview?['strengths'] ?? [];
    final List<dynamic> weaknesses = _dashboardReview?['weaknesses'] ?? [];
    final List<dynamic> solutions = _dashboardReview?['solutions'] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Fixed Top Bar (Score & Intro)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 38,
                  lineWidth: 7,
                  percent: _averageScore / 100,
                  center: Text('${_averageScore.toInt()}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  progressColor: _averageScore >= 75
                      ? Colors.green
                      : _averageScore >= 50
                          ? Colors.orange
                          : Colors.redAccent,
                  backgroundColor: theme.colorScheme.surface,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Speech Pattern Review',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Based on your last ${_sessions.take(4).length} sessions',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 28),
              ],
            ),
          ),

          // Section 2: Scrollable Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reviewText,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                  const SizedBox(height: 24),

                  if (strengths.isNotEmpty) ...[
                    Text('Core Strengths', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: strengths.map((s) => Chip(
                        label: Text(s.toString()),
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: Colors.green[800], fontSize: 12),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (weaknesses.isNotEmpty) ...[
                    Text('Areas to Refine', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: weaknesses.map((w) => Chip(
                        label: Text(w.toString()),
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: Colors.orange[800], fontSize: 12),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (solutions.isNotEmpty) ...[
                    Text('Action Plan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...solutions.map((sol) {
                      final title = sol['weakness_title'] ?? 'Exercise';
                      final desc = sol['exercise'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right_rounded, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(desc, style: theme.textTheme.bodySmall),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _EmptyDashboard extends StatelessWidget {
  final ThemeData theme;
  const _EmptyDashboard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined,
              size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Welcome to SpeechCoach',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Record your first session to unlock your personalized training dashboard and analytics!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _SessionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SessionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
