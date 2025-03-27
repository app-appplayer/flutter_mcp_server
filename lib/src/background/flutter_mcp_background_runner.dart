import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart';
import 'package:uuid/uuid.dart';
/// Import for isolate entry point
import 'dart:isolate' show SendPort;

/// Status of a background task
enum TaskStatus {
  /// Task is queued but not started
  queued,
  
  /// Task is currently running
  running,
  
  /// Task has completed successfully
  completed,
  
  /// Task has failed
  failed,
  
  /// Task has been cancelled
  cancelled
}

/// Resource limits for background execution
class ResourceLimits {
  /// Maximum CPU usage percentage
  final double maxCpuUsage;
  
  /// Maximum memory usage in MB
  final double maxMemoryUsageMB;
  
  /// Maximum execution time
  final Duration maxExecutionTime;
  
  /// Maximum network usage in MB
  final double maxNetworkUsageMB;
  
  /// Create resource limits
  const ResourceLimits({
    this.maxCpuUsage = 50.0,
    this.maxMemoryUsageMB = 100.0,
    this.maxExecutionTime = const Duration(minutes: 5),
    this.maxNetworkUsageMB = 10.0,
  });
}

/// Task information
class _TaskInfo {
  /// Unique ID for the task
  final String id;
  
  /// Name of the tool to execute
  final String toolName;
  
  /// Arguments for the tool
  final Map<String, dynamic> arguments;
  
  /// Whether networking is allowed
  final bool allowNetworking;
  
  /// Current status
  TaskStatus status;
  
  /// Error message if failed
  String? error;
  
  /// Result data
  Map<String, dynamic>? result;
  
  /// Stream controller for status updates
  final StreamController<TaskStatus> statusController;
  
  /// Create a task
  _TaskInfo({
    required this.id,
    required this.toolName,
    required this.arguments,
    required this.allowNetworking,
  }) : 
    status = TaskStatus.queued,
    statusController = StreamController<TaskStatus>.broadcast();
  
  /// Update the status
  void updateStatus(TaskStatus newStatus) {
    status = newStatus;
    statusController.add(newStatus);
  }
  
  /// Set error information
  void setError(String errorMessage) {
    error = errorMessage;
    updateStatus(TaskStatus.failed);
  }
  
  /// Set result data
  void setResult(Map<String, dynamic> resultData) {
    result = resultData;
    updateStatus(TaskStatus.completed);
  }
  
  /// Cancel the task
  void cancel() {
    updateStatus(TaskStatus.cancelled);
  }
  
  /// Close resources
  void dispose() {
    statusController.close();
  }
}

/// Runner for background MCP tool execution
class FlutterMcpBackgroundRunner {
  static final FlutterMcpBackgroundRunner _instance = FlutterMcpBackgroundRunner._();
  
  /// Get singleton instance
  static FlutterMcpBackgroundRunner get instance => _instance;
  
  /// Background service instance
  final _backgroundService = FlutterMcpBackgroundService();
  
  /// Queue of pending tasks
  final _taskQueue = Queue<_TaskInfo>();
  
  /// Map of tasks by ID
  final _tasks = <String, _TaskInfo>{};
  
  /// Whether the runner is currently processing tasks
  bool _isProcessing = false;
  
  /// Resource limits
  //ResourceLimits _resourceLimits = const ResourceLimits();
  
  /// Background isolate for processing
  FlutterMcpBackgroundIsolate? _isolate;
  
  /// Private constructor
  FlutterMcpBackgroundRunner._() {
    _initialize();
  }
  
