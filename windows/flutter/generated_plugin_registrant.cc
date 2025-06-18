//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <printer_plus/printer_plus_plugin_c_api.h>
#include <printing/printing_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  PrinterPlusPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrinterPlusPluginCApi"));
  PrintingPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrintingPlugin"));
}
