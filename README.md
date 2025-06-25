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
- **Floating, rounded app bar**: Modern, elevated app bar that appears to float at the top of the overlay and settings screens.
- **Segmented tab navigation**: Switch between All, Debug, Logs, and API logs with a single tap.
- **Debug log filtering**: Filter debug logs by Info, Warning, or Error with color-coded chips.
- **Monospaced font throughout**: All text uses a coding-style monospaced font for clarity and consistency.
- **Expandable API log cards**: View detailed request/response info, headers, timings, and more.
- **Powerful search and filter**: Search logs with match navigation and highlighting.
- **Export and share logs**: Export logs as JSON or text, share with device/app info, or clear logs.
- **Settings page**: View device/app info, share logs, and clear logs from a dedicated settings screen.
- **Dio and http integration**: Automatically log API calls from Dio and http clients.
- **Riverpod state management**: Robust, testable log state management.
- **Modular, documented code**: All classes, widgets, and services are split into files and fully documented with Dart doc comments.
- **Modern dark overlay UI**: Always accessible, beautiful, and easy to use.
- **Compatible with Android, iOS, and Web**

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
  Logger.init(const LoggerConfig(
    enableInDebug: true,
    allowedIds: ['dev@company.com'],
    enableLongPressGesture: true,
  ));
  runApp(MyApp());
}
```

### 3. Attach Global Long-Press (in your root widget)
```dart
@override
Widget build(BuildContext context) {
  LoggerCore.attachLongPress(context, userId: currentUserEmail);
  return MaterialApp(...);
}
```

### 4. Logging Usage
```dart
Logger.debug(ref, 'Init', 'App started');
Logger.info(ref, 'User', 'User logged in');
Logger.error(ref, 'Error', 'Something went wrong');
Logger.api(
  ref: ref,
  heading: 'GET /api/user',
  content: '{"result": "ok"}',
  method: 'GET',
  url: 'https://api.example.com/user',
  headers: {'Authorization': 'Bearer token'},
  statusCode: 200,
  timings: Duration(milliseconds: 123),
);
```

## Screenshots

<!-- Add screenshots here to showcase the floating app bar, segmented tabs, and log cards. -->

## API Reference

See the Dart doc comments in the code for detailed API documentation. All public classes, methods, and fields are fully documented.

## License

MIT

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

