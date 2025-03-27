import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mcp_server/mcp_server.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart' hide LogLevel;
import 'package:uuid/uuid.dart';

import 'flutter_mcp_server_config.dart';

/// Server states
enum ServerState {
  /// Server is stopped
  stopped,
  
  /// Server is starting
  starting,
  
  /// Server is running
  running,
  
  /// Server has encountered an error
  error,
  
  /// Server is paused (app in background)
  paused
}

/// Resource statistics for server
class ServerResourceStats {
  /// CPU usage percentage
  final double cpuUsage;
  
  /// Memory usage in MB
  final double memoryUsageMB;
  
  /// Number of active connections
  final int activeConnections;
  
  /// Number of requests processed
  final int requestsProcessed;
  
  /// Number of errors occurred
  final int errorsCount;
  
  /// Create resource stats
  const ServerResourceStats({
    this.cpuUsage = 0.0,
    this.memoryUsageMB = 0.0,
    this.activeConnections = 0,
    this.requestsProcessed = 0,
    this.errorsCount = 0,
  });
}

/// Main Flutter server for MCP protocol
class FlutterMcpServer with WidgetsBindingObserver {
  /// Unique ID for this server instance
  final String id;
  
  /// Underlying MCP server instance
  final Server _server;
  
  /// Configuration for this server
  final FlutterMcpServerConfig config;
  
  /// Current server state
  ServerState _serverState = ServerState.stopped;
  
  /// Stream controller for server state changes
  final _stateController = StreamController<ServerState>.broadcast();
  
  /// Stream controller for error events
  final _errorController = StreamController<McpError>.broadcast();
  
  /// Transport instance
  ServerTransport? _transport;

  /// Set the transport to use for server
  void setTransport(ServerTransport transport) {
    _transport = transport;
  }

  /// Get current transport
  ServerTransport? getTransport() {
    return _transport;
  }

  /// Whether this server has been disposed
  bool _isDisposed = false;
  
  /// Resource statistics for the server
  ServerResourceStats _resourceStats = ServerResourceStats();
  
  /// Timer for resource stats updates
  Timer? _statsTimer;
  
  /// Create a new Flutter MCP server
  FlutterMcpServer({
    String? id,
    required String name,
    required String version,
    ServerCapabilities? capabilities,
    FlutterMcpServerConfig? config,
  }) : 
    id = id ?? const Uuid().v4(),
    _server = Server(
      name: name,
      version: version,
      capabilities: capabilities ?? const ServerCapabilities(
        tools: true,
        toolsListChanged: true,
        resources: true,
        resourcesListChanged: true,
        prompts: true,
        promptsListChanged: true,
      ),
    ),
    config = config ?? FlutterMcpServerConfig(),
    super() {
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Start resource stats timer if enabled
    if (this.config.monitorResourceUsage) {
      _startResourceMonitoring();
    }
  }
  
  /// Factory method to create a new server instance
  static Future<FlutterMcpServer> create({
    String? id,
    required String name,
    required String version,
    ServerCapabilities? capabilities,
    FlutterMcpServerConfig? config,
  }) async {
    // Create server instance
    final server = FlutterMcpServer(
      id: id,
      name: name,
      version: version, 
      capabilities: capabilities,
      config: config,
    );
    
    return server;
  }
  
  /// Get the underlying MCP server
  Server get mcpServer => _server;
  
  /// Get current server state
  ServerState get serverState => _serverState;
  
  /// Stream of server state changes
  Stream<ServerState> get stateStream => _stateController.stream;
  
  /// Stream of error events
  Stream<McpError> get errorStream => _errorController.stream;
  
  /// Whether the server is currently running
  bool get isRunning => _serverState == ServerState.running;
  
  /// Get resource statistics
  ServerResourceStats get resourceStats => _resourceStats;
  
  /// Start the server with the provided transport
  Future<void> start(ServerTransport transport) async {
    if (_isDisposed) {
      throw StateError('Server has been disposed');
    }
    
    if (_serverState == ServerState.starting) {
      throw StateError('Server is already starting');
    }
    
    if (_serverState == ServerState.running) {
      throw StateError('Server is already running');
    }
    
    // Store transport for later use
    _transport = transport;
    
    // Update state
    _setServerState(ServerState.starting);
    
    try {
      // Connect to transport
      _server.connect(transport);
      
      // Update state
      _setServerState(ServerState.running);
      
      // Send log message
      _server.sendLog(McpLogLevel.info, 'Server started');
      
    } catch (e) {
      // Update state
      _setServerState(ServerState.error);
      
      // Add error to error stream
      if (e is McpError) {
        _errorController.add(e);
      } else {
        _errorController.add(McpError(e.toString()));
      }
      
      rethrow;
    }
  }
  
  /// Stop the server
  Future<void> stop() async {
    if (_isDisposed) {
      return;
    }
    
    if (_serverState == ServerState.stopped) {
      return;
    }
    
    // Send log message
    if (_serverState == ServerState.running) {
      _server.sendLog(McpLogLevel.info, 'Server stopping');
    }
    
    // Disconnect from transport
    _server.disconnect();
    
    // Update state
    _setServerState(ServerState.stopped);
  }
  
