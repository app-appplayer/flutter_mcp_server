library flutter_mcp_server;

// Server implementation
export 'src/server/flutter_mcp_server.dart';
export 'src/server/flutter_mcp_server_config.dart';
export 'src/server/flutter_mcp_server_manager.dart';

// Tool implementation
export 'src/tools/flutter_mcp_tool_implementation.dart';

// Resource implementation
export 'src/resources/flutter_mcp_resource_provider.dart';

// Background execution
export 'src/background/flutter_mcp_background_runner.dart';

// Widgets
export 'src/widgets/flutter_mcp_server_config_widget.dart';
export 'src/widgets/flutter_mcp_server_monitor_widget.dart';

// Re-export MCP server core types for convenience
export 'package:mcp_server/mcp_server.dart' show
Tool,
Resource,
ServerCapabilities,
ClientCapabilities,
McpError,
JsonRpcMessage,
LogLevel,
CallToolResult,
ReadResourceResult,
GetPromptResult,
Message,
Content,
TextContent,
ImageContent,
ResourceContent,
Prompt,
PromptArgument,
ToolHandler,
ResourceHandler,
PromptHandler;