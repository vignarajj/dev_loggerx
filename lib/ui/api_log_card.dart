import 'package:logitx/models/api_log_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'seconds_ago_messages.dart';

/// Card widget for displaying an API log entry with expandable details.
///
/// Shows method, URL, status, timings, headers, and response. Supports copy on long-press.
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

/// State for [ApiLogCard]. Handles expansion and animation.
class ApiLogCardState extends State<ApiLogCard> {
  bool _expandedRequest = false;
  bool _expandedResponse = false;
  bool _expandedError = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.apiLog;
    final isError = log.statusCode != null && log.statusCode! >= 400;
    final cardColor = widget.isHighlighted ? Colors.blueGrey[800] : Colors.grey[900];
    final borderColor = isError ? Colors.redAccent : Colors.blueAccent;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withOpacity(0.4), width: 1.2),
      ),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: _buildFullApiLogText(log)));
          if (widget.onCopy != null) widget.onCopy!();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Method, URL, Status, Timings
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.method,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.url,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'RobotoMono',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    log.statusCode?.toString() ?? '—',
                    style: TextStyle(
                      color: isError ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Timings: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'RobotoMono',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    log.timings != null ? '${log.timings} ms' : '—',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontFamily: 'RobotoMono',
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatTimestamp(log.timestamp),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Request Section
              _SectionHeader(
                title: 'Request',
                expanded: _expandedRequest,
                onTap: () => setState(() => _expandedRequest = !_expandedRequest),
              ),
              if (_expandedRequest)
                _ApiSectionBody(
                  children: [
                    _ApiDetailRow(label: 'Headers', value: _prettyPrintJson(log.headers)),
                    _ApiDetailRow(label: 'Body', value: _prettyPrintJson(log.body)),
                  ],
                ),
              // Response Section
              _SectionHeader(
                title: 'Response',
                expanded: _expandedResponse,
                onTap: () => setState(() => _expandedResponse = !_expandedResponse),
              ),
              if (_expandedResponse)
                _ApiSectionBody(
                  children: [
                    _ApiDetailRow(label: 'Headers', value: _prettyPrintJson(log.headers)),
                    _ApiDetailRow(label: 'Body', value: _prettyPrintJson(log.content)),
                  ],
                ),
              // Error Section (if error)
              if (isError) ...[
                _SectionHeader(
                  title: 'Error',
                  expanded: _expandedError,
                  onTap: () => setState(() => _expandedError = !_expandedError),
                  color: Colors.redAccent,
                ),
                if (_expandedError)
                  _ApiSectionBody(
                    children: [
                      _ApiDetailRow(label: 'Error', value: log.content),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _prettyPrintJson(dynamic data) {
    if (data == null) return '—';
    try {
      if (data is String) {
        final decoded = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  String _buildFullApiLogText(ApiLogModel log) {
    return '[${log.method}] ${log.url}\nStatus: ${log.statusCode}\nTimings: ${log.timings} ms\n\nHeaders: ${_prettyPrintJson(log.headers)}\n\nRequest Body:\n${_prettyPrintJson(log.body)}\n\nResponse Body:\n${_prettyPrintJson(log.content)}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Color? color;

  const _SectionHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        margin: const EdgeInsets.only(top: 8, bottom: 2),
        decoration: BoxDecoration(
          color: (color ?? Colors.blueAccent).withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: color ?? Colors.blueAccent,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: color ?? Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiSectionBody extends StatelessWidget {
  final List<Widget> children;
  const _ApiSectionBody({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ApiDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _ApiDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
                fontSize: 12,
              ),
              maxLines: 16,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }
}

