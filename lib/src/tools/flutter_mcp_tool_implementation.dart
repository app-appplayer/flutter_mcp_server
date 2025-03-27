import 'dart:async';
import 'package:mcp_server/mcp_server.dart';

/// Abstract base class for implementing MCP tools
abstract class FlutterMcpToolImplementation {
  /// Tool name
  String get name;
  
  /// Tool description
  String? get description;
  
  /// Tool input schema
  Map<String, dynamic> get inputSchema;
  
  /// Execute the tool with the provided arguments
  Future<CallToolResult> execute(Map<String, dynamic> arguments);
  
  /// Whether the tool can run in background mode
  bool get canRunInBackground => false;
  
  /// Convert to a handler function
  ToolHandler toHandler() {
    return (arguments) async {
      return await execute(arguments);
    };
  }
  
  /// Register this tool with a server
  void registerWith(Server server) {
    server.addTool(
      name: name,
      description: description ?? '',
      inputSchema: inputSchema,
      handler: toHandler(),
    );
  }
}

/// Base class for simple tools that return text
abstract class SimpleTextToolImplementation extends FlutterMcpToolImplementation {
  @override
  Future<CallToolResult> execute(Map<String, dynamic> arguments) async {
    try {
      final text = await executeText(arguments);
      return CallToolResult(
        [TextContent(text: text)],
      );
    } catch (e) {
      return CallToolResult(
        [TextContent(text: 'Error: $e')],
        isError: true,
      );
    }
  }
  
  /// Execute the tool and return a text result
  Future<String> executeText(Map<String, dynamic> arguments);
}

/// Base class for tools that may return multiple content items
abstract class MultiContentToolImplementation extends FlutterMcpToolImplementation {
  @override
  Future<CallToolResult> execute(Map<String, dynamic> arguments) async {
    try {
      final contents = await executeWithContent(arguments);
      return CallToolResult(contents);
    } catch (e) {
      return CallToolResult(
        [TextContent(text: 'Error: $e')],
        isError: true,
      );
    }
  }
  
  /// Execute the tool and return multiple content items
  Future<List<Content>> executeWithContent(Map<String, dynamic> arguments);
}

/// Base class for tools that stream results
abstract class StreamingToolImplementation extends FlutterMcpToolImplementation {
  @override
  Future<CallToolResult> execute(Map<String, dynamic> arguments) async {
    // Initial result to start streaming
    return CallToolResult(
      [TextContent(text: 'Starting operation...')],
      isStreaming: true,
    );
  }
  
  /// Get stream of content updates
  Stream<Content> getContentStream(Map<String, dynamic> arguments);
}

/// Base class for long-running background tools
abstract class BackgroundToolImplementation extends FlutterMcpToolImplementation {
  /// Task ID for this operation
  final String taskId;
  
  /// Create a background tool
  BackgroundToolImplementation(this.taskId);
  
  @override
  bool get canRunInBackground => true;
  
  @override
  Future<CallToolResult> execute(Map<String, dynamic> arguments) async {
    // Start background execution
    startBackgroundExecution(arguments);
    
    // Return initial result
    return CallToolResult(
      [TextContent(text: 'Task started with ID: $taskId')],
    );
  }
  
  /// Start background execution of the tool
  Future<void> startBackgroundExecution(Map<String, dynamic> arguments);
  
  /// Get current status of the background task
  Future<String> getTaskStatus();
  
  /// Cancel the background task
  Future<void> cancelTask();
}

/// Factory for creating common tool implementations
class FlutterMcpToolFactory {
  /// Create a calculator tool
  static FlutterMcpToolImplementation createCalculatorTool() {
    return _CalculatorTool();
  }
  
  /// Create a word counter tool
  static FlutterMcpToolImplementation createWordCounterTool() {
    return _WordCounterTool();
  }
  
  /// Create a date/time tool
  static FlutterMcpToolImplementation createDateTimeTool() {
    return _DateTimeTool();
  }
}

/// Simple calculator tool implementation
class _CalculatorTool extends SimpleTextToolImplementation {
  @override
  String get name => 'calculator';
  
  @override
  String get description => 'Perform basic arithmetic calculations';
  
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'operation': {
        'type': 'string',
        'enum': ['add', 'subtract', 'multiply', 'divide'],
        'description': 'The operation to perform',
      },
      'a': {
        'type': 'number',
        'description': 'First operand',
      },
      'b': {
        'type': 'number',
        'description': 'Second operand',
      },
    },
    'required': ['operation', 'a', 'b'],
  };
  
  @override
  Future<String> executeText(Map<String, dynamic> arguments) async {
    final operation = arguments['operation'] as String;
    final a = arguments['a'] as num;
    final b = arguments['b'] as num;
    
    switch (operation) {
      case 'add':
        return (a + b).toString();
      case 'subtract':
        return (a - b).toString();
      case 'multiply':
        return (a * b).toString();
      case 'divide':
        if (b == 0) {
          throw ArgumentError('Division by zero');
        }
        return (a / b).toString();
      default:
        throw ArgumentError('Unknown operation: $operation');
    }
  }
}

/// Word counter tool implementation
class _WordCounterTool extends SimpleTextToolImplementation {
  @override
  String get name => 'word_counter';
  
  @override
  String get description => 'Count words, characters, and sentences in text';
  
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'text': {
        'type': 'string',
        'description': 'Text to analyze',
      },
      'countSpaces': {
        'type': 'boolean',
        'description': 'Whether to include spaces in character count',
        'default': true,
      },
    },
    'required': ['text'],
  };
  
  @override
  Future<String> executeText(Map<String, dynamic> arguments) async {
    final text = arguments['text'] as String;
    final countSpaces = arguments['countSpaces'] as bool? ?? true;
    
    final words = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final chars = countSpaces ? text.length : text.replaceAll(RegExp(r'\s'), '').length;
    final sentences = RegExp(r'[.!?]+').allMatches(text).length;
    
    return '''
Words: $words
Characters: $chars${countSpaces ? ' (including spaces)' : ' (excluding spaces)'}
Sentences: $sentences
''';
  }
}

/// Date and time tool implementation
class _DateTimeTool extends SimpleTextToolImplementation {
  @override
  String get name => 'date_time';
  
  @override
  String get description => 'Get current date and time information';
  
  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'format': {
        'type': 'string',
        'description': 'Output format (full, date, time)',
        'enum': ['full', 'date', 'time'],
        'default': 'full',
      },
      'timezone': {
        'type': 'string',
        'description': 'Timezone (UTC, local)',
        'enum': ['UTC', 'local'],
        'default': 'local',
      },
    },
  };
  
  @override
  Future<String> executeText(Map<String, dynamic> arguments) async {
    final format = arguments['format'] as String? ?? 'full';
    final timezone = arguments['timezone'] as String? ?? 'local';
    
    final now = timezone == 'UTC' ? DateTime.now().toUtc() : DateTime.now();
    
    switch (format) {
      case 'date':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'time':
        return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      case 'full':
      default:
        return now.toString();
    }
  }
}
