import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_loggerx/services/services.dart';
import 'floating_rounded_app_bar.dart';

/// Settings/details page for device and app info, log sharing, and clearing logs.
///
/// Used as a subpage from the logger overlay for diagnostics and export.
class SettingsDetailPage extends ConsumerWidget {
  final Map<String, dynamic> info;
  final VoidCallback? onShare;

  const SettingsDetailPage({required this.info, this.onShare, super.key});

  /// Builds the settings detail page UI.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(loggerProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          FloatingRoundedAppBar(
            title: const Text(
              'Device & App Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
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
          ),
        ],
      ),
    );
  }
}
