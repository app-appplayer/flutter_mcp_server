import 'dart:async';
import 'package:flutter/material.dart';
import '../server/flutter_mcp_server.dart';

/// Style configuration for the monitor widget
class FlutterMcpServerMonitorStyle {
  /// Color for running state
  final Color runningColor;
  
  /// Color for stopped state
  final Color stoppedColor;
  
  /// Color for starting state
  final Color startingColor;
  
  /// Color for error state
  final Color errorColor;
  
  /// Color for paused state
  final Color pausedColor;
  
  /// Text style for status text
  final TextStyle? textStyle;
  
  /// Icon size
  final double iconSize;
  
  /// Create monitor widget style
  const FlutterMcpServerMonitorStyle({
    this.runningColor = Colors.green,
    this.stoppedColor = Colors.red,
    this.startingColor = Colors.orange,
    this.errorColor = Colors.red,
    this.pausedColor = Colors.grey,
    this.textStyle,
    this.iconSize = 16.0,
  });
}

/// Widget for monitoring MCP server status and performance
class FlutterMcpServerMonitorWidget extends StatefulWidget {
  /// Server to monitor
  final FlutterMcpServer server;
  
  /// Refresh interval for status updates
  final Duration refreshInterval;
  
  /// Style configuration
  final FlutterMcpServerMonitorStyle? style;
  
  /// Whether to show server controls
  final bool showServerControls;
  
  /// Whether to show resource usage stats
  final bool showResourceStats;
  
  /// Create a server monitor widget
  const FlutterMcpServerMonitorWidget({
    Key? key,
    required this.server,
    this.refreshInterval = const Duration(seconds: 1),
    this.style,
    this.showServerControls = true,
    this.showResourceStats = true,
  }) : super(key: key);

  @override
  _FlutterMcpServerMonitorWidgetState createState() => _FlutterMcpServerMonitorWidgetState();
}

class _FlutterMcpServerMonitorWidgetState extends State<FlutterMcpServerMonitorWidget> {
  /// Current server state
  ServerState _serverState = ServerState.stopped;
  
  /// Current resource stats
  ServerResourceStats _resourceStats = ServerResourceStats();
  
  /// Timer for periodic updates
  Timer? _refreshTimer;
  
  /// Subscription to server state changes
  StreamSubscription? _stateSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize state
    _serverState = widget.server.serverState;
    _resourceStats = widget.server.resourceStats;
    
    // Listen for server state changes
    _stateSubscription = widget.server.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _serverState = state;
        });
      }
    });
    
    // Start periodic updates
    _startRefreshTimer();
  }
  
  @override
  void didUpdateWidget(FlutterMcpServerMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.refreshInterval != widget.refreshInterval) {
      // Restart timer with new interval
      _stopRefreshTimer();
      _startRefreshTimer();
    }
    
    if (oldWidget.server != widget.server) {
      // Update subscriptions for new server
      _stateSubscription?.cancel();
      _stateSubscription = widget.server.stateStream.listen((state) {
        if (mounted) {
          setState(() {
            _serverState = state;
          });
        }
      });
      
      // Update current state
      _serverState = widget.server.serverState;
      _resourceStats = widget.server.resourceStats;
    }
  }
  
  @override
  void dispose() {
    _stopRefreshTimer();
    _stateSubscription?.cancel();
    super.dispose();
  }
  
  /// Start periodic refresh timer
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      _updateStats();
    });
  }
  
  /// Stop periodic refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  /// Update resource statistics
  void _updateStats() {
    if (mounted) {
      setState(() {
        _resourceStats = widget.server.resourceStats;
      });
    }
  }
  
  /// Get color for current server state
  Color _getColorForState(FlutterMcpServerMonitorStyle style) {
    switch (_serverState) {
      case ServerState.running:
        return style.runningColor;
      case ServerState.stopped:
        return style.stoppedColor;
      case ServerState.starting:
        return style.startingColor;
      case ServerState.error:
        return style.errorColor;
      case ServerState.paused:
        return style.pausedColor;
    }
  }
  
  /// Get icon for current server state
  IconData _getIconForState() {
    switch (_serverState) {
      case ServerState.running:
        return Icons.play_circle;
      case ServerState.stopped:
        return Icons.stop_circle;
      case ServerState.starting:
        return Icons.sync;
      case ServerState.error:
        return Icons.error;
      case ServerState.paused:
        return Icons.pause_circle;
    }
  }
  
  /// Get text for current server state
  String _getTextForState() {
    switch (_serverState) {
      case ServerState.running:
        return 'Running';
      case ServerState.stopped:
        return 'Stopped';
      case ServerState.starting:
        return 'Starting...';
      case ServerState.error:
        return 'Error';
      case ServerState.paused:
        return 'Paused';
    }
  }
  
  /// Start the server
  Future<void> _startServer() async {
    try {
      final transport = widget.server.getTransport();
      if (transport != null) {
        await widget.server.start(transport);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transport available')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start server: $e')),
      );
    }
  }
  
  /// Stop the server
  Future<void> _stopServer() async {
    try {
      await widget.server.stop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop server: $e')),
      );
    }
  }
  
  /// Build the resource usage section
  Widget _buildResourceUsage() {
    if (!widget.showResourceStats) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Resource Usage',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        
        // CPU usage indicator
        _buildResourceIndicator(
          'CPU',
          _resourceStats.cpuUsage,
          100.0,
          '%',
          Colors.blue,
        ),
        
        // Memory usage indicator
        _buildResourceIndicator(
          'Memory',
          _resourceStats.memoryUsageMB,
          200.0,
          ' MB',
          Colors.green,
        ),
        
        // Connection stats
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active connections:'),
              Text('${_resourceStats.activeConnections}'),
            ],
          ),
        ),
        
        // Request stats
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Requests processed:'),
              Text('${_resourceStats.requestsProcessed}'),
            ],
          ),
        ),
        
        // Error stats
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Errors:'),
              Text('${_resourceStats.errorsCount}'),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build a resource indicator bar
  Widget _buildResourceIndicator(
    String label,
    double value,
    double maxValue,
    String unit,
    Color color,
  ) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${value.toStringAsFixed(1)}$unit'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const FlutterMcpServerMonitorStyle();
    final stateColor = _getColorForState(style);
    final stateIcon = _getIconForState();
    final stateText = _getTextForState();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server information
            Text(
              widget.server.mcpServer.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'v${widget.server.mcpServer.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            
            // Status indicator
            Row(
              children: [
                Icon(
                  stateIcon,
                  color: stateColor,
                  size: style.iconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  stateText,
                  style: style.textStyle?.copyWith(color: stateColor) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                      ),
                ),
              ],
            ),
            
            // Server controls
            if (widget.showServerControls) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_serverState == ServerState.stopped ||
                      _serverState == ServerState.error)
                    ElevatedButton(
                      onPressed: _startServer,
                      child: const Text('Start Server'),
                    ),
                  if (_serverState == ServerState.running ||
                      _serverState == ServerState.paused)
                    ElevatedButton(
                      onPressed: _stopServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Stop Server'),
                    ),
                ],
              ),
            ],
            
            // Resource usage section
            _buildResourceUsage(),
          ],
        ),
      ),
    );
  }
}
