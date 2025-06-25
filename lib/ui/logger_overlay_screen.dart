// UI: Logger Overlay Screen
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_loggerx/dev_loggerx.dart';
import 'package:dev_loggerx/models/api_log_model.dart';
import 'package:dev_loggerx/models/debug_log_model.dart';
import 'package:dev_loggerx/models/dev_log_model.dart';
import 'package:dev_loggerx/models/log_enums.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'log_list_view.dart';
import 'seconds_ago_messages.dart';
import 'segmented_tab_bar.dart';
import 'settings_detail_page.dart';
import 'floating_rounded_app_bar.dart';

/// Overlay screen for viewing, searching, and filtering logs in-app.
///
/// Displays segmented tabs for All, Debug, Logs, and API logs, with search,
/// filter, export, and settings. Used as the main overlay UI for DevLoggerX.
class LoggerOverlayScreen extends ConsumerStatefulWidget {
  const LoggerOverlayScreen({super.key});

  @override
  ConsumerState<LoggerOverlayScreen> createState() =>
      _LoggerOverlayScreenState();
}

/// State for [LoggerOverlayScreen]. Handles tab selection, search, filtering, and log export.
class _LoggerOverlayScreenState extends ConsumerState<LoggerOverlayScreen> {
  int _selectedIndex = 0;
  final List<String> _tabs = ['All', 'Debug', 'Logs', 'API'];
  String _search = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  int _searchIndex = 0;
  List<int> _searchMatches = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _overlayNavigatorKey =
      GlobalKey<NavigatorState>();

  // Debug filter state
  String _debugFilter = 'All';
  final List<String> _debugFilters = ['All', 'Info', 'Warning', 'Error'];

  @override
  void initState() {
    super.initState();
    registerTimeagoLocale();
  }

  /// Called when the search text changes. Updates search matches and highlights.
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

  /// Navigate to the previous search match.
  void _goToPrevMatch() {
    setState(() {
      if (_searchMatches.isNotEmpty) {
        _searchIndex =
            (_searchIndex - 1 + _searchMatches.length) % _searchMatches.length;
      }
    });
  }

  /// Navigate to the next search match.
  void _goToNextMatch() {
    setState(() {
      if (_searchMatches.isNotEmpty) {
        _searchIndex = (_searchIndex + 1) % _searchMatches.length;
      }
    });
  }

  /// Show the settings page with device/app info and log sharing.
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
          builder: (_) => SettingsDetailPage(
            info: info,
            onShare: _showShareDialogAndShare,
          ),
        ),
      );
    }
  }

  /// Show the share dialog and export logs.
  Future<void> _showShareDialogAndShare() async {
    print("clicked share logs");
    final logTypes = ['All', 'Debug', 'Logs', 'API'];
    int selectedIndex = 0;
    final dialogContext = _overlayNavigatorKey.currentContext;
    if (dialogContext == null || !mounted) {
      print("Navigator context is not available or widget is not mounted.");
      return;
    }
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
                    await _shareLogsWithDeviceInfo(dialogContext,
                        filterIndex: selectedIndex);
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

  /// Share logs with device info, filtered by log type.
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
      'logs': filteredLogs.map((log) => logToJson(log)).toList(),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(loggerProvider);
    final sortedLogs = [...logs]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final debugLogs =
        sortedLogs.where((l) => l.type == DevLogType.debug.name).toList();
    final logLogs =
        sortedLogs.where((l) => l.type == DevLogType.log.name).toList();
    final apiLogs =
        sortedLogs.where((l) => l.type == DevLogType.api.name).toList();

    // Apply debug filter
    List<DevLogModel> filteredDebugLogs = debugLogs;
    if (_debugFilter != 'All') {
      filteredDebugLogs = debugLogs.where((log) {
        if (log is DebugLogModel) {
          return log.level.toLowerCase() == _debugFilter.toLowerCase();
        }
        return false;
      }).toList();
    }

    List<List<DevLogModel>> logViews = [
      sortedLogs,
      filteredDebugLogs,
      logLogs,
      apiLogs,
    ];

    List<List<DevLogModel>> filteredViews = logViews
        .map((list) => list
            .where((log) =>
                log.heading.toLowerCase().contains(_search.toLowerCase()) ||
                log.content.toLowerCase().contains(_search.toLowerCase()))
            .toList())
        .toList();

    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'RobotoMono', // Use a monospaced font
        ),
      ),
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
          body: Column(
            children: [
              FloatingRoundedAppBar(
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
              const SizedBox(height: 8),
              SegmentedTabBar(
                tabs: _tabs,
                selectedIndex: _selectedIndex,
                onTabSelected: (i) => setState(() => _selectedIndex = i),
              ),
              // Debug filter row
              if (_selectedIndex == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _debugFilters.map((filter) {
                      final selected = _debugFilter == filter;
                      Color color;
                      switch (filter) {
                        case 'Info':
                          color = Colors.blueAccent;
                          break;
                        case 'Warning':
                          color = Colors.orangeAccent;
                          break;
                        case 'Error':
                          color = Colors.redAccent;
                          break;
                        default:
                          color = Colors.grey;
                      }
                      return ChoiceChip(
                        label: Text(filter, style: TextStyle(fontFamily: 'RobotoMono')),
                        selected: selected,
                        selectedColor: color.withAlpha(2),
                        backgroundColor: Colors.grey[850],
                        labelStyle: TextStyle(
                          color: selected ? color : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoMono',
                        ),
                        onSelected: (_) {
                          setState(() => _debugFilter = filter);
                        },
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: List.generate(
                    _tabs.length,
                    (i) => LogListView(
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
}

Map<String, dynamic> logToJson(DevLogModel log) {
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
