import 'package:webview_flutter/webview_flutter.dart';
import 'javascript_injection_service.dart';

/// Service for handling communication with the WebView.
class WebViewCommunicationService {
  final WebViewController _controller;

  WebViewCommunicationService(this._controller);

  /// Injects the print interceptor script into the WebView.
  Future<void> injectPrintInterceptor() async {
    try {
      final script = JavaScriptInjectionService.getPrintInterceptorScript();
      await _controller.runJavaScript(script);
      print('✅ Script de interceptor de impresión inyectado');
    } catch (e) {
      print('❌ Error inyectando script de impresión: $e');
    }
  }

  /// Notifies the web page about a successful print job.
  Future<void> notifyPrintHistory(String text) async {
    try {
      // First check if the addPrintHistory function exists
      final hasAddPrintHistory = await _checkAddPrintHistoryFunction();

      if (hasAddPrintHistory) {
        // Use the existing function
        final script = JavaScriptInjectionService.getAddPrintHistoryScript(
          text,
        );
        await _controller.runJavaScriptReturningResult(script);
        print('✅ Historial actualizado usando función existente');
      } else {
        // Create history manually
        await _createManualPrintHistory(text);
      }
    } catch (e) {
      print('❌ Error notificando historial a la web: $e');
    }
  }

  /// Checks if the addPrintHistory function exists in the web page.
  Future<bool> _checkAddPrintHistoryFunction() async {
    try {
      final script = JavaScriptInjectionService.getCheckAddPrintHistoryScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      return result == true;
    } catch (e) {
      print('❌ Error verificando función addPrintHistory: $e');
      return false;
    }
  }

  /// Creates print history manually in the web page.
  Future<void> _createManualPrintHistory(String text) async {
    try {
      final script =
          JavaScriptInjectionService.getCreateManualPrintHistoryScript(text);
      await _controller.runJavaScript(script);
      print('✅ Historial creado manualmente');
    } catch (e) {
      print('❌ Error creando historial manualmente: $e');
    }
  }

  /// Clears the textarea in the web page.
  Future<void> clearTextarea() async {
    try {
      final script = JavaScriptInjectionService.getClearTextareaScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      if (result == true) {
        print('✅ Textarea limpiado exitosamente');
      } else {
        print('⚠️ No se encontró textarea para limpiar');
      }
    } catch (e) {
      print('❌ Error al limpiar el textarea: $e');
    }
  }

  /// Executes custom JavaScript in the WebView.
  Future<dynamic> executeJavaScript(String script) async {
    try {
      return await _controller.runJavaScriptReturningResult(script);
    } catch (e) {
      print('❌ Error ejecutando JavaScript: $e');
      return null;
    }
  }

  /// Gets the current URL of the WebView.
  Future<String?> getCurrentUrl() async {
    try {
      return await _controller.currentUrl();
    } catch (e) {
      print('❌ Error obteniendo URL actual: $e');
      return null;
    }
  }

  /// Runs a diagnostic script to inspect the page structure.
  Future<void> runDiagnostic() async {
    try {
      final script = JavaScriptInjectionService.getDiagnosticScript();
      await _controller.runJavaScript(script);
      print(
        '✅ Diagnóstico de página ejecutado. Revisa la consola del WebView.',
      );
    } catch (e) {
      print('❌ Error ejecutando diagnóstico: $e');
    }
  }

  /// Reloads the WebView.
  Future<void> reload() async {
    try {
      await _controller.reload();
      print('✅ WebView recargado');
    } catch (e) {
      print('❌ Error recargando WebView: $e');
    }
  }

  /// Runs a debug script to check JavaScript injection status.
  Future<void> debugInjection() async {
    try {
      final script = JavaScriptInjectionService.getDebugInjectionScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🔧 Resultado de depuración: $result');
    } catch (e) {
      print('❌ Error en depuración: $e');
    }
  }

  /// Runs a manual test of the print button functionality.
  Future<void> testManualPrint() async {
    try {
      final script = JavaScriptInjectionService.getManualPrintTestScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🧪 Resultado de prueba manual: $result');
    } catch (e) {
      print('❌ Error en prueba manual: $e');
    }
  }

  /// Sends current print configuration to the web page.
  Future<void> sendPrintConfiguration({
    required String codeTable,
    required bool normalizeCharacters,
    required bool fullNormalization,
  }) async {
    try {
      final script = '''
        (function() {
          // Enviar configuración de impresión a la web
          if (typeof window.setPrintConfiguration === 'function') {
            window.setPrintConfiguration({
              codeTable: '$codeTable',
              normalizeCharacters: $normalizeCharacters,
              fullNormalization: $fullNormalization,
              platform: 'flutter',
              timestamp: new Date().toISOString()
            });
            console.log('✅ Configuración de impresión enviada a la web:', {
              codeTable: '$codeTable',
              normalizeCharacters: $normalizeCharacters,
              fullNormalization: $fullNormalization
            });
            return true;
          } else {
            // Si no existe la función, crear variables globales
            window.flutterPrintConfig = {
              codeTable: '$codeTable',
              normalizeCharacters: $normalizeCharacters,
              fullNormalization: $fullNormalization,
              platform: 'flutter',
              timestamp: new Date().toISOString()
            };
            console.log('✅ Configuración de impresión guardada en variables globales');
            return true;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('📋 Configuración enviada a la web: $result');
    } catch (e) {
      print('❌ Error enviando configuración: $e');
    }
  }

  /// Forces WebView detection for Flutter to enable print button.
  Future<void> forceWebViewDetection() async {
    try {
      final script =
          JavaScriptInjectionService.getForceWebViewDetectionScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🔍 Resultado de forzar detección: $result');
    } catch (e) {
      print('❌ Error forzando detección: $e');
    }
  }
}
