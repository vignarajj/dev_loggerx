// UI layer for DevLogger plugin
// Provides the overlay screen, segmented navigation, log cards, search, export, and settings UI.

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_loggerx/dev_loggerx.dart';
import 'package:dev_loggerx/services/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

/// The main overlay screen for viewing and managing logs.
/// Includes segmented navigation, search, export, and settings.
class LoggerOverlayScreen extends ConsumerStatefulWidget {
  const LoggerOverlayScreen({super.key});

  @override
  ConsumerState<LoggerOverlayScreen> createState() =>
      _LoggerOverlayScreenState();
}

class _LoggerOverlayScreenState extends ConsumerState<LoggerOverlayScreen> {
  // Index of the selected tab
  int _selectedIndex = 0;

  // Tab labels
  final List<String> _tabs = ['All', 'Debug', 'Logs', 'API'];

  // Current search query
  String _search = '';

  // Whether the search bar is shown
  bool _showSearch = false;

  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();
  int _searchIndex = 0;
  List<int> _searchMatches = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _overlayNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _registerTimeagoLocale();
  }

  void _onSearchChanged(String v, List<DevLogModel> logs) {
    setState(() {
      _search = v;
      _searchMatches = [];
      _searchIndex = 0;
      if (_search.isNotEmpty) {
        for (int i = 0; i < logs.length; i++) {
          if (logs[i].heading.toLowerCase().contains(_search.toLowerCase()) ||
              logs[i].content.toLowerCase().contains(_search.toLowerCase())) {
            _searchMatches.add(i);
          }
        }
      }
    });
  }

  void _goToPrevMatch() {
    setState(() {
      if (_searchMatches.isNotEmpty) {
        _searchIndex =
            (_searchIndex - 1 + _searchMatches.length) % _searchMatches.length;
      }
    });
  }

  void _goToNextMatch() {
    setState(() {
      if (_searchMatches.isNotEmpty) {
        _searchIndex = (_searchIndex + 1) % _searchMatches.length;
      }
    });
  }

  void _showSettingsPage(BuildContext context) async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    Map<String, dynamic> info = {};
    String os = '';
    String osVersion = '';
    String deviceName = '';
    String manufacturer = '';
    String isPhysicalDevice = '';
    String networkType = '-';
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      networkType = 'Mobile';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      networkType = 'WiFi';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      networkType = 'Ethernet';
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      networkType = 'VPN';
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      networkType = 'Other';
    } else {
      networkType = 'None';
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      os = 'Android';
      osVersion = android.version.release;
      deviceName = android.model;
      manufacturer = android.manufacturer;
      isPhysicalDevice = android.isPhysicalDevice ? 'Yes' : 'No';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final ios = await deviceInfo.iosInfo;
      os = 'iOS';
      osVersion = ios.systemVersion;
      deviceName = ios.name;
      manufacturer = 'Apple';
      isPhysicalDevice = ios.isPhysicalDevice ? 'Yes' : 'No';
    } else {
      os = Theme.of(context).platform.name;
      osVersion = '-';
      deviceName = '-';
      manufacturer = '-';
      isPhysicalDevice = '-';
    }
    info = {
      'OS': os,
      'OS Version': osVersion,
      'Device Name': deviceName,
      'Manufacturer': manufacturer,
      'Is Physical Device': isPhysicalDevice,
      'Network Type': networkType,
      'App Version': packageInfo.version,
      'App Build Number': packageInfo.buildNumber,
    };
    if (mounted) {
      _overlayNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => _SettingsDetailPage(
            info: info,
            onShare: _showShareDialogAndShare,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Build the overlay UI with segmented navigation, search, and log list.
  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(loggerProvider);
    // Sort logs by timestamp descending (latest first)
    final sortedLogs = [...logs]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final debugLogs =
        sortedLogs.where((l) => l.type == DevLogType.debug.name).toList();
    final logLogs =
        sortedLogs.where((l) => l.type == DevLogType.log.name).toList();
    final apiLogs =
        sortedLogs.where((l) => l.type == DevLogType.api.name).toList();

    List<List<DevLogModel>> logViews = [
      sortedLogs,
      debugLogs,
      logLogs,
      apiLogs,
    ];

    // Apply search filter
    List<List<DevLogModel>> filteredViews = logViews
        .map((list) => list
            .where((log) =>
                log.heading.toLowerCase().contains(_search.toLowerCase()) ||
                log.content.toLowerCase().contains(_search.toLowerCase()))
            .toList())
        .toList();

    return MaterialApp(
      theme: ThemeData.dark(),
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorKey: _overlayNavigatorKey,
      home: PopScope(
        onPopInvokedWithResult: (res, _) async {
          final nav = _overlayNavigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          } else {
            LoggerCore.hideOverlay();
          }
        },
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: _showSearch
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search logs...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => _onSearchChanged(v, sortedLogs),
                        ),
                      ),
                      if (_searchMatches.isNotEmpty)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward,
                                  color: Colors.white),
                              onPressed: _goToPrevMatch,
                            ),
                            Text(
                              '${_searchMatches.isEmpty ? 0 : _searchIndex + 1}/${_searchMatches.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward,
                                  color: Colors.white),
                              onPressed: _goToNextMatch,
                            ),
                          ],
                        ),
                    ],
                  )
                : const Text(
                    'Dev Logger',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
            backgroundColor: Colors.grey[900],
            actions: [
              if (!_showSearch)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _showSearch = true),
                  tooltip: 'Search',
                ),
              if (_showSearch)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearch = false;
                      _search = '';
                      _searchController.clear();
                      _searchMatches = [];
                      _searchIndex = 0;
                    });
                  },
                  tooltip: 'Close search',
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsPage(context),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 8),
              _SegmentedTabBar(
                tabs: _tabs,
                selectedIndex: _selectedIndex,
                onTabSelected: (i) => setState(() => _selectedIndex = i),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: List.generate(
                    _tabs.length,
                    (i) => _LogListView(
                      logs: filteredViews[i],
                      highlightIndices: _searchMatches,
                      highlightIndex: _searchIndex,
                      onCopy: () {
                        final messenger = _scaffoldMessengerKey.currentState;
                        messenger?.showSnackBar(
                          const SnackBar(
                            content: Text('Log copied to clipboard!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Show the export modal bottom sheet with filters and export options.
  void _showExportSheet(BuildContext context) {
    final logs = ref.read(loggerProvider);
    DevLogType? selectedType;
    DateTimeRange? selectedRange;
    String search = '';
    String exportFormat = 'json';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export Logs',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<DevLogType?>(
                    value: selectedType,
                    dropdownColor: Colors.grey[900],
                    decoration: const InputDecoration(
                      labelText: 'Log Type',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('All',
                              style: TextStyle(color: Colors.white))),
                      ...DevLogType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name,
                                style: const TextStyle(color: Colors.white)),
                          )),
                    ],
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search keyword',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setSheetState(() => search = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(now.year - 5),
                              lastDate: now,
                              initialDateRange: selectedRange,
                              builder: (context, child) => Theme(
                                data: ThemeData.dark(),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedRange = picked);
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: Text(selectedRange == null
                              ? 'Date range'
                              : '${selectedRange!.start.toLocal()} - ${selectedRange!.end.toLocal()}'),
                        ),
                      ),
                      if (selectedRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () =>
                              setSheetState(() => selectedRange = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'json',
                        groupValue: exportFormat,
                        onChanged: (v) =>
                            setSheetState(() => exportFormat = v!),
                        activeColor: Colors.blueAccent,
                      ),
                      const Text('JSON', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'txt',
                        groupValue: exportFormat,
                        onChanged: (v) =>
                            setSheetState(() => exportFormat = v!),
                        activeColor: Colors.blueAccent,
                      ),
                      const Text('Plain Text',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Download Logs?',
                                style: TextStyle(color: Colors.white)),
                            content: const Text(
                                'Do you want to download the exported logs to your Downloads folder?',
                                style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        final filtered = logs.where((log) {
                          if (selectedType?.name != null &&
                              log.type != selectedType?.name) {
                            return false;
                          }
                          if (search.isNotEmpty &&
                              !('${log.heading} ${log.content}'
                                  .toLowerCase()
                                  .contains(search.toLowerCase()))) {
                            return false;
                          }
                          if (selectedRange != null &&
                              (log.timestamp.isBefore(selectedRange!.start) ||
                                  log.timestamp.isAfter(selectedRange!.end))) {
                            return false;
                          }
                          return true;
                        }).toList();
                        final now = DateTime.now();
                        final appInfo =
                            'App: MyApp\nExported: \\${now.toIso8601String()}';
                        String exportData;
                        String fileExt;
                        if (exportFormat == 'json') {
                          exportData = jsonEncode({
                            'appInfo': appInfo,
                            'logs':
                                filtered.map((log) => _logToJson(log)).toList(),
                          });
                          fileExt = 'json';
                        } else {
                          exportData =
                              '$appInfo\n\n\\${filtered.map((log) => _logToText(log)).join('\n\n')}';
                          fileExt = 'txt';
                        }
                        Directory? downloadsDir;
                        try {
                          downloadsDir = await getDownloadsDirectory();
                        } catch (_) {}
                        downloadsDir ??= await getTemporaryDirectory();
                        final file = File(
                            '${downloadsDir.path}/dev_logs_${now.millisecondsSinceEpoch}.$fileExt');
                        await file.writeAsString(exportData);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          final messenger = _scaffoldMessengerKey.currentState;
                          messenger?.showSnackBar(
                            SnackBar(
                              content: Text('Logs exported to: ${file.path}'),
                              backgroundColor: Colors.blueAccent,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export & Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Format a log as JSON for export.
  Map<String, dynamic> _logToJson(DevLogModel log) {
    if (log is ApiLogModel) {
      return {
        'id': log.id,
        'timestamp': log.timestamp.toIso8601String(),
        'type': log.type,
        'heading': log.heading,
        'content': log.content,
        'method': log.method,
        'url': log.url,
        'headers': log.headers,
        'body': log.body,
        'statusCode': log.statusCode,
        'timings': log.timings,
        'memoryUsage': log.memoryUsage,
      };
    } else {
      return {
        'id': log.id,
        'timestamp': log.timestamp.toIso8601String(),
        'type': log.type,
        'heading': log.heading,
        'content': log.content,
      };
    }
  }

  /// Format a log as plain text for export.
  String _logToText(DevLogModel log) {
    if (log is ApiLogModel) {
      return '''[API] ${log.method} ${log.url}
Time: ${log.timestamp}
Status: ${log.statusCode}
Timings: ${log.timings ?? '-'} ms
Headers: ${jsonEncode(log.headers)}
Request Body: ${log.body}
Response: ${log.content}
Memory Usage: ${log.memoryUsage ?? '-'}
''';
    } else {
      return '[${log.type.toUpperCase()}] ${log.heading}\nTime: ${log.timestamp}\n${log.content}';
    }
  }

  Future<void> _showShareDialogAndShare() async {
    print("clicked share logs");
    final logTypes = ['All', 'Debug', 'Logs', 'API'];
    int selectedIndex = 0;
    // Ensure the overlay navigator's context is mounted
    final dialogContext = _overlayNavigatorKey.currentContext;
    if (dialogContext == null || !mounted) {
      print("Navigator context is not available or widget is not mounted.");
      return;
    }

    // Show dropdown instead of dialog
    showModalBottomSheet(
      context: dialogContext,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Log Type',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedIndex,
                dropdownColor: Colors.grey[900],
                decoration: const InputDecoration(
                  labelText: 'Log Type',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  logTypes.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(logTypes[i],
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                onChanged: (v) => selectedIndex = v!,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _shareLogsWithDeviceInfo(dialogContext, filterIndex: selectedIndex);
                  },
                  child: const Text('Share Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareLogsWithDeviceInfo(BuildContext context,
      {int filterIndex = 0}) async {
    final logs = ref.read(loggerProvider);
    List<DevLogModel> filteredLogs;
    switch (filterIndex) {
      case 1:
        filteredLogs =
            logs.where((l) => l.type == DevLogType.debug.name).toList();
        break;
      case 2:
        filteredLogs =
            logs.where((l) => l.type == DevLogType.log.name).toList();
        break;
      case 3:
        filteredLogs =
            logs.where((l) => l.type == DevLogType.api.name).toList();
        break;
      case 0:
      default:
        filteredLogs = logs;
    }
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    Map<String, dynamic> info = {};
    String os = '';
    String osVersion = '';
    String deviceName = '';
    String manufacturer = '';
    String isPhysicalDevice = '';
    String networkType = '-';
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      networkType = 'Mobile';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      networkType = 'WiFi';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      networkType = 'Ethernet';
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      networkType = 'VPN';
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      networkType = 'Other';
    } else {
      networkType = 'None';
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      os = 'Android';
      osVersion = android.version.release;
      deviceName = android.model;
      manufacturer = android.manufacturer;
      isPhysicalDevice = android.isPhysicalDevice ? 'Yes' : 'No';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final ios = await deviceInfo.iosInfo;
      os = 'iOS';
      osVersion = ios.systemVersion;
      deviceName = ios.name;
      manufacturer = 'Apple';
      isPhysicalDevice = ios.isPhysicalDevice ? 'Yes' : 'No';
    } else {
      os = Theme.of(context).platform.name;
      osVersion = '-';
      deviceName = '-';
      manufacturer = '-';
      isPhysicalDevice = '-';
    }
    info = {
      'OS': os,
      'OS Version': osVersion,
      'Device Name': deviceName,
      'Manufacturer': manufacturer,
      'Is Physical Device': isPhysicalDevice,
      'Network Type': networkType,
      'App Version': packageInfo.version,
      'App Build Number': packageInfo.buildNumber,
    };

    final now = DateTime.now();
    final exportMap = {
      'deviceInfo': info,
      'exportedAt': now.toIso8601String(),
      'logs': filteredLogs.map((log) => _logToJson(log)).toList(),
    };
    final exportData = const JsonEncoder.withIndent('  ').convert(exportMap);
    // Share as text if small, else as file
    final bytes = Uint8List.fromList(exportData.codeUnits);
    if (bytes.lengthInBytes < 80 * 1024) {
      await SharePlus.instance.share(ShareParams(text: exportData));
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = await File(
              '${tempDir.path}/devloggerx_logs_${now.millisecondsSinceEpoch}.json')
          .writeAsString(exportData);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Large logs shared as file.'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    }
  }
}

/// Segmented tab bar for switching log categories.
class _SegmentedTabBar extends StatelessWidget {
  /// Segmented tab bar for switching log categories.
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _SegmentedTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? Colors.blueAccent : Colors.grey[850],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// List view for displaying logs in cards.
class _LogListView extends StatelessWidget {
  /// List view for displaying logs in cards.
  final List<DevLogModel> logs;
  final List<int>? highlightIndices;
  final int? highlightIndex;
  final VoidCallback? onCopy;

  const _LogListView(
      {required this.logs,
      this.highlightIndices,
      this.highlightIndex,
      this.onCopy});

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
          return _ApiLogCard(
              apiLog: log, isHighlighted: isHighlighted, onCopy: onCopy);
        } else {
          return _GenericLogCard(
              log: log, isHighlighted: isHighlighted, onCopy: onCopy);
        }
      },
    );
  }
}

/// Card widget for generic/debug logs.
class _GenericLogCard extends StatelessWidget {
  /// Card widget for generic/debug logs.
  final DevLogModel log;
  final bool isHighlighted;
  final VoidCallback? onCopy;

  const _GenericLogCard(
      {required this.log, this.isHighlighted = false, this.onCopy});

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
                _formatTimestamp(log.timestamp),
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

/// Card widget for API logs with expandable details.
class _ApiLogCard extends StatefulWidget {
  /// Card widget for API logs with expandable details.
  final ApiLogModel apiLog;
  final bool isHighlighted;
  final VoidCallback? onCopy;

  const _ApiLogCard(
      {required this.apiLog, this.isHighlighted = false, this.onCopy});

  @override
  State<_ApiLogCard> createState() => _ApiLogCardState();
}

class _ApiLogCardState extends State<_ApiLogCard>
    with SingleTickerProviderStateMixin {
  // Whether the card is expanded
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
                Text(_formatTimestamp(log.timestamp),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                if (_expanded) ...[
                  const Divider(color: Colors.white12, height: 16),
                  _ApiDetailRow(
                      label: 'Status',
                      value: log.statusCode?.toString() ?? '—'),
                  _ApiDetailRow(
                      label: 'Timings',
                      value: log.timings != null ? '${log.timings} ms' : '—'),
                  _ApiDetailRow(
                      label: 'Headers',
                      value: log.headers.isNotEmpty
                          ? log.headers.toString()
                          : '—'),
                  _ApiDetailRow(
                      label: 'Request Body',
                      value: log.body?.toString() ?? '—'),
                  _ApiDetailRow(label: 'Response', value: log.content),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row widget for displaying API log details.
class _ApiDetailRow extends StatelessWidget {
  /// Row widget for displaying API log details.
  final String label;
  final String value;

  const _ApiDetailRow({required this.label, required this.value});

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

String _formatTimestamp(DateTime dt) {
  return timeago.format(dt, locale: 'en_seconds', allowFromNow: true);
}

class _SettingsDetailPage extends ConsumerWidget {
  final Map<String, dynamic> info;
  final VoidCallback? onShare;

  const _SettingsDetailPage({required this.info, this.onShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(loggerProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Device & App Info'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            tooltip: 'Share Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Logs',
            onPressed: () {
              notifier.clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All logs cleared!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: info.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 160,
                          child: Text(e.key,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16))),
                      Expanded(
                          child: Text(e.value.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// Custom timeago messages for seconds-precision
class SecondsAgoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => '';

  @override
  String suffixAgo() => 'ago';

  @override
  String suffixFromNow() => 'from now';

  @override
  String lessThanOneMinute(int seconds) => '$seconds seconds';

  @override
  String aboutAMinute(int minutes) => '1 minute';

  @override
  String minutes(int minutes) => '$minutes minutes';

  @override
  String aboutAnHour(int minutes) => '1 hour';

  @override
  String hours(int hours) => '$hours hours';

  @override
  String aDay(int hours) => '1 day';

  @override
  String days(int days) => '$days days';

  @override
  String aboutAMonth(int days) => '1 month';

  @override
  String months(int months) => '$months months';

  @override
  String aboutAYear(int year) => '1 year';

  @override
  String years(int years) => '$years years';

  @override
  String wordSeparator() => ' ';
}

// Register custom locale for seconds-precision
void _registerTimeagoLocale() {
  timeago.setLocaleMessages('en_seconds', SecondsAgoMessages());
}
