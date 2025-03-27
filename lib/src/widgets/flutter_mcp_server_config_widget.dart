import 'package:flutter/material.dart';
import '../server/flutter_mcp_server.dart';
import '../server/flutter_mcp_server_config.dart';

/// Widget for configuring MCP server settings
class FlutterMcpServerConfigWidget extends StatefulWidget {
  /// Server to configure
  final FlutterMcpServer server;
  
  /// Callback when configuration changes
  final Function(FlutterMcpServerConfig)? onConfigChanged;
  
  /// Custom theme data for widget styling
  final ThemeData? customTheme;
  
  /// Whether to show advanced settings
  final bool showAdvancedSettings;
  
  /// Whether to allow saving the configuration
  final bool allowSave;
  
  /// Create a server config widget
  const FlutterMcpServerConfigWidget({
    Key? key,
    required this.server,
    this.onConfigChanged,
    this.customTheme,
    this.showAdvancedSettings = false,
    this.allowSave = true,
  }) : super(key: key);

  @override
  State<FlutterMcpServerConfigWidget> createState() => _FlutterMcpServerConfigWidgetState();
}

class _FlutterMcpServerConfigWidgetState extends State<FlutterMcpServerConfigWidget> {
  /// Current server configuration
  late FlutterMcpServerConfig _config;
  
  /// Whether advanced settings are visible
  late bool _showAdvancedSettings;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with server's current config
    _config = widget.server.config;
    _showAdvancedSettings = widget.showAdvancedSettings;
  }
  
  /// Update config and notify
  void _updateConfig(FlutterMcpServerConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    
    widget.onConfigChanged?.call(newConfig);
  }
  
  /// Save configuration to preferences
  Future<void> _saveConfig() async {
    await _config.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved')),
    );
  }
  
  /// Reset configuration to defaults
  void _resetConfig() {
    setState(() {
      _config = FlutterMcpServerConfig.defaults();
    });
    
    widget.onConfigChanged?.call(_config);
  }
  
  /// Build settings section
  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build basic settings section
  Widget _buildBasicSettings() {
    return _buildSettingsSection(
      'Basic Settings',
      [
        SwitchListTile(
          title: const Text('Run in Background'),
          subtitle: const Text('Keep server running when app is in background'),
          value: _config.runInBackground,
          onChanged: (value) {
            _updateConfig(_config.copyWith(runInBackground: value));
          },
        ),
        
        ListTile(
          title: const Text('Max Concurrent Requests'),
          subtitle: const Text('Maximum number of requests to process simultaneously'),
          trailing: DropdownButton<int>(
            value: _config.maxConcurrentRequests,
            items: [1, 3, 5, 10, 15, 20].map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateConfig(_config.copyWith(maxConcurrentRequests: value));
              }
            },
          ),
        ),
        
        ListTile(
          title: const Text('Request Handler Timeout'),
          subtitle: const Text('Maximum time allowed for request handlers'),
          trailing: DropdownButton<int>(
            value: _config.requestHandlerTimeout.inSeconds,
            items: [5, 10, 30, 60, 120, 300].map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('${value}s'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateConfig(_config.copyWith(
                  requestHandlerTimeout: Duration(seconds: value),
                ));
              }
            },
          ),
        ),
      ],
    );
  }
  
  /// Build advanced settings section
  Widget _buildAdvancedSettings() {
    if (!_showAdvancedSettings) {
      return const SizedBox.shrink();
    }
    
    return _buildSettingsSection(
      'Advanced Settings',
      [
        SwitchListTile(
          title: const Text('Monitor Resource Usage'),
          subtitle: const Text('Track and report resource usage statistics'),
          value: _config.monitorResourceUsage,
          onChanged: (value) {
            _updateConfig(_config.copyWith(monitorResourceUsage: value));
          },
        ),
        
        ListTile(
          title: const Text('Resource Stats Update Interval'),
          subtitle: const Text('How often to update resource statistics'),
          trailing: DropdownButton<int>(
            value: _config.resourceStatsUpdateIntervalSeconds,
            items: [1, 3, 5, 10, 30, 60].map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('${value}s'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateConfig(_config.copyWith(
                  resourceStatsUpdateIntervalSeconds: value,
                ));
              }
            },
          ),
        ),
        
        SwitchListTile(
          title: const Text('Use Android Foreground Service'),
          subtitle: const Text('Run as a foreground service on Android'),
          value: _config.useAndroidForegroundService,
          onChanged: (value) {
            _updateConfig(_config.copyWith(useAndroidForegroundService: value));
          },
        ),
        
        SwitchListTile(
          title: const Text('Register with System Tray'),
          subtitle: const Text('Add icon to system tray on desktop'),
          value: _config.registerWithSystemTray,
          onChanged: (value) {
            _updateConfig(_config.copyWith(registerWithSystemTray: value));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.customTheme ?? Theme.of(context);
    
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Server Configuration'),
          actions: [
            if (widget.allowSave)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveConfig,
                tooltip: 'Save Configuration',
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetConfig,
              tooltip: 'Reset to Defaults',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Server information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('ID: ${widget.server.id}'),
                    Text('Name: ${widget.server.mcpServer.name}'),
                    Text('Version: ${widget.server.mcpServer.version}'),
                    Text('Protocol: ${widget.server.mcpServer.protocolVersion}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Basic settings
            _buildBasicSettings(),
            
            // Advanced settings toggle
            SwitchListTile(
              title: const Text('Show Advanced Settings'),
              value: _showAdvancedSettings,
              onChanged: (value) {
                setState(() {
                  _showAdvancedSettings = value;
                });
              },
            ),
            
            // Advanced settings (if enabled)
            _buildAdvancedSettings(),
          ],
        ),
      ),
    );
  }
}
