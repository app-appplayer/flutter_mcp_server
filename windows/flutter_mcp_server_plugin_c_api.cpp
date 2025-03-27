#include "include/flutter_mcp_server/flutter_mcp_server_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_mcp_server_plugin.h"

void FlutterMcpServerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_mcp_server::FlutterMcpServerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
