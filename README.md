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

# DevLoggerX Flutter Plugin

A developer-friendly Flutter plugin to capture, view, and manage logs inside your app. Supports Debug, Logs, and API logs. Inspired by cr_logger, always in dark mode, and built with Riverpod.

## Features
- Categorized log display: **All, Debug, Logs, API** (segmented tabs)
- Expandable API log cards with details
- Powerful search and filter (with match navigation)
- Export logs (JSON or plain text) with filters
- Share logs (with device/app info) via bottom sheet
- Settings page: view device/app info, share logs, clear logs
- Integrates with Dio and http clients
- Built with Riverpod for robust state management
- Modern dark overlay UI, always accessible
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
  Logger.init(const DevLoggerConfig(
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
Logger.debug(ref, 'Init', 'App started');
Logger.info(ref, 'User', 'User logged in');
Logger.error(ref, 'Crash', 'Null pointer exception');

Logger.api(
  ref: ref,
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
final client = Logger.wrapHttp(ref);
final response = await client.get(Uri.parse('https://api.com/user'));
```

## Overlay UI & Features
- **Open overlay:** Long-press with gesture (if enabled) or call `LoggerCore.showOverlay()`
- **Segmented tabs:** Switch between All, Debug, Logs, API
- **Search:** Tap search icon, type keyword, navigate matches
- **Export:** Tap export, filter by type/date/keyword, export as JSON or text
- **Share:** Tap settings → share icon, select log type, share with device/app info
- **Clear logs:** Tap settings → delete icon
- **Settings:** View device/app info, app version, network type, etc.

## API Reference
- `Logger.init(DevLoggerConfig config)` – Initialize the logger
- `Logger.debug(WidgetRef ref, String heading, String content)` – Log debug/info
- `Logger.info(WidgetRef ref, String heading, String content)` – Log info
- `Logger.error(WidgetRef ref, String heading, String content)` – Log error
- `Logger.api(...)` – Log API call manually
- `DevLoggerDioInterceptor` – Dio interceptor for API logging
- `Logger.wrapHttp(ref, [client])` – Wrap http.Client for API logging

## Platform Compatibility
- **Android:** Supported
- **iOS:** Supported
- **Web:** Supported

## UI/UX
- Modern dark mode overlay
- Segmented navigation for log types
- Expandable/collapsible API log cards
- Smooth search and match navigation
- Material bottom sheets for export/share
- Device/app info in settings

## Exporting, Sharing, and Clearing Logs
- **Export:** Tap export, filter logs, choose format, download to device
- **Share:** Tap settings → share, select log type, share as text/file (with device/app info)
- **Clear:** Tap settings → delete icon to clear all logs

## Contributing & Issues
- Contributions are welcome! Please open issues or pull requests on GitHub.
- For bugs, feature requests, or questions, file an issue with details and reproduction steps.

## License
MIT

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

