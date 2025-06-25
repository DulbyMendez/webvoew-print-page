/// Service for handling JavaScript injection and WebView communication.
class JavaScriptInjectionService {
  /// Returns the simplified JavaScript code that only handles direct print requests.
  static String getPrintInterceptorScript() {
    return '''
      (function() {
        console.log('🚀 Inicializando sistema de impresión simplificado...');
        
        // --- CONFIGURAR CANAL DE COMUNICACIÓN CON FLUTTER ---
        // Configurar window.NativePrinter como alias del canal DirectPrint
        if (typeof DirectPrint !== 'undefined') {
          window.NativePrinter = {
            postMessage: function(message) {
              console.log('🔄 Redirigiendo mensaje a DirectPrint:', message);
              DirectPrint.postMessage(message);
            }
          };
          console.log('✅ window.NativePrinter configurado como alias de DirectPrint');
        }
        
        // --- FUNCIÓN PRINCIPAL DE IMPRESIÓN ---
        function callDirectPrint() {
          try {
            console.log('🚀 Iniciando proceso de impresión directa...');
            
            // Validar que se proporcionen los datos necesarios
            if (!arguments[0] || typeof arguments[0] !== 'object') {
              console.error('❌ Error: Se requiere un objeto con los datos de impresión');
              alert('Error: Se requiere un objeto con los datos de impresión');
              return;
            }
            
            const printData = arguments[0];
            
            // Validar campos requeridos
            if (!printData.content || typeof printData.content !== 'string') {
              console.error('❌ Error: El campo "content" es requerido y debe ser una cadena');
              alert('Error: El campo "content" es requerido y debe ser una cadena');
              return;
            }
            
            if (!printData.title || typeof printData.title !== 'string') {
              console.error('❌ Error: El campo "title" es requerido y debe ser una cadena');
              alert('Error: El campo "title" es requerido y debe ser una cadena');
              return;
            }
            
            if (!printData.printers || !Array.isArray(printData.printers)) {
              console.error('❌ Error: El campo "printers" es requerido y debe ser un array');
              alert('Error: El campo "printers" es requerido y debe ser un array');
              return;
            }
            
            // Validar cada impresora
            for (let i = 0; i < printData.printers.length; i++) {
              const printer = printData.printers[i];
              if (!printer.ip || typeof printer.ip !== 'string') {
                console.error('❌ Error: Cada impresora debe tener un campo "ip" válido');
                alert('Error: Cada impresora debe tener un campo "ip" válido');
                return;
              }
              if (!printer.copies || typeof printer.copies !== 'number' || printer.copies < 1) {
                console.error('❌ Error: Cada impresora debe tener un campo "copies" válido (número >= 1)');
                alert('Error: Cada impresora debe tener un campo "copies" válido (número >= 1)');
                return;
              }
            }
            
            // Agregar timestamp y URL
            const finalPrintData = {
              content: printData.content.trim(),
              title: printData.title.trim(),
              printers: printData.printers,
              url: window.location.href,
              timestamp: new Date().toISOString()
            };
            
            console.log('➡️ Enviando datos de impresión a Flutter:', finalPrintData);
            
            // Intentar usar window.NativePrinter primero, luego DirectPrint como fallback
            if (window.NativePrinter && window.NativePrinter.postMessage) {
              window.NativePrinter.postMessage(JSON.stringify(finalPrintData));
            } else if (typeof DirectPrint !== 'undefined') {
              DirectPrint.postMessage(JSON.stringify(finalPrintData));
            } else {
              console.error('❌ No se encontró canal de comunicación con Flutter');
              alert('Error: No se puede comunicar con la aplicación Flutter');
            }
            
          } catch (error) {
            console.error('❌ Error al procesar datos de impresión:', error);
            alert('Error al intentar imprimir: ' + error.message);
          }
        }
        
        // --- EXPONER FUNCIÓN GLOBAL ---
        window.callDirectPrint = callDirectPrint;
        
        // --- FUNCIÓN DE CONVENIENCIA PARA LLAMAR DESDE CÓDIGO WEB ---
        window.printToNative = function(content, title, printers) {
          return callDirectPrint({
            content: content,
            title: title,
            printers: printers
          });
        };
        
        console.log('✅ Sistema de impresión simplificado inicializado');
        console.log('📝 Uso: callDirectPrint({content: "texto", title: "título", printers: [{ip: "192.168.1.100", copies: 1}]})');
        console.log('📝 O: printToNative("texto", "título", [{ip: "192.168.1.100", copies: 1}])');
      })();
    ''';
  }

  /// Returns JavaScript code to check if addPrintHistory function exists.
  static String getCheckAddPrintHistoryScript() {
    return '''
      (function() {
        return typeof addPrintHistory === 'function';
      })();
    ''';
  }

