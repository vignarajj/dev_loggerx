<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# DevLogger Flutter Plugin

A developer-friendly Flutter plugin to capture, view, and manage logs inside your app. Supports Debug, Logs, and API logs. Inspired by cr_logger, always in dark mode, and built with Riverpod.

## Features
- Categorized log display: Debug, Logs, API
- Expandable API log cards
- Search and filter logs
- Runtime configuration (long-press, clear logs, etc.)
- Integrates with Dio and http clients
- Compatible with Android, iOS, and Web

## Getting Started

### 1. Add Dependency
```yaml
dependencies:
  dev_loggerx: ^0.1.0
```

### 2. Initialize in main()
```dart
import 'package:dev_loggerx/dev_loggerx.dart';

void main() {
  init(const DevLoggerConfig(
    enableInDebug: true,
    allowedEmails: ['dev@company.com'],
    enableLongPressGesture: true,
  ));
  runApp(MyApp());
}
```

### 3. Attach Global Long-Press (in your root widget)
```dart
@override
Widget build(BuildContext context) {
  DevLogger.attachGlobalLongPress(context, userEmail: currentUserEmail);
  return MaterialApp(...);
}
```

### 4. Logging Usage
```dart
logDebug('Init', 'App started');
logInfo('User', 'User logged in');
logError('Crash', 'Null pointer exception');

logApiRequest(
  heading: 'GET /api/user',
  content: '{"id":1}',
  method: 'GET',
  url: 'https://api.com/user',
  headers: {'Authorization': 'Bearer ...'},
  statusCode: 200,
  timings: Duration(milliseconds: 120),
);
```

### 5. Dio Integration
```dart
final dio = Dio();
dio.interceptors.add(DevLoggerDioInterceptor(ref));
```

### 6. http Integration
```dart
final client = wrapHttpClient(ref);
final response = await client.get(Uri.parse('https://api.com/user'));
```

### 7. Runtime Settings
- Tap the settings icon in the logger overlay to toggle long-press, clear logs, and more.

## API Reference
- `init(DevLoggerConfig config)` – Initialize the logger
- `logDebug(String heading, String content)` – Log debug/info
- `logInfo(String heading, String content)` – Log info
- `logError(String heading, String content)` – Log error
- `logApiRequest(...)` – Log API call manually
- `DevLoggerDioInterceptor` – Dio interceptor for API logging
- `wrapHttpClient(ref, [client])` – Wrap http.Client for API logging

## Platform Compatibility
- **Android:** Supported
- **iOS:** Supported
- **Web:** Supported

## License
MIT

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
