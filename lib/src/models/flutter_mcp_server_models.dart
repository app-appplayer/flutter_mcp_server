import 'package:mcp_server/mcp_server.dart' as original;

// Original types for convenience
export 'package:mcp_server/mcp_server.dart' show
JsonRpcMessage,
McpLogLevel,
ReadResourceResult,
GetPromptResult,
Message,
Content,
ImageContent,
ResourceContent,
Prompt,
PromptArgument,
ToolHandler,
ResourceHandler,
PromptHandler,
McpError,
ServerCapabilities,
SseServerTransport,
StdioServerTransport;

// 이름을 변경하여 재정의
class ServerTool extends original.Tool {
  ServerTool({
    required super.name,
    required super.description,
    required super.inputSchema,
  });

  // Factory from original
  factory ServerTool.fromOriginal(original.Tool tool) {
    return ServerTool(
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema,
    );
  }
}

class ServerResource extends original.Resource {
  ServerResource({
    required super.uri,
    required super.name,
    required super.description,
    required super.mimeType,
    super.uriTemplate,
  });

  // Factory from original
  factory ServerResource.fromOriginal(original.Resource resource) {
    return ServerResource(
      uri: resource.uri,
      name: resource.name,
      description: resource.description,
      mimeType: resource.mimeType,
      uriTemplate: resource.uriTemplate,
    );
  }
}

class ServerTextContent extends original.TextContent {
  ServerTextContent({required super.text});

  // Factory from original
  factory ServerTextContent.fromOriginal(original.TextContent content) {
    return ServerTextContent(text: content.text);
  }
}

class ServerCallToolResult extends original.CallToolResult {
  ServerCallToolResult(
      super.contents, {
        super.isStreaming,
        super.isError,
      });

  // Factory from original
  factory ServerCallToolResult.fromOriginal(original.CallToolResult result) {
    return ServerCallToolResult(
      result.contents,
      isStreaming: result.isStreaming,
      isError: result.isError,
    );
  }
}

// 충돌되는 타입을 새 이름으로 재정의
class ServerClientCapabilities extends original.ClientCapabilities {
  const ServerClientCapabilities({
    super.roots = false,
    super.rootsListChanged = false,
  });
}
