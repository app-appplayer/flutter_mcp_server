import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for the Flutter MCP server
class FlutterMcpServerConfig {
  /// Default setting for running in background
  static const bool defaultRunInBackground = false;
  
  /// Default request handler timeout in seconds
  static const int defaultRequestHandlerTimeoutSeconds = 30;
  
  /// Default maximum concurrent requests
  static const int defaultMaxConcurrentRequests = 5;
  
  /// Default resource usage monitoring setting
  static const bool defaultMonitorResourceUsage = true;
  
  /// Default resource stats update interval in seconds
  static const int defaultResourceStatsUpdateIntervalSeconds = 5;
  
  /// Whether to keep server running when app is in background
  final bool runInBackground;
  
  /// Timeout for request handlers
  final Duration requestHandlerTimeout;
  
  /// Maximum number of concurrent requests
  final int maxConcurrentRequests;
  
  /// Whether to monitor resource usage
  final bool monitorResourceUsage;
  
  /// Interval for resource stats updates
  final int resourceStatsUpdateIntervalSeconds;
  
  /// Whether to use foreground service on Android
  final bool useAndroidForegroundService;
  
  /// Whether to register server with system tray on desktop
  final bool registerWithSystemTray;
  
  /// Create a new server configuration
  FlutterMcpServerConfig({
    this.runInBackground = defaultRunInBackground,
    Duration? requestHandlerTimeout,
    this.maxConcurrentRequests = defaultMaxConcurrentRequests,
    this.monitorResourceUsage = defaultMonitorResourceUsage,
    this.resourceStatsUpdateIntervalSeconds = defaultResourceStatsUpdateIntervalSeconds,
    this.useAndroidForegroundService = true,
    this.registerWithSystemTray = true,
  }) : 
    requestHandlerTimeout = requestHandlerTimeout ?? Duration(seconds: defaultRequestHandlerTimeoutSeconds);
  
  /// Create a configuration with default values
  factory FlutterMcpServerConfig.defaults() {
    return FlutterMcpServerConfig();
  }
  
  /// Load configuration from shared preferences
  static Future<FlutterMcpServerConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('flutter_mcp_server_config');
    
    if (configJson == null) {
      return FlutterMcpServerConfig.defaults();
    }
    
    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      return FlutterMcpServerConfig.fromJson(configMap);
    } catch (e) {
      // If config is corrupted, return defaults
      return FlutterMcpServerConfig.defaults();
    }
  }
  
  /// Save configuration to shared preferences
  Future<bool> save() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString('flutter_mcp_server_config', jsonEncode(toJson()));
  }
  
  /// Convert configuration to JSON map
  Map<String, dynamic> toJson() {
    return {
      'runInBackground': runInBackground,
      'requestHandlerTimeoutSeconds': requestHandlerTimeout.inSeconds,
      'maxConcurrentRequests': maxConcurrentRequests,
      'monitorResourceUsage': monitorResourceUsage,
      'resourceStatsUpdateIntervalSeconds': resourceStatsUpdateIntervalSeconds,
      'useAndroidForegroundService': useAndroidForegroundService,
      'registerWithSystemTray': registerWithSystemTray,
    };
  }
  
  /// Create configuration from JSON map
  factory FlutterMcpServerConfig.fromJson(Map<String, dynamic> json) {
    return FlutterMcpServerConfig(
      runInBackground: json['runInBackground'] ?? defaultRunInBackground,
      requestHandlerTimeout: Duration(seconds: json['requestHandlerTimeoutSeconds'] ?? defaultRequestHandlerTimeoutSeconds),
      maxConcurrentRequests: json['maxConcurrentRequests'] ?? defaultMaxConcurrentRequests,
      monitorResourceUsage: json['monitorResourceUsage'] ?? defaultMonitorResourceUsage,
      resourceStatsUpdateIntervalSeconds: json['resourceStatsUpdateIntervalSeconds'] ?? defaultResourceStatsUpdateIntervalSeconds,
      useAndroidForegroundService: json['useAndroidForegroundService'] ?? true,
      registerWithSystemTray: json['registerWithSystemTray'] ?? true,
    );
  }
  
  /// Create a copy of this configuration with specified fields replaced
  FlutterMcpServerConfig copyWith({
    bool? runInBackground,
    Duration? requestHandlerTimeout,
    int? maxConcurrentRequests,
    bool? monitorResourceUsage,
    int? resourceStatsUpdateIntervalSeconds,
    bool? useAndroidForegroundService,
    bool? registerWithSystemTray,
  }) {
    return FlutterMcpServerConfig(
      runInBackground: runInBackground ?? this.runInBackground,
      requestHandlerTimeout: requestHandlerTimeout ?? this.requestHandlerTimeout,
      maxConcurrentRequests: maxConcurrentRequests ?? this.maxConcurrentRequests,
      monitorResourceUsage: monitorResourceUsage ?? this.monitorResourceUsage,
      resourceStatsUpdateIntervalSeconds: resourceStatsUpdateIntervalSeconds ?? this.resourceStatsUpdateIntervalSeconds,
      useAndroidForegroundService: useAndroidForegroundService ?? this.useAndroidForegroundService,
      registerWithSystemTray: registerWithSystemTray ?? this.registerWithSystemTray,
    );
  }
}
