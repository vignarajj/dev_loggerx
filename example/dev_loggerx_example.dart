/// Example app for LoggerX plugin.
///
/// Demonstrates:
/// - Initialization with all config options
/// - Logging debug/info, error, generic, and API logs
/// - Persistence and export
/// - Overlay UI (long-press)
/// - Dio and http integration
/// - Riverpod state management
///
/// Each button is a test case with a code comment explaining its purpose.
library;

import 'package:logit/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logit/logit.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize persistence if needed
  await LoggerService.initPersistenceIfNeeded(const LoggerConfig(enablePersistence: true));
  // Initialize the logger with all config options
  Logit.init(const LoggerConfig(
    enableInDebug: true,
    allowedIds: ['test@dev.com'],
    enableLongPressGesture: true,
    enablePersistence: true,
    maxStoredLogs: 100,
  ));
  runApp(const ProviderScope(child: LoggerExampleApp()));
}

/// Main app widget for the example.
class LoggerExampleApp extends StatelessWidget {
  const LoggerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogIt Example',
      theme: ThemeData.dark(),
      home: const LoggerExampleHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Home screen with test case buttons and instructions.
class LoggerExampleHome extends ConsumerWidget {
  const LoggerExampleHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attach the global long-press gesture for overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LogitCore.attachLongPress(context, userId: 'test@dev.com');
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Logit Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Test Cases:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          /// Test: Log a debug/info message
          ElevatedButton(
            onPressed: () {
              Logit.debug(ref, 'Debug Test', 'This is a debug/info log.');
            },
            child: const Text('Log Debug/Info'),
          ),
          /// Test: Log an error message
          ElevatedButton(
            onPressed: () {
              Logit.error(ref, 'Error Test', 'This is an error log.');
            },
            child: const Text('Log Error'),
          ),
          /// Test: Log a generic log
          ElevatedButton(
            onPressed: () {
              ref.read(loggerProvider.notifier).addLog(
                heading: 'Generic Log',
                content: 'This is a generic log entry.',
              );
            },
            child: const Text('Log Generic'),
          ),
          /// Test: Log an API call manually
          ElevatedButton(
            onPressed: () {
              Logit.api(
                ref: ref,
                heading: 'Manual API Log',
                content: '{"result": "ok"}',
                method: 'GET',
                url: 'https://api.example.com/test',
                headers: {'Authorization': 'Bearer token'},
                statusCode: 200,
                timings: const Duration(milliseconds: 123),
              );
            },
            child: const Text('Log API (Manual)'),
          ),
          /// Test: Log an API call using Dio
          ElevatedButton(
            onPressed: () async {
              final dio = Dio();
              dio.interceptors.add(LoggerDio(ref));
              try {
                await dio.get('https://jsonplaceholder.typicode.com/posts/1');
              } catch (_) {}
            },
            child: const Text('Log API (Dio)'),
          ),
          /// Test: Log an API call using http
          ElevatedButton(
            onPressed: () async {
              final client = Logit.wrapHttp(ref);
              try {
                await client.get(Uri.parse('https://jsonplaceholder.typicode.com/posts/2'));
              } catch (_) {}
            },
            child: const Text('Log API (http)'),
          ),
          /// Test: Clear all logs
          ElevatedButton(
            onPressed: () {
              ref.read(loggerProvider.notifier).clearLogs();
            },
            child: const Text('Clear Logs'),
          ),
          const SizedBox(height: 24),
          const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('- Use the buttons above to generate different types of logs.'),
          const Text('- Long-press anywhere to open the logger overlay.'),
          const Text('- Use the overlay UI to search, filter, export, and manage logs.'),
          const Text('- Settings in the overlay allow toggling features and clearing logs.'),
          const Text('- Export logs to JSON or text and share them.'),
        ],
      ),
    );
  }
}
