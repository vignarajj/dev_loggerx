import 'package:logitx/models/debug_log_model.dart';
import 'package:logitx/models/dev_log_model.dart';
import 'package:logitx/models/log_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'seconds_ago_messages.dart';

/// Card widget for displaying a single log entry (debug, log, or API).
///
/// Shows heading, timestamp, content, and type/level with color. Supports copy on long-press.
class GenericLogCard extends StatelessWidget {
  final DevLogModel log;
  final bool isHighlighted;
  final VoidCallback? onCopy;

  const GenericLogCard({
    required this.log,
    this.isHighlighted = false,
    this.onCopy,
    super.key,
  });

  /// Builds the log card UI.
  @override
  Widget build(BuildContext context) {
    final isDebug = log is DebugLogModel;
    Color? debugColor;
    String? debugLabel;
    if (isDebug) {
      final level = (log as DebugLogModel).level.toLowerCase();
      switch (level) {
        case 'info':
          debugColor = Colors.blueAccent;
          debugLabel = 'INFO';
          break;
        case 'warning':
          debugColor = Colors.orangeAccent;
          debugLabel = 'WARNING';
          break;
        case 'error':
          debugColor = Colors.redAccent;
          debugLabel = 'ERROR';
          break;
        default:
          debugColor = Colors.grey;
          debugLabel = level.toUpperCase();
      }
    }
    return Card(
      color: isHighlighted ? Colors.blueGrey[800] : Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(
              ClipboardData(text: '${log.heading}\n${log.content}'));
          if (onCopy != null) onCopy!();
        },
        child: ListTile(
          title: Text(
            log.heading,
            style:
                const TextStyle(color: Colors.white, fontFamily: 'RobotoMono'),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatTimestamp(log.timestamp),
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'RobotoMono'),
              ),
              const SizedBox(height: 2),
              Text(
                log.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70, fontFamily: 'RobotoMono'),
              ),
            ],
          ),
          trailing: isDebug
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      debugLabel!,
                      style: TextStyle(
                        color: debugColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Text(
                  log.type.toUpperCase(),
                  style: TextStyle(
                    color: log.type == DevLogType.api.name
                        ? Colors.orangeAccent
                        : log.type == DevLogType.debug.name
                            ? Colors.lightBlueAccent
                            : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                  ),
                ),
        ),
      ),
    );
  }
}
