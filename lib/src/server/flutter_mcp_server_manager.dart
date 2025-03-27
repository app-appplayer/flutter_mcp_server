import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart';

import 'flutter_mcp_server.dart';

/// Manager for multiple MCP server instances
class FlutterMcpServerManager {
  static final FlutterMcpServerManager _instance = FlutterMcpServerManager._();
  
  /// Get singleton instance
  static FlutterMcpServerManager get instance => _instance;
  
  /// Map of server instances by ID
  final _servers = <String, FlutterMcpServer>{};
  
  /// Whether the manager has been disposed
  bool _isDisposed = false;
  
  /// Stream controller for server registration events
  final _serverRegistrationController = StreamController<String>.broadcast();
  
  /// Stream controller for server state events
  final _serverStateController = StreamController<Map<String, ServerState>>.broadcast();
  
  /// Background service for managing servers
  FlutterMcpBackgroundService? _backgroundService;
  
  /// Background mode status
  //bool _backgroundMode = false;
  
  /// Private constructor
  FlutterMcpServerManager._() {
    // Initialize background service if supported
    if (FlutterMcpPlatform.instance.supportsBackgroundExecution) {
      _initBackgroundService();
    }
  }
  
  /// Stream of server registration events
  Stream<String> get onServerRegistered => _serverRegistrationController.stream;
  
  /// Stream of server state events
  Stream<Map<String, ServerState>> get onServerStateChanged => _serverStateController.stream;
  
  /// Initialize background service
  Future<void> _initBackgroundService() async {
    _backgroundService = FlutterMcpBackgroundService();
    
    // Register background task for server management
    await _backgroundService?.register('mcpServersTask', () {
      // This would be a method that keeps servers running in background
      // We'll implement a placeholder version
      _keepServersAlive();
    });
  }
  
  /// Register a server with the manager
  Future<void> registerServer(String id, FlutterMcpServer server) async {
    if (_isDisposed) {
      throw StateError('Manager has been disposed');
    }
    
    if (_servers.containsKey(id)) {
      throw ArgumentError('Server with ID "$id" is already registered');
    }
    
    // Store server
    _servers[id] = server;
    
    // Listen for server state changes
    server.stateStream.listen((state) {
      _notifyStateChange();
    });
    
    // Notify listeners
    _serverRegistrationController.add(id);
    _notifyStateChange();
    
    if (kDebugMode) {
      print('Flutter MCP Server Manager: Registered server with ID "$id"');
    }
  }
  
  /// Unregister a server from the manager
  Future<void> unregisterServer(String id) async {
    if (_isDisposed) {
      return;
    }
    
    final server = _servers.remove(id);
    
    if (server != null) {
      if (server.isRunning) {
        await server.stop();
      }
      
      if (kDebugMode) {
        print('Flutter MCP Server Manager: Unregistered server with ID "$id"');
      }
      
      _notifyStateChange();
    }
  }
  
  /// Get a server by ID
  FlutterMcpServer? getServer(String id) {
    if (_isDisposed) {
      return null;
    }
    
    return _servers[id];
  }
  
  /// Get all registered servers
  List<FlutterMcpServer> getAllServers() {
    if (_isDisposed) {
      return [];
    }
    
    return _servers.values.toList();
  }
  
  /// Get servers filtered by state
  List<FlutterMcpServer> getServersByState(ServerState state) {
    if (_isDisposed) {
      return [];
    }
    
    return _servers.values
        .where((server) => server.serverState == state)
        .toList();
  }
  
  /// Get all running servers
  List<FlutterMcpServer> getRunningServers() {
    return getServersByState(ServerState.running);
  }
  
  /// Start all registered servers
  Future<void> startAll() async {
    if (_isDisposed) {
      return;
    }
    
    final servers = getAllServers();
    
    for (final server in servers) {
      if (server.serverState == ServerState.stopped) {
        try {
          // Only try to start if server has a transport
          final transport = server.getTransport();
          if (transport != null) {
            await server.start(transport);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Flutter MCP Server Manager: Failed to start server: $e');
          }
          // Continue with other servers even if one fails
        }
      }
    }
    
    _notifyStateChange();
  }
  
  /// Stop all registered servers
  Future<void> stopAll() async {
    if (_isDisposed) {
      return;
    }
    
    final servers = getAllServers();
    
    for (final server in servers) {
      try {
        await server.stop();
      } catch (e) {
        if (kDebugMode) {
          print('Flutter MCP Server Manager: Failed to stop server: $e');
        }
        // Continue with other servers even if one fails
      }
    }
    
    _notifyStateChange();
  }
  
  /// Adjust resource usage for all servers
  void adjustResourceUsage(AppResourceMode mode) {
    if (_isDisposed) {
      return;
    }
    
    final servers = getAllServers();
    
    for (final server in servers) {
      server.adjustResourceUsage(mode);
    }
  }

  /// Enable background running for servers
  Future<void> enableBackgroundRunning(bool enabled) async {
    if (_isDisposed || _backgroundService == null) {
      return;
    }

    if (enabled) {
      await _backgroundService?.startService();
      await _backgroundService?.schedulePeriodicTask(
        const Duration(minutes: 15), // Periodic interval
        'mcpServersTask',
      );
      //_backgroundMode = true;

      // Apply background mode to all servers
      for (final server in getAllServers()) {
        if (server.config.runInBackground) {
          server.adjustResourceUsage(AppResourceMode.minimal);
        }
      }
    } else {
      await _backgroundService?.stopService();
      //_backgroundMode = false;

      // Reset resource mode for running servers
      for (final server in getRunningServers()) {
        server.adjustResourceUsage(AppResourceMode.full);
      }
    }
  }
  /// Keep servers alive during background execution
  void _keepServersAlive() {
    // This would contain logic to ensure servers stay running
    // For example, restarting crashed servers, monitoring health, etc.
    if (_isDisposed) {
      return;
    }
    
    if (kDebugMode) {
      print('Flutter MCP Server Manager: Keeping servers alive in background');
    }
    
    // Simple version: ensure all servers that should be running are running
    final servers = getAllServers();
    
    for (final server in servers) {
      if (server.config.runInBackground && 
          server.serverState != ServerState.running && 
          server.serverState != ServerState.starting) {
        
        try {
          final transport = server.getTransport();
          if (transport != null) {
            server.start(transport);
          }
        } catch (e) {
          // Log error but continue with other servers
          if (kDebugMode) {
            print('Flutter MCP Server Manager: Failed to restart server in background: $e');
          }
        }
      }
    }
  }
  
  /// Notify listeners about server state changes
  void _notifyStateChange() {
    if (_isDisposed) {
      return;
    }
    
    final states = <String, ServerState>{};
    
    for (final entry in _servers.entries) {
      states[entry.key] = entry.value.serverState;
    }
    
    _serverStateController.add(states);
  }
  
  /// Dispose all servers and release resources
  void dispose() {
    if (_isDisposed) {
      return;
    }
    
    _isDisposed = true;
    
    // Stop and dispose all servers
    final servers = getAllServers();
    
    for (final server in servers) {
      server.stop();
      server.dispose();
    }
    
    _servers.clear();
    
    // Stop background service
    _backgroundService?.stopService();
    
    // Close stream controllers
    _serverRegistrationController.close();
    _serverStateController.close();
  }
}
