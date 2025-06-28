import 'package:webview_flutter/webview_flutter.dart';
import 'javascript_injection_service.dart';
import 'package:flutter/services.dart';

/// Service for handling communication with the WebView.
class WebViewCommunicationService {
  final WebViewController _controller;

  WebViewCommunicationService(this._controller);

  /// Injects the simplified print function script into the WebView.
  Future<void> injectPrintInterceptor() async {
    try {
      final script = JavaScriptInjectionService.getPrintInterceptorScript();
      await _controller.runJavaScript(script);
      print('✅ Script de función de impresión simplificado inyectado');
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

  /// Tests the print function with sample data.
  Future<void> testPrintFunction() async {
    try {
      final script = JavaScriptInjectionService.getTestPrintFunctionScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🧪 Resultado de prueba de función de impresión: $result');
    } catch (e) {
      print('❌ Error en prueba de función de impresión: $e');
    }
  }

  /// Tests the isFlutterWebView function.
  Future<void> testIsFlutterWebView() async {
    try {
      final script = JavaScriptInjectionService.getTestIsFlutterWebViewScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🔍 Resultado de prueba de isFlutterWebView: $result');
    } catch (e) {
      print('❌ Error en prueba de isFlutterWebView: $e');
    }
  }

  /// Gets usage information for the print function.
  Future<void> getFunctionUsage() async {
    try {
      final script = JavaScriptInjectionService.getFunctionUsageScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('📖 Información de uso de función de impresión: $result');
    } catch (e) {
      print('❌ Error obteniendo información de uso: $e');
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

  /// Sends a test print request to the WebView.
  Future<void> sendTestPrintRequest() async {
    try {
      final script = JavaScriptInjectionService.getTestPrintFunctionScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🧪 Resultado de prueba de función de impresión: $result');
    } catch (e) {
      print('❌ Error en prueba de función de impresión: $e');
    }
  }

  /// Gets the printer IP from the web page input.
  Future<String?> getPrinterIPFromWeb() async {
    try {
      final script = '''
        (function() {
          // Buscar el input con clase printer-ip
          const printerIPInput = document.querySelector('.printer-ip') ||
                                document.querySelector('#printer-ip') ||
                                document.querySelector('input[placeholder*="printer"]') ||
                                document.querySelector('input[placeholder*="impresora"]');
          
          if (printerIPInput && printerIPInput.value) {
            console.log('✅ IP de impresora encontrada en web:', printerIPInput.value);
            return printerIPInput.value.trim();
          } else {
            console.log('⚠️ No se encontró IP de impresora en la web, usando IP por defecto');
            return '192.168.1.13'; // IP por defecto
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('📡 IP de impresora obtenida desde web: $result');
      return result.toString();
    } catch (e) {
      print('❌ Error obteniendo IP de impresora desde web: $e');
      return '192.168.1.13'; // IP por defecto en caso de error
    }
  }

  /// Sends a test invoice print request to the WebView.
  Future<void> sendTestInvoiceRequest() async {
    try {
      final script = JavaScriptInjectionService.getTestInvoiceScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('🧾 Resultado de prueba de factura con QR: $result');
    } catch (e) {
      print('❌ Error en prueba de factura con QR: $e');
    }
  }

  /// Sends a test invoice print request to the WebView using IP from web.
  Future<void> sendTestInvoiceRequestWithWebIP() async {
    try {
      // Obtener IP de la web
      final printerIP = await getPrinterIPFromWeb();

      final script = '''
        (function() {
          console.log('🧪 ENVIANDO SOLICITUD DE IMPRESIÓN DE FACTURA CON IP DE WEB');
          
          const testInvoiceData = {
            content: 'Importadora La Bombonera HE S.A.S\\n' +
                     'Responsable de IVA Regimen Comun\\n' +
                     'NIT: 901.185.393-1\\n' +
                     'Direccion: AUT MEDELLIN BOGOTA KM 46 VDA\\n' +
                     'VARGAS MAS QUINIENTOS METROS PAR EMPRESARIAL G\\n' +
                     '19 BG 8 A\\n' +
                     'Movil: 57+3006389781\\n' +
                     'Email: asistentelabombonera@gmail.com\\n' +
                     'El Santuario-Antioquia\\n' +
                     'Resolucion y/o Autorizacion Dian\\n' +
                     'No.18764082399886 FECHA 2024/10/29 VENCIMIENTO\\n' +
                     '2026/10/29 NUMERACION DEL No. FEIB-5001 AL\\n' +
                     'FEIB-10000\\n' +
                     '------------------------------------------\\n' +
                     'FACTURA ELECTRONICA\\n DE VENTA #:FEIB-5390\\n' +
                     'FECHA:                     2025-06-18 14:26:09\\n' +
                     '------------------------------------------\\n' +
                     'Articulo          Can  Valor       Total\\n' +
                     '-JMG-1265-KIT      24   \$1.050      \$25.200\\n' +
                     ' MANICURE BX240 unidades\\n' +
                     '-JMG64-167-REJILLA 48   \$160,21     \$7.690\\n' +
                     ' LAVA PLATOS BX1200 unidades\\n' +
                     '                                    ----------\\n' +
                     '------------------------------------------\\n' +
                     'CANT.ART:                                   72\\n' +
                     'SUBTOTAL:                              \$32.890\\n' +
                     'TOTAL:                                 \$32.890\\n' +
                     'Nombre:JAB CACHARRERIA S.A.S.\\n' +
                     'NIT:901919284\\n' +
                     'Direccion:CRA 16 # 7-31 SEC 2   ADM MARIA\\n' +
                     'PATRICIA\\n' +
                     'Telefono:3142324624\\n' +
                     'Movil:3192324624\\n' +
                     'Ciudad:PENOL\\n' +
                     'Barrio/Zona:MEGA PRECIOS EL PENOL\\n' +
                     '------------------------------------------\\n' +
                     'T.Abono:                                    \$0\\n' +
                     'T.Deuda:                               \$32.890\\n' +
                     'Firma:____________________________\\n' +
                     '                 Medios Pago\\n' +
                     'Fecha Vencimiento                   2025-07-18\\n' +
                     'Atendido por:                ORFANERY GRAJALES\\n' +
                     'Vendedor:        JOHAN STIVEN HERNANDEZ ALZATE\\n' +
                     'MENOS 5%   20 DIAS      FLETE -50-50\\n' +
                     'Los productos sin IVA en esta factura son\\n' +
                     'BIENES EXENTOS - Decreto 417 del 17 de marzo\\n' +
                     'de 2020 - Decreto 551 de 15 de abril de 2020.\\n' +
                     'Favor Consignar en la FIDUCUENTA BANCOLOMBIA\\n' +
                     'No. 031000003647 a nombre de IMPORTADORA LA\\n' +
                     'BOMBONERA HE SAS NIT 901185393-1\\n' +
                     'Autorizo expresamente a IMPORTADORA LA\\n' +
                     'BOMBONERA HE SAS Y / O a su representante\\n' +
                     'legal, para ser consultado(a) y verificado(a)\\n' +
                     'con terceras personas incluyendo la Base de\\n' +
                     'datos y para que el caso de incumplimiento de\\n' +
                     'las obligaciones, sea reportado a las bases de\\n' +
                     'datos de DATACREDITO o cualquier otro.\\n' +
                     'Sus datos seran tratados y administrados segun\\n' +
                     'la ley 1581 del 2012 ley de proteccion de\\n' +
                     'datos.\\n' +
                     'El no pago oportuno causara intereses de mora\\n' +
                     'iguales a la tasa maxima legal.\\n' +
                     'Esta factura de venta se asimila en todos sus\\n' +
                     'efectos a una letra de cambio, art. 774 del\\n' +
                     'Codigo de Comercio.\\n' +
                     '****GRACIAS POR SU VISITA****\\n' +
                     '          Proceso de validacion Dian\\n' +
                     '   Ver Factura Electronica y Bonos Emitidos\\n' +
                     '<imagen_grande>QR_CODE_PLACEHOLDER</imagen_grande>',
            title: 'Factura Electronica\\n' +'de Venta #FEIB-5390',
            printers: [
              { ip: '$printerIP', copies: 1 }
            ]
          };
          
          console.log('📋 Datos de factura con IP de web:', testInvoiceData);
          
          if (typeof callDirectPrint === 'function') {
            callDirectPrint(testInvoiceData);
            return 'Solicitud de impresion de factura con IP de web enviada';
          } else {
            return 'Error: Funcion callDirectPrint no disponible';
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('🧪 Resultado de solicitud de factura con IP de web: $result');
    } catch (e) {
      print('❌ Error enviando solicitud de factura con IP de web: $e');
    }
  }

  /// Tests invoice printing with a smaller QR to avoid base64 size issues.
  Future<void> testInvoiceWithSmallQr() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        JavaScriptInjectionService.getTestInvoiceScript(),
      );
      print('🧾 Resultado de prueba de factura: $result');
    } catch (e) {
      print('❌ Error al probar factura con QR pequeño: $e');
    }
  }

  /// Procesa texto desde textarea y lo convierte al formato de impresión.
  /// Detecta automáticamente si es una factura y aplica el formato correspondiente.
  Future<void> processTextareaContent() async {
    try {
      print('📝 Procesando contenido del textarea...');

      final script = '''
        (function() {
          console.log('🔍 Buscando textarea en la página...');
          
          // Buscar textarea por diferentes selectores
          const textarea = document.querySelector('textarea') ||
                          document.querySelector('#content') ||
                          document.querySelector('.content') ||
                          document.querySelector('[name="content"]') ||
                          document.querySelector('[placeholder*="factura"]') ||
                          document.querySelector('[placeholder*="contenido"]');
          
          if (!textarea) {
            console.log('❌ No se encontró textarea en la página');
            return {
              success: false,
              error: 'No se encontró textarea en la página'
            };
          }
          
          const content = textarea.value.trim();
          if (!content) {
            console.log('❌ El textarea está vacío');
            return {
              success: false,
              error: 'El textarea está vacío'
            };
          }
          
          console.log('✅ Contenido encontrado en textarea:', content.length + ' caracteres');
          
          // Detectar si es una factura
          const isInvoice = content.includes('FACTURA') ||
                           content.includes('NIT:') ||
                           content.includes('TOTAL:') ||
                           content.includes('SUBTOTAL:') ||
                           content.includes('Cliente:') ||
                           content.includes('Fecha:');
          
          // Extraer título de la primera línea
          const lines = content.split('\\n');
          let title = 'Documento';
          for (const line of lines) {
            if (line.trim() && !line.trim().startsWith('<')) {
              title = line.trim();
              break;
            }
          }
          
          // Obtener IP de impresora
          const printerIP = document.querySelector('.printer-ip')?.value ||
                           document.querySelector('#printer-ip')?.value ||
                           '192.168.1.13';
          
          console.log('📋 Información extraída:');
          console.log('   - Título:', title);
          console.log('   - Es factura:', isInvoice);
          console.log('   - IP impresora:', printerIP);
          
          return {
            success: true,
            content: content,
            title: title,
            isInvoice: isInvoice,
            printerIP: printerIP,
            contentLength: content.length
          };
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('📝 Resultado de procesamiento de textarea: $result');

      if (result != null &&
          result is Map<String, dynamic> &&
          result['success'] == true) {
        // Procesar el contenido y enviarlo para impresión
        await _sendProcessedContentToPrint(result);
      } else {
        final error =
            result is Map<String, dynamic>
                ? result['error']
                : 'Error desconocido';
        print('❌ Error procesando textarea: $error');
      }
    } catch (e) {
      print('❌ Error al procesar contenido del textarea: $e');
    }
  }

  /// Activa el procesamiento automático de textarea.
  /// Crea un botón flotante y detecta cambios automáticamente.
  Future<void> activateTextareaAutoProcessing() async {
    try {
      print('🔧 Activando procesamiento automático de textarea...');

      final script =
          JavaScriptInjectionService.getTextareaAutoProcessingScript();
      final result = await _controller.runJavaScriptReturningResult(script);
      print('✅ Procesamiento automático de textarea activado: $result');
    } catch (e) {
      print('❌ Error activando procesamiento automático de textarea: $e');
    }
  }

  /// Envía el contenido procesado para impresión.
  Future<void> _sendProcessedContentToPrint(Map<String, dynamic> data) async {
    try {
      final content = data['content'] as String;
      final title = data['title'] as String;
      final isInvoice = data['isInvoice'] as bool;
      final printerIP = data['printerIP'] as String;

      print('🖨️ Enviando contenido procesado para impresión:');
      print('   - Título: $title');
      print('   - Tipo: ${isInvoice ? 'Factura' : 'Documento'}');
      print('   - IP: $printerIP');
      print('   - Contenido: ${content.length} caracteres');

      final script = '''
        (function() {
          console.log('🖨️ Enviando contenido procesado para impresión...');
          
          const printData = {
            printers: [
              {
                ip: '${printerIP}',
                copies: 1,
                content: `${content.replaceAll('`', '\\`').replaceAll('\$', '\\\$')}`,
                title: '${title.replaceAll("'", "\\'")}'
              }
            ]
          };
          
          console.log('📋 Datos de impresión:', printData);
          
          if (typeof callDirectPrint === 'function') {
            callDirectPrint(printData);
            return 'Contenido enviado para impresión exitosamente';
          } else {
            return 'Error: Función callDirectPrint no disponible';
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('✅ Resultado de envío para impresión: $result');
    } catch (e) {
      print('❌ Error enviando contenido procesado para impresión: $e');
    }
  }

  /// Lee el archivo content.txt y envía la factura para impresión.
  Future<void> sendInvoiceFromFile() async {
    try {
      print('📄 Leyendo archivo content.txt...');

      // Leer el archivo content.txt
      final content = await rootBundle.loadString('assets/content.txt');
      print('✅ Archivo leído correctamente (${content.length} caracteres)');

      // Obtener IP de la web
      final printerIP = await getPrinterIPFromWeb();

      // Extraer el título de la factura (primera línea sin etiquetas)
      final lines = content.split('\n');
      String title = 'Factura Electrónica';
      for (final line in lines) {
        if (line.trim().isNotEmpty && !line.trim().startsWith('<')) {
          title = line.trim();
          break;
        }
      }

      // Crear el script para enviar la factura desde el archivo
      final script = '''
        (function() {
          console.log('📄 ENVIANDO FACTURA DESDE ARCHIVO CONTENT.TXT');
          
          const invoiceData = {
            content: `${content.replaceAll('`', '\\`').replaceAll('\$', '\\\$')}`,
            title: '$title',
            printers: [
              { ip: '$printerIP', copies: 1 }
            ]
          };
          
          console.log('📋 Datos de factura desde archivo:', invoiceData);
          
          if (typeof callDirectPrint === 'function') {
            callDirectPrint(invoiceData);
            return 'Factura desde archivo enviada exitosamente';
          } else {
            return 'Error: Función callDirectPrint no disponible';
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('🧾 Resultado de factura desde archivo: $result');
    } catch (e) {
      print('❌ Error al leer archivo y enviar factura: $e');
    }
  }
}
