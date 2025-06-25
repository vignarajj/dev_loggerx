import 'package:dev_loggerx/dev_loggerx.dart';
import 'package:dev_loggerx/services/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Initialize the logger with default config
  Logger.init(
    const LoggerConfig(
      enableInDebug: true,
      enableLongPressGesture: true,
      enablePersistence: false,
      maxStoredLogs: 100,
      allowedIds: ['test@dev.com'], // Example allowed ID
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevLoggerX Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'DevLoggerX Example'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int _counter = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach the logger overlay via long-press
    LoggerCore.attachLongPress(context, userId: 'test@dev.com');
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    Logger.debug(ref, 'Counter Incremented', 'Counter is now $_counter');
  }

  void _updateLoggerConfig() {
    // Example: Toggle long-press gesture at runtime
    final current = LoggerCore.config.value;
    LoggerCore.updateConfig(
      current.copyWith(enableLongPressGesture: !current.enableLongPressGesture),
    );
    Logger.debug(
      ref,
      'Config Updated',
      'Long-press gesture is now ${!current.enableLongPressGesture}',
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    final config = LoggerCore.config.value;
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              config.enableLongPressGesture
                  ? Icons.touch_app
                  : Icons.do_not_touch,
            ),
            tooltip: 'Toggle Long-Press Gesture',
            onPressed: _updateLoggerConfig,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text('You have pushed the button this many times:'),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _incrementCounter,
                  child: const Text('Increment & Log'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _updateLoggerConfig,
                  child: Text(
                    config.enableLongPressGesture
                        ? 'Disable Long-Press Logger'
                        : 'Enable Long-Press Logger',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Long-press anywhere to open the logger overlay.'),
                const SizedBox(height: 24),
                Wrap(
                  runSpacing: 12.0,
                  spacing: 12.0,

                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Logger.debug(
                          ref,
                          'Debug Test',
                          'This is a debug/info log.',
                        );
                      },
                      child: const Text('Log Debug/Info'),
                    ),

                    /// Test: Log an error message
                    ElevatedButton(
                      onPressed: () {
                        Logger.error(
                          ref,
                          'Error Test',
                          'This is an error log.',
                        );
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
                        Logger.api(
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
                          await dio.get(
                            'https://jsonplaceholder.typicode.com/posts/1',
                          );
                        } catch (_) {}
                      },
                      child: const Text('Log API (Dio)'),
                    ),

                    /// Test: Log an API call using http
                    ElevatedButton(
                      onPressed: () async {
                        final client = Logger.wrapHttp(ref);
                        try {
                          await client.get(
                            Uri.parse(
                              'https://jsonplaceholder.typicode.com/posts/2',
                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
