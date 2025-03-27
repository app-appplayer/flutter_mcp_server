import 'dart:async';
import 'package:mcp_server/mcp_server.dart';

// Platform import for SystemInfoResourceProvider
import 'dart:io' show Platform;

/// Abstract base class for implementing MCP resource providers
abstract class FlutterMcpResourceProvider {
  /// URI scheme for this resource provider
  String get uriScheme;
  
  /// Provider description
  String? get description;
  
  /// List resources available from this provider
  Future<List<Resource>> listResources(Map<String, dynamic>? params);
  
  /// Get a specific resource content
  Future<ReadResourceResult> getResource(String uri, Map<String, dynamic>? params);
  
  /// Stream of resource change notifications (optional)
  Stream<String>? get resourceChangeStream => null;
  
  /// Convert to a handler function
  ResourceHandler toHandler() {
    return (uri, params) async {
      return await getResource(uri, params);
    };
  }
  
  /// Register this provider with a server for a specific resource
  void registerResourceWith(Server server, Resource resource) {
    server.addResource(
      uri: resource.uri,
      name: resource.name,
      description: resource.description,
      mimeType: resource.mimeType,
      uriTemplate: resource.uriTemplate,
      handler: toHandler(),
    );
  }
  
  /// Register all resources from this provider with a server
  Future<void> registerAllResourcesWith(Server server) async {
    final resources = await listResources(null);
    
    for (final resource in resources) {
      registerResourceWith(server, resource);
    }
  }
}

/// Base class for static text resources
abstract class StaticTextResourceProvider extends FlutterMcpResourceProvider {
  @override
  Future<ReadResourceResult> getResource(String uri, Map<String, dynamic>? params) async {
    final content = await getTextContent(uri, params);
    
    return ReadResourceResult(
      content: content,
      mimeType: 'text/plain',
      contents: [TextContent(text: content)],
    );
  }
  
  /// Get text content for a resource
  Future<String> getTextContent(String uri, Map<String, dynamic>? params);
}

/// Base class for JSON resources
abstract class JsonResourceProvider extends FlutterMcpResourceProvider {
  @override
  Future<ReadResourceResult> getResource(String uri, Map<String, dynamic>? params) async {
    final json = await getJsonContent(uri, params);
    final jsonString = json is String ? json : json.toString();
    
    return ReadResourceResult(
      content: jsonString,
      mimeType: 'application/json',
      contents: [TextContent(text: jsonString)],
    );
  }
  
  /// Get JSON content for a resource
  Future<dynamic> getJsonContent(String uri, Map<String, dynamic>? params);
}

/// Base class for file resources
abstract class FileResourceProvider extends FlutterMcpResourceProvider {
  @override
  Future<ReadResourceResult> getResource(String uri, Map<String, dynamic>? params) async {
    final result = await getFileContent(uri, params);
    
    return ReadResourceResult(
      content: result.content,
      mimeType: result.mimeType,
      contents: [
        TextContent(text: result.content),
      ],
    );
  }
  
  /// Get file content for a resource
  Future<_FileContent> getFileContent(String uri, Map<String, dynamic>? params);
}

/// Helper class for file content results
class _FileContent {
  /// File content as string
  final String content;
  
  /// MIME type of the file
  final String mimeType;
  
  /// Create file content result
  _FileContent({
    required this.content,
    required this.mimeType,
  });
}

/// Base class for image resources
abstract class ImageResourceProvider extends FlutterMcpResourceProvider {
  @override
  Future<ReadResourceResult> getResource(String uri, Map<String, dynamic>? params) async {
    final result = await getImageInfo(uri, params);
    
    return ReadResourceResult(
      content: result.description,
      mimeType: 'text/plain',
      contents: [
        ImageContent(
          url: result.url,
          mimeType: result.mimeType,
        ),
        TextContent(text: result.description),
      ],
    );
  }
  
  /// Get image information for a resource
  Future<_ImageInfo> getImageInfo(String uri, Map<String, dynamic>? params);
}

/// Helper class for image information
class _ImageInfo {
  /// Image URL
  final String url;
  
  /// MIME type of the image
  final String mimeType;
  
  /// Image description
  final String description;
  
  /// Create image information
  _ImageInfo({
    required this.url,
    required this.mimeType,
    required this.description,
  });
}

