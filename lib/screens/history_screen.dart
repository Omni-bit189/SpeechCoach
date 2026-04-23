import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import 'report_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _api = ApiService();
  late Future<List<SpeechSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Past sessions'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: FutureBuilder<List<SpeechSession>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load sessions: ${snap.error}'));
          }
          final sessions = snap.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions yet. Record your first speech!'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = sessions[i];
              final score = s.overallScore.toInt();
              final color = score >= 75
                  ? Colors.green
                  : score >= 50
                      ? Colors.orange
                      : Colors.redAccent;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text('$score',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                      DateFormat('MMM d, yyyy · h:mm a').format(s.createdAt)),
                  subtitle: Text(
                      '${s.durationS.toInt()}s · ${s.wordsPerMinute.toInt()} wpm · ${s.fillerCount} fillers'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete Session'),
                              content: const Text('Are you sure you want to delete this session?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _api.deleteSession(s.id);
                              if (!context.mounted) return;
                              setState(() {
                                _future = _api.listSessions();
                              });
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                            }
                          }
                        },
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ReportScreen(session: s))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
