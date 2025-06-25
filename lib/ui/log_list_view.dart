import 'package:dev_loggerx/models/api_log_model.dart';
import 'package:dev_loggerx/models/dev_log_model.dart';
import 'package:flutter/material.dart';
import 'generic_log_card.dart';
import 'api_log_card.dart';

class LogListView extends StatelessWidget {
  final List<DevLogModel> logs;
  final List<int>? highlightIndices;
  final int? highlightIndex;
  final VoidCallback? onCopy;

  const LogListView({
    required this.logs,
    this.highlightIndices,
    this.highlightIndex,
    this.onCopy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No logs', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, i) {
        final log = logs[i];
        final isHighlighted = highlightIndices != null &&
            highlightIndex != null &&
            highlightIndices!.isNotEmpty &&
            highlightIndices![highlightIndex!] == i;
        if (log is ApiLogModel) {
          return ApiLogCard(
              apiLog: log, isHighlighted: isHighlighted, onCopy: onCopy);
        } else {
          return GenericLogCard(
              log: log, isHighlighted: isHighlighted, onCopy: onCopy);
        }
      },
    );
  }
}
