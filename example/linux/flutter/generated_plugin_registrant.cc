//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_mcp_common/flutter_mcp_common_plugin.h>
#include <flutter_mcp_server/flutter_mcp_server_plugin.h>
#include <flutter_secure_storage_linux/flutter_secure_storage_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_mcp_common_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterMcpCommonPlugin");
  flutter_mcp_common_plugin_register_with_registrar(flutter_mcp_common_registrar);
  g_autoptr(FlPluginRegistrar) flutter_mcp_server_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterMcpServerPlugin");
  flutter_mcp_server_plugin_register_with_registrar(flutter_mcp_server_registrar);
  g_autoptr(FlPluginRegistrar) flutter_secure_storage_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterSecureStorageLinuxPlugin");
  flutter_secure_storage_linux_plugin_register_with_registrar(flutter_secure_storage_linux_registrar);
}
