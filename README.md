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

# Logit Flutter Plugin

A developer-friendly Flutter plugin to capture, view, and manage logs inside your app. Supports Debug, Logs, and API logs.

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
  logit: ^1.0.0
```

### 2. Initialize in main()
```dart
import 'package:logit/logit.dart';

void main() {
  Logit.init(const LoggerConfig(
    enableInDebug: true,
    allowedIds: ['test@dev.com'],
    enableLongPressGesture: true,
    enablePersistence: true,
    maxStoredLogs: 100,
  ));
  runApp(const MyApp());
}
```

### 3. Attach Logger Overlay
```dart
@override
void initState() {
  super.initState();
  Logit.attachOverlay(context);
}
```

### 4. Log Messages
```dart
Logit.debug('Debug message');
Logit.api('GET', 'https://api.example.com', headers: {}, body: {}, statusCode: 200);
Logit.log('General log message');
```

## Screenshots
Below are some screenshots showcasing the functionality of this plugin:

<table>
  <tr>
    <td><img src="screenshots/Screenshot_20250626-121919.png" alt="Screenshot 1" width="200"></td>
    <td><img src="screenshots/Screenshot_20250626-121933.png" alt="Screenshot 2" width="200"></td>
    <td><img src="screenshots/Screenshot_20250626-121957.png" alt="Screenshot 3" width="200"></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot_20250626-122007.png" alt="Screenshot 4" width="200"></td>
    <td><img src="screenshots/Screenshot_20250626-122028.png" alt="Screenshot 5" width="200"></td>
    <td><img src="screenshots/Screenshot_20250626-122039.png" alt="Screenshot 6" width="200"></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot_20250626-122048.png" alt="Screenshot 7" width="200"></td>
    <td><img src="screenshots/Screenshot_20250626-122100.png" alt="Screenshot 8" width="200"></td>
    <td><img src="screenshots/Screenshot_20250626-122128.png" alt="Screenshot 9" width="200"></td>
  </tr>
</table>

## Export Logs
Logs can be exported in JSON or plain text format using the export modal.

## Contributing
Contributions are welcome! Please follow the guidelines in CONTRIBUTING.md.

## License
This project is licensed under the MIT License. See LICENSE for details.

## Additional Information

- For more details on the API, check out the [API Documentation](doc/api/index.html).
- If you find any issues or have a feature request, please file them on the [GitHub repository](https://github.com/vignarajj/dev_loggerx).