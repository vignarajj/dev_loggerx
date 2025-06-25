import 'package:dev_loggerx/models/dev_log_model.dart';
import 'package:dev_loggerx/models/log_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'seconds_ago_messages.dart';

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

  @override
  Widget build(BuildContext context) {
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
          title: Text(log.heading, style: const TextStyle(color: Colors.white)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatTimestamp(log.timestamp),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                log.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          trailing: Text(
            log.type.toUpperCase(),
            style: TextStyle(
              color: log.type == DevLogType.api.name
                  ? Colors.orangeAccent
                  : log.type == DevLogType.debug.name
                      ? Colors.lightBlueAccent
                      : Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