  /// Initialize the runner
  Future<void> _initialize() async {
    // Register with background service
    await _backgroundService.register('mcpBackgroundRunner', _backgroundProcessingTask);
    
    // Create isolate if supported
    if (!kIsWeb) {
      _isolate = FlutterMcpBackgroundIsolate();
      try {
        await _isolate!.spawn(_isolateEntryPoint);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to create background isolate: $e');
        }
        _isolate = null;
      }
    }
  }
  
  /// Background processing task
  Future<void> _backgroundProcessingTask() async {
    if (!_isProcessing && _taskQueue.isNotEmpty) {
      _isProcessing = true;
      
      try {
        await _processNextTask();
      } finally {
        _isProcessing = false;
      }
    }
  }
  
  /// Process next task in queue
  Future<void> _processNextTask() async {
    if (_taskQueue.isEmpty) {
      return;
    }
    
    final task = _taskQueue.removeFirst();
    task.updateStatus(TaskStatus.running);
    
    try {
      // Process task in isolate if available
      if (_isolate != null) {
        // Send task to isolate
        _isolate!.sendMessage({
          'type': 'execute',
          'taskId': task.id,
          'toolName': task.toolName,
          'arguments': task.arguments,
          'allowNetworking': task.allowNetworking,
        });
        
        // Wait for result from isolate
        await for (final result in _isolate!.messages) {
          if (result is Map && result['taskId'] == task.id) {
            if (result['error'] != null) {
              task.setError(result['error']);
            } else {
              task.setResult(result['result']);
            }
            break;
          }
        }
      } else {
        // Process in main isolate (simpler but potentially blocking)
        // This is a placeholder implementation
        await Future.delayed(Duration(seconds: 2));
        task.setResult({'status': 'completed', 'message': 'Task executed'});
      }
    } catch (e) {
      task.setError(e.toString());
    }
    
    // Process next task if any
    if (_taskQueue.isNotEmpty) {
      _backgroundService.schedulePeriodicTask(Duration(seconds: 1), 'mcpBackgroundRunner');
    }
  }
  
  /// Enqueue a tool execution task
  Future<String> enqueueToolExecution(
    String toolName, 
    Map<String, dynamic> arguments, {
    bool allowNetworking = true,
  }) async {
    final taskId = const Uuid().v4();
    
    final task = _TaskInfo(
      id: taskId,
      toolName: toolName,
      arguments: arguments,
      allowNetworking: allowNetworking,
    );
    
    _tasks[taskId] = task;
    _taskQueue.add(task);
    
    // Start processing if not already running
    if (!_isProcessing) {
      _backgroundService.schedulePeriodicTask(Duration(seconds: 1), 'mcpBackgroundRunner');
    }
    
    return taskId;
  }
  
  /// Get task status
  Future<TaskStatus> getTaskStatus(String taskId) async {
    final task = _tasks[taskId];
    
    if (task == null) {
      throw ArgumentError('Unknown task ID: $taskId');
    }
    
    return task.status;
  }
  
  /// Get task status stream
  Stream<TaskStatus> getTaskStatusStream(String taskId) {
    final task = _tasks[taskId];
    
    if (task == null) {
      throw ArgumentError('Unknown task ID: $taskId');
    }
    
    return task.statusController.stream;
  }
  
  /// Get task result
  Future<Map<String, dynamic>?> getTaskResult(String taskId) async {
    final task = _tasks[taskId];
    
    if (task == null) {
      throw ArgumentError('Unknown task ID: $taskId');
    }
    
    if (task.status != TaskStatus.completed) {
      return null;
    }
    
    return task.result;
  }
  
  /// Get task error
  Future<String?> getTaskError(String taskId) async {
    final task = _tasks[taskId];
    
    if (task == null) {
      throw ArgumentError('Unknown task ID: $taskId');
    }
    
    if (task.status != TaskStatus.failed) {
      return null;
    }
    
    return task.error;
  }
  
  /// Cancel a task
  Future<bool> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    
    if (task == null) {
      return false;
    }
    
    if (task.status == TaskStatus.queued) {
      // Remove from queue
      _taskQueue.removeWhere((t) => t.id == taskId);
    }
    
    task.cancel();
    return true;
  }

  /// Set resource limits for task execution
  void setResourceLimits(ResourceLimits limits) {
    //_resourceLimits = limits;

    // Apply the new limits to any running tasks
    if (_isolate != null) {
      _isolate!.sendMessage({
        'type': 'setResourceLimits',
        'limits': {
          'maxCpuUsage': limits.maxCpuUsage,
          'maxMemoryUsageMB': limits.maxMemoryUsageMB,
          'maxExecutionTimeMs': limits.maxExecutionTime.inMilliseconds,
          'maxNetworkUsageMB': limits.maxNetworkUsageMB,
        },
      });
    }
  }

  /// Clean up task resources
  Future<void> cleanupTask(String taskId) async {
    final task = _tasks.remove(taskId);
    
    if (task != null) {
      task.dispose();
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    // Cancel all tasks
    for (final task in _tasks.values) {
      task.cancel();
      task.dispose();
    }
    
    _tasks.clear();
    _taskQueue.clear();
    
    // Kill isolate
    _isolate?.kill();
    
    // Stop background service
    await _backgroundService.stopService();
  }
}

/// Isolate entry point for background processing
void _isolateEntryPoint(dynamic message, SendPort sendPort) {
  // This would contain actual tool execution logic
  // For now, we'll just simulate execution with a delay
  
  if (message is Map && message['type'] == 'execute') {
    final taskId = message['taskId'];
    final toolName = message['toolName'];
    final arguments = message['arguments'];
    
    // Simulate processing
    Future.delayed(Duration(seconds: 2), () {
      // Send result back to main isolate
      sendPort.send({
        'taskId': taskId,
        'result': {
          'toolName': toolName,
          'processedArguments': arguments,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    });
  }
}


