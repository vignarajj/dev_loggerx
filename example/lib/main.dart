import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logitx/logit.dart';
import 'package:logitx/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggerService.initPersistenceIfNeeded(
    const LoggerConfig(enablePersistence: true),
  );

  // Initialize the logger with all config options
  Logit.init(
    const LoggerConfig(
      enableInDebug: true,
      allowedIds: ['test@dev.com'],
      enableLongPressGesture: true,
      enablePersistence: true,
      maxStoredLogs: 100,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'LogItX Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(title: 'LogItX Example'),
      ),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LogitCore.attachLongPress(context, userId: 'test@dev.com');
      // Initialize provider container for API logging
      if (LogitCore.container == null) {
        final container = ProviderScope.containerOf(context);
        LogitCore.initializeProviderContainer(container);
        // Also initialize LoggerDio's container
        LoggerDio.initializeProviderContainer(container);
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Test Cases:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          /// Test: Log a debug/info message
          ElevatedButton(
            onPressed: () {
              Logit.debug('Debug Test', 'This is a debug/info log.');
            },
            child: const Text('Log Debug/Info'),
          ),

          /// Test: Log an error message
          ElevatedButton(
            onPressed: () {
              Logit.error('Error Test', 'This is an error log.');
            },
            child: const Text('Log Error'),
          ),

          /// Test: Log a generic log
          ElevatedButton(
            onPressed: () {
              ref
                  .read(loggerProvider.notifier)
                  .addLog(
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
              dio.interceptors.add(LoggerDio());
              try {
                await dio.get('https://jsonplaceholder.typicode.com/posts/1');
              } catch (_) {}
            },
            child: const Text('Log API (Dio)'),
          ),

          /// Test: Log an API call using http
          ElevatedButton(
            onPressed: () async {
              final client = Logit.wrapHttp();
              try {
                await client.get(
                  Uri.parse('https://jsonplaceholder.typicode.com/posts/2'),
                );
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
        ],
      ),
    );
  }
}
