import 'package:dev_loggerx/models/api_log_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'seconds_ago_messages.dart';

class ApiLogCard extends StatefulWidget {
  final ApiLogModel apiLog;
  final bool isHighlighted;
  final VoidCallback? onCopy;

  const ApiLogCard({
    required this.apiLog,
    this.isHighlighted = false,
    this.onCopy,
    super.key,
  });

  @override
  State<ApiLogCard> createState() => ApiLogCardState();
}

class ApiLogCardState extends State<ApiLogCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.apiLog;
    return Card(
      color: widget.isHighlighted ? Colors.blueGrey[800] : Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          onLongPress: () {
            Clipboard.setData(ClipboardData(
                text: '[${log.method}] ${log.url}\n${log.content}'));
            if (widget.onCopy != null) widget.onCopy!();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '[${log.method}]',
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.url,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatTimestamp(log.timestamp),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                if (_expanded) ...[
                  const Divider(color: Colors.white12, height: 16),
                  ApiDetailRow(
                      label: 'Status',
                      value: log.statusCode?.toString() ?? '—'),
                  ApiDetailRow(
                      label: 'Timings',
                      value: log.timings != null ? '${log.timings} ms' : '—'),
                  ApiDetailRow(
                      label: 'Headers',
                      value: log.headers.isNotEmpty
                          ? log.headers.toString()
                          : '—'),
                  ApiDetailRow(
                      label: 'Request Body',
                      value: log.body?.toString() ?? '—'),
                  ApiDetailRow(label: 'Response', value: log.content),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApiDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const ApiDetailRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
