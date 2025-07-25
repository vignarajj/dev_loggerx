/// LoggerX: A developer-friendly Flutter plugin for in-app logging, API tracking, and debugging.
///
/// Features:
/// - Categorized log display (Debug, Logs, API)
/// - Overlay UI with search, filter, export, and settings
/// - Supports Dio and http API logging
/// - Persistence with Hive
/// - Riverpod state management
/// - Easy integration and configuration
///
library;

import 'package:logitx/models/log_enums.dart';
import 'package:logitx/ui/logger_overlay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/config.dart';
import 'services/services.dart';

export 'config/config.dart' show LoggerConfig;
export 'services/services.dart' show LoggerDio, LoggerHttp, loggerProvider;
export 'src/dev_loggerx_base.dart';

/// Core logger entry point for configuration, overlay, and access control.
class LogitCore {
  /// Current logger configuration (reactive).
  static final ValueNotifier<LoggerConfig> config =
      ValueNotifier(const LoggerConfig());
  static bool _initialized = false;
  static OverlayEntry? _loggerOverlayEntry;
  static bool _overlayShown = false;

  // Container for accessing providers outside the widget tree
  static ProviderContainer? container;

  /// Initialize the provider container for use in non-widget contexts
  static void initializeProviderContainer(ProviderContainer coreContainer) {
    container = coreContainer;
  }

  /// Initialize the logger with the given configuration.
  static void init(LoggerConfig initialConfig) {
    config.value = initialConfig;
    _initialized = true;
  }

  /// Update the logger configuration at runtime. Listeners will be notified.
  static void updateConfig(LoggerConfig newConfig) {
    config.value = newConfig;
  }

  /// Returns true if the logger should be accessible for the current user.
  /// Checks debug mode or allowedIds (to be used in UI logic).
  /// If allowedIds is empty, no one is allowed by ID.
  static bool canAccess({String? userId}) {
    if (!_initialized) {
      return false;
    }
    final cfg = config.value;
    if (cfg.enableInDebug) {
      return true;
    }
    if (cfg.allowedIds.isEmpty) {
      return false;
    }
    if (userId != null && cfg.allowedIds.contains(userId)) {
      return true;
    }
    return false;
  }

  /// Attach a global long-press gesture to open the logger overlay.
  /// Call this in your app's root widget (e.g., in build or initState).
  static void attachLongPress(BuildContext context, {String? userId}) {
    if (!_initialized) return;
    if (!config.value.enableLongPressGesture) return;
    if (!canAccess(userId: userId)) return;
    if (_overlayShown) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    // Add a Listener to capture long-press anywhere
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlay.insert(
        OverlayEntry(
          builder: (ctx) => _LongPressDetector(
            onLongPress: () {
              if (_overlayShown) return;
              _showOverlay(context);
            },
          ),
        ),
      );
    });
  }

  /// Show the logger overlay screen.
  static void _showOverlay(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _loggerOverlayEntry = OverlayEntry(
      builder: (ctx) => LoggerOverlayScreen(),
    );
    overlay.insert(_loggerOverlayEntry!);
    _overlayShown = true;
  }

  /// Hide the logger overlay screen.
  static void hideOverlay() {
    _loggerOverlayEntry?.remove();
    _loggerOverlayEntry = null;
    _overlayShown = false;
  }
}

/// Internal widget to capture long-press anywhere on the screen.
class _LongPressDetector extends StatelessWidget {
  final VoidCallback onLongPress;

  const _LongPressDetector({required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: onLongPress,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Public API for logging from outside the plugin.
///
/// Use [Logit.debug], [Logit.info], [Logit.error], and [Logit.api] to log messages and API calls.
class Logit {
  /// Initializes the logger. Call this in your app's main() or before using any logging.
  static void init(LoggerConfig config) => LogitCore.init(config);

  /// Logs a debug/info message.
  static void debug(String heading, String content) {
    LogitCore.container?.read(loggerProvider.notifier).addDebugLog(
          heading: heading,
          content: content,
          level: DebugLogLevel.info,
        );
  }

  /// Logs an info message.
  static void info(String heading, String content) => debug(heading, content);

  /// Logs an error message.
  static void error(String heading, String content) {
    LogitCore.container?.read(loggerProvider.notifier).addDebugLog(
          heading: heading,
          content: content,
          level: DebugLogLevel.error,
        );
  }

  /// Logs an API request/response manually.
  static void api({
    required String heading,
    required String content,
    required String method,
    required String url,
    required Map<String, dynamic> headers,
    dynamic body,
    int? statusCode,
    Duration? timings,
    int? memoryUsage,
  }) {
    LogitCore.container?.read(loggerProvider.notifier).addApiLog(
          heading: heading,
          content: content,
          method: method,
          url: url,
          headers: headers,
          body: body,
          statusCode: statusCode,
          timings: timings,
          memoryUsage: memoryUsage,
        );
  }

  /// Wraps an http.Client to enable API logging.
  static LoggerHttp wrapHttp([dynamic client]) {
    return LoggerHttp(client);
  }

  /// Initialize a provider container for service classes
  static void initializeProviderContainer(ProviderContainer container) {
    LogitCore.initializeProviderContainer(container);
    LoggerDio.initializeProviderContainer(container);
  }
}