  /// Returns JavaScript code to add print history.
  static String getAddPrintHistoryScript(String text) {
    return '''
      (function() {
        try {
          if (typeof addPrintHistory === 'function') {
            addPrintHistory("${text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}");
            console.log('✅ Historial actualizado desde Flutter');
            return true;
          }
          return false;
        } catch (error) {
          console.error('Error actualizando historial:', error);
          return false;
        }
      })();
    ''';
  }

  /// Returns JavaScript code to create manual print history.
  static String getCreateManualPrintHistoryScript(String text) {
    return '''
      (function() {
        try {
          console.log('⚠️ Creando historial manualmente...');
          
          const historyContainer = document.getElementById('printHistory') ||
                                  document.querySelector('.print-history') ||
                                  document.querySelector('[data-print-history]');
          
          if (historyContainer) {
            const timestamp = new Date().toLocaleString();
            const historyItem = document.createElement('div');
            historyItem.className = 'print-item';
            historyItem.innerHTML = 
              '<div class="print-header">' +
                '<span class="print-time">' + timestamp + '</span>' +
                '<span class="print-status success">✅ Exitoso</span>' +
              '</div>' +
              '<div class="print-content">' +
                '<strong>Texto impreso:</strong>' +
                '<div class="print-preview">' +
                "${text.replaceAll('"', '&quot;').replaceAll('\n', '<br>')}" +
                '</div>' +
              '</div>';
            
            historyContainer.insertBefore(historyItem, historyContainer.firstChild);
            console.log('✅ Historial actualizado manualmente');
          } else {
            console.log('⚠️ No se encontró contenedor de historial');
          }
        } catch (error) {
          console.error('Error creando historial manualmente:', error);
        }
      })();
    ''';
  }

  /// Returns JavaScript code to clear textarea.
  static String getClearTextareaScript() {
    return '''
      (function() {
        const textareaSelectors = [
          '#textInput',
          '#content',
          'textarea',
          '.text-input',
          '[data-print-content]'
        ];
        
        for (const selector of textareaSelectors) {
          const textarea = document.querySelector(selector);
          if (textarea) {
            textarea.value = '';
            textarea.dispatchEvent(new Event('input', { bubbles: true }));
            console.log('✅ Textarea limpiado:', selector);
            return true;
          }
        }
        console.log('⚠️ No se encontró textarea para limpiar');
        return false;
      })();
    ''';
  }

  /// Returns JavaScript code to test the print function.
  static String getTestPrintFunctionScript() {
    return '''
      (function() {
        console.log('🧪 PROBANDO FUNCIÓN DE IMPRESIÓN');
        console.log('==================================');
        
        // Verificar si la función está disponible
        if (typeof callDirectPrint === 'function') {
          console.log('✅ callDirectPrint está disponible');
          
          // Datos de prueba
          const testData = {
            content: "Este es un texto de prueba para verificar que la función de impresión funciona correctamente.",
            title: "Prueba de Impresión",
            printers: [
              { ip: "192.168.1.100", copies: 1 },
              { ip: "192.168.1.101", copies: 2 }
            ]
          };
          
          console.log('📋 Datos de prueba:', testData);
          
          // Llamar la función
          try {
            callDirectPrint(testData);
            console.log('✅ Función de impresión llamada exitosamente');
            return 'Función de impresión probada exitosamente';
          } catch (error) {
            console.error('❌ Error al llamar función de impresión:', error);
            return 'Error: ' + error.message;
          }
        } else {
          console.log('❌ callDirectPrint NO está disponible');
          return 'Error: Función callDirectPrint no está disponible';
        }
      })();
    ''';
  }

  /// Returns JavaScript code to get function usage information.
  static String getFunctionUsageScript() {
    return '''
      (function() {
        console.log('📖 INFORMACIÓN DE USO DE LA FUNCIÓN DE IMPRESIÓN');
        console.log('================================================');
        
        const usageInfo = {
          functionName: 'callDirectPrint',
          available: typeof callDirectPrint === 'function',
          alternativeFunction: 'printToNative',
          alternativeAvailable: typeof printToNative === 'function',
          usage: {
            method1: 'callDirectPrint({content: "texto", title: "título", printers: [{ip: "192.168.1.100", copies: 1}]})',
            method2: 'printToNative("texto", "título", [{ip: "192.168.1.100", copies: 1}])',
            method3: 'window.NativePrinter.postMessage(JSON.stringify({content: "texto", title: "título", printers: [{ip: "192.168.1.100", copies: 1}]}))'
          },
          requiredFields: {
            content: 'string - El texto a imprimir',
            title: 'string - El título del documento',
            printers: 'array - Lista de impresoras con ip (string) y copies (number)'
          },
          example: {
            content: "Texto a imprimir",
            title: "Título de impresión", 
            printers: [
              { ip: "192.168.1.100", copies: 2 },
              { ip: "192.168.1.101", copies: 1 }
            ]
          }
        };
        
        console.log('Información de uso:', usageInfo);
        return usageInfo;
      })();
    ''';
  }
}