/// Factory for creating common resource providers
class FlutterMcpResourceProviderFactory {
  /// Create a config resource provider
  static FlutterMcpResourceProvider createConfigProvider(Map<String, dynamic> config) {
    return _ConfigResourceProvider(config);
  }
  
  /// Create a system info resource provider
  static FlutterMcpResourceProvider createSystemInfoProvider() {
    return _SystemInfoResourceProvider();
  }
  
  /// Create a time resource provider
  static FlutterMcpResourceProvider createTimeProvider() {
    return _TimeResourceProvider();
  }
}

/// Config resource provider implementation
class _ConfigResourceProvider extends JsonResourceProvider {
  /// Configuration data
  final Map<String, dynamic> _config;
  
  /// Create a config provider
  _ConfigResourceProvider(this._config);
  
  @override
  String get uriScheme => 'config';
  
  @override
  String get description => 'Application configuration data';
  
  @override
  Future<List<Resource>> listResources(Map<String, dynamic>? params) async {
    return [
      Resource(
        uri: 'config://app',
        name: 'Application Configuration',
        description: 'Current application configuration settings',
        mimeType: 'application/json',
      ),
    ];
  }
  
  @override
  Future<dynamic> getJsonContent(String uri, Map<String, dynamic>? params) async {
    if (uri == 'config://app') {
      return _config;
    }
    
    throw ArgumentError('Unknown config URI: $uri');
  }
}

/// System information resource provider
class _SystemInfoResourceProvider extends JsonResourceProvider {
  @override
  String get uriScheme => 'system';
  
  @override
  String get description => 'System information';
  
  @override
  Future<List<Resource>> listResources(Map<String, dynamic>? params) async {
    return [
      Resource(
        uri: 'system://info',
        name: 'System Information',
        description: 'Current system information',
        mimeType: 'application/json',
      ),
    ];
  }
  
  @override
  Future<dynamic> getJsonContent(String uri, Map<String, dynamic>? params) async {
    if (uri == 'system://info') {
      return {
        'platform': {
          'operatingSystem': Platform.operatingSystem,
          'operatingSystemVersion': Platform.operatingSystemVersion,
          'localHostname': Platform.localHostname,
          'numberOfProcessors': Platform.numberOfProcessors,
        },
        'environment': Platform.environment,
        'executable': Platform.executable,
        'version': Platform.version,
      };
    }
    
    throw ArgumentError('Unknown system URI: $uri');
  }
}

/// Time resource provider implementation
class _TimeResourceProvider extends JsonResourceProvider {
  @override
  String get uriScheme => 'time';
  
  @override
  String get description => 'Date and time information';
  
  @override
  Future<List<Resource>> listResources(Map<String, dynamic>? params) async {
    return [
      Resource(
        uri: 'time://current',
        name: 'Current Time',
        description: 'Current date and time information',
        mimeType: 'application/json',
      ),
      Resource(
        uri: 'time://zones',
        name: 'Time Zones',
        description: 'List of time zones',
        mimeType: 'application/json',
      ),
    ];
  }
  
  @override
  Future<dynamic> getJsonContent(String uri, Map<String, dynamic>? params) async {
    if (uri == 'time://current') {
      final now = DateTime.now();
      final utc = now.toUtc();
      
      return {
        'timestamp': now.millisecondsSinceEpoch,
        'iso8601': now.toIso8601String(),
        'utc': {
          'iso8601': utc.toIso8601String(),
          'hour': utc.hour,
          'minute': utc.minute,
          'second': utc.second,
        },
        'local': {
          'hour': now.hour,
          'minute': now.minute,
          'second': now.second,
        },
        'date': {
          'year': now.year,
          'month': now.month,
          'day': now.day,
          'weekday': now.weekday,
        },
      };
    } else if (uri == 'time://zones') {
      // Return a simple list of common time zones
      return {
        'timeZones': [
          'UTC',
          'America/New_York',
          'America/Chicago',
          'America/Denver',
          'America/Los_Angeles',
          'Europe/London',
          'Europe/Paris',
          'Europe/Berlin',
          'Asia/Tokyo',
          'Asia/Shanghai',
          'Australia/Sydney',
        ],
      };
    }
    
    throw ArgumentError('Unknown time URI: $uri');
  }
}


