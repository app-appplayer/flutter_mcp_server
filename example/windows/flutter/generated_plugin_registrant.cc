//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <connectivity_plus/connectivity_plus_windows_plugin.h>
#include <flutter_mcp_common/flutter_mcp_common_plugin_c_api.h>
#include <flutter_mcp_server/flutter_mcp_server_plugin_c_api.h>
#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ConnectivityPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ConnectivityPlusWindowsPlugin"));
  FlutterMcpCommonPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterMcpCommonPluginCApi"));
  FlutterMcpServerPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterMcpServerPluginCApi"));
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
}