  /// Add a tool to the server
  void addTool({
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
    required ToolHandler handler,
  }) {
    _server.addTool(
      name: name,
      description: description,
      inputSchema: inputSchema,
      handler: handler,
    );
  }
  
  /// Remove a tool from the server
  void removeTool(String name) {
    _server.removeTool(name);
  }
  
  /// Add a resource to the server
  void addResource({
    required String uri,
    required String name,
    required String description,
    required String mimeType,
    Map<String, dynamic>? uriTemplate,
    required ResourceHandler handler,
  }) {
    _server.addResource(
      uri: uri,
      name: name, 
      description: description,
      mimeType: mimeType,
      uriTemplate: uriTemplate,
      handler: handler,
    );
  }
  
  /// Remove a resource from the server
  void removeResource(String uri) {
    _server.removeResource(uri);
  }
  
  /// Add a prompt to the server
  void addPrompt({
    required String name,
    required String description,
    required List<PromptArgument> arguments,
    required PromptHandler handler,
  }) {
    _server.addPrompt(
      name: name,
      description: description,
      arguments: arguments,
      handler: handler,
    );
  }
  
  /// Remove a prompt from the server
  void removePrompt(String name) {
    _server.removePrompt(name);
  }
  
  /// Send a log message
  void sendLog(McpLogLevel level, String message, {String? logger, Map<String, dynamic>? data}) {
    if (_serverState == ServerState.running) {
      _server.sendLog(level, message, logger: logger, data: data);
    }
  }
  
  /// Handle lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only handle if server is running and not disposed
    if (_isDisposed || _serverState != ServerState.running) {
      return;
    }
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Resume server if it was paused
        if (_serverState == ServerState.paused) {
          _resumeServer();
        }
        
        // Adjust resource usage
        adjustResourceUsage(AppResourceMode.full);
        break;
      
      case AppLifecycleState.inactive:
        // Reduce resource usage
        adjustResourceUsage(AppResourceMode.reduced);
        break;
      
      case AppLifecycleState.paused:
        // Pause or maintain server based on config
        if (config.runInBackground) {
          // Just reduce resource usage
          adjustResourceUsage(AppResourceMode.minimal);
        } else {
          // Pause server
          _pauseServer();
        }
        break;
      
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Further reduce resource usage or stop server based on config
        if (config.runInBackground) {
          adjustResourceUsage(AppResourceMode.suspended);
        } else {
          stop();
        }
        break;
    }
  }
  
  /// Adjust resource usage based on app state
  void adjustResourceUsage(AppResourceMode mode) {
    // This can be used to optimize resource usage based on app state
    // For now, just log the mode change
    if (kDebugMode) {
      print('MCP Server adjusting resource usage to: $mode');
    }
    
    if (_serverState == ServerState.running) {
      _server.sendLog(
        McpLogLevel.debug,
        'Server resource usage adjusted',
        data: {'mode': mode.toString()},
      );
    }
  }
  
  /// Start resource usage monitoring
  void _startResourceMonitoring() {
    // Monitor resource usage periodically
    _statsTimer = Timer.periodic(Duration(seconds: config.resourceStatsUpdateIntervalSeconds), (_) {
      _updateResourceStats();
    });
  }
  
  /// Update resource usage statistics
  void _updateResourceStats() {
    // In a real implementation, we would measure actual resource usage
    // For now, we'll use dummy values
    if (_serverState == ServerState.running) {
      setState(() {
        _resourceStats = ServerResourceStats(
          cpuUsage: 5.0, // Example value
          memoryUsageMB: 25.0, // Example value
          activeConnections: 1, // Example value
          requestsProcessed: _resourceStats.requestsProcessed + 1, // Example value
          errorsCount: _resourceStats.errorsCount, // Example value
        );
      });
    }
  }
  
  /// Clean up resources
  void dispose() {
    if (_isDisposed) {
      return;
    }
    
    // Mark as disposed
    _isDisposed = true;
    
    // Stop resource monitoring
    _statsTimer?.cancel();
    
    // Stop server if running
    if (_serverState != ServerState.stopped) {
      _server.disconnect();
    }
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Close stream controllers
    _stateController.close();
    _errorController.close();
  }
  
  /// Set server state and notify listeners
  void _setServerState(ServerState state) {
    if (_serverState != state) {
      _serverState = state;
      _stateController.add(state);
    }
  }
  
  /// Pause server (when app goes to background)
  void _pauseServer() {
    if (_serverState == ServerState.running) {
      _setServerState(ServerState.paused);
      _server.sendLog(McpLogLevel.info, 'Server paused');
    }
  }
  
  /// Resume server (when app comes to foreground)
  void _resumeServer() {
    if (_serverState == ServerState.paused) {
      _setServerState(ServerState.running);
      _server.sendLog(McpLogLevel.info, 'Server resumed');
    }
  }
  
  /// Helper to trigger setState from external calls if available
  void setState(VoidCallback fn) {
    fn();
  }
}
