import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/session_provider.dart';
import 'report_screen.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: const _SessionView(),
    );
  }
}

class _SessionView extends StatelessWidget {
  const _SessionView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final theme = Theme.of(context);

    // Navigate to report once analysis is done
    if (provider.state == RecordingState.done && provider.lastSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ReportScreen(session: provider.lastSession!)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New session'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
              const Spacer(),

              // ── Topic selector ────────────────────────────────────────
              if (provider.state == RecordingState.idle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Choose a topic (optional)',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Reload topics',
                      onPressed: provider.isLoadingTopics
                          ? null
                          : () => provider.loadTopics(),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.isLoadingTopics)
                  const Center(child: CircularProgressIndicator())
                else if (provider.topics.isNotEmpty)
                  ...provider.topics.map((t) {
                    final selected = provider.selectedTopic?.title == t.title;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          provider.selectTopic(selected ? null : t);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.lightbulb_rounded,
                                        color: Colors.amber, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        t.tip,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme
                                                    .colorScheme.outline),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],

              // ── Duration selector ─────────────────────────────────────
              if (provider.state == RecordingState.idle) ...[
                Text('Choose duration',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [60, 120, 180, 300].map((s) {
                    final label =
                        s < 60 ? '${s}s' : '${s ~/ 60} min';
                    final selected = provider.targetSeconds == s;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => provider.setTarget(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              // ── Timer ring ────────────────────────────────────────────
              _TimerRing(provider: provider),

              const SizedBox(height: 48),

              // ── Status text ───────────────────────────────────────────
              _StatusText(provider: provider),

              const Spacer(),

              // ── Action button ─────────────────────────────────────────
              _ActionButton(provider: provider),

              const SizedBox(height: 32),
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
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  final SessionProvider provider;
  const _TimerRing({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final progress = provider.targetSeconds > 0
        ? provider.elapsedSeconds / provider.targetSeconds
        : 0.0;

    final mins =
        (provider.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs =
        (provider.elapsedSeconds % 60).toString().padLeft(2, '0');

    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _RingPainter(
            progress: progress.clamp(0, 1),
            color: color,
            isRecording: provider.isRecording,
            amplitude: provider.currentAmplitude),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.state == RecordingState.uploading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text('${(provider.uploadProgress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall),
              ] else ...[
                Text('$mins:$secs',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (provider.isRecording)
                  const Icon(Icons.graphic_eq_rounded, size: 20)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1200.ms, color: Colors.redAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRecording;
  final double amplitude;
  _RingPainter(
      {required this.progress,
      required this.color,
      required this.isRecording,
      required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Add dynamic pulsing factor based on amplitude
    final pulseExtra = isRecording ? (amplitude * 15.0) : 0.0;
    final r = cx - 15;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final fillPaint = Paint()
      ..color = isRecording ? Colors.redAccent : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + pulseExtra
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: (amplitude * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15 + pulseExtra * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    
    if (isRecording && amplitude > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        shadowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => 
      old.progress != progress || old.isRecording != isRecording || old.amplitude != amplitude;
}

class _StatusText extends StatelessWidget {
  final SessionProvider provider;
  const _StatusText({required this.provider});

  @override
  Widget build(BuildContext context) {
    final text = switch (provider.state) {
      RecordingState.idle => 'Tap the mic to start speaking',
      RecordingState.recording => 'Speak clearly — AI is listening',
      RecordingState.uploading => 'Analysing your speech…',
      RecordingState.done => 'Done!',
      RecordingState.error => provider.errorMessage ?? 'Something went wrong',
    };

    return Text(text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge)
        .animate(key: ValueKey(provider.state))
        .fadeIn(duration: 300.ms);
  }
}

class _ActionButton extends StatelessWidget {
  final SessionProvider provider;
  const _ActionButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (provider.state == RecordingState.uploading) {
      return const SizedBox.shrink();
    }

    if (provider.state == RecordingState.error) {
      return FilledButton.icon(
        onPressed: provider.reset,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      );
    }

    final isRecording = provider.isRecording;
    return GestureDetector(
      onTap: isRecording ? provider.stopRecording : provider.startRecording,
      child: AnimatedContainer(
        duration: 300.ms,
        width: isRecording ? 72 : 80,
        height: isRecording ? 72 : 80,
        decoration: BoxDecoration(
          color: isRecording ? Colors.redAccent : theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.redAccent : theme.colorScheme.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
