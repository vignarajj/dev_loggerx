import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_loggerx/services/services.dart';

class SettingsDetailPage extends ConsumerWidget {
  final Map<String, dynamic> info;
  final VoidCallback? onShare;

  const SettingsDetailPage({required this.info, this.onShare, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(loggerProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Device & App Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            tooltip: 'Share Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Logs',
            onPressed: () {
              notifier.clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All logs cleared!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: info.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 160,
                          child: Text(e.key,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16))),
                      Expanded(
                          child: Text(e.value.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
