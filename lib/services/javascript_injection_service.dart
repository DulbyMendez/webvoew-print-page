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
        
        // --- FUNCIÓN PARA DETECTAR FLUTTER WEBVIEW ---
        function isFlutterWebView() {
          // Verificar si existe el canal de comunicación con Flutter
          const hasDirectPrint = typeof DirectPrint !== 'undefined';
          const hasNativePrinter = typeof window.NativePrinter !== 'undefined';
          
          // Verificar si existe la configuración de Flutter
          const hasFlutterConfig = typeof window.flutterPrintConfig !== 'undefined';
          
          // Verificar si estamos en un WebView (no en navegador normal)
          const isInWebView = window.ReactNativeWebView || 
                             window.webkit && window.webkit.messageHandlers ||
                             window.AndroidInterface ||
                             window.flutter_inappwebview;
          
          // Verificar si las funciones de impresión están disponibles
          const hasPrintFunctions = typeof callDirectPrint === 'function' || 
                                   typeof printToNative === 'function';
          
          const isFlutter = hasDirectPrint || hasNativePrinter || hasFlutterConfig || hasPrintFunctions;
          
          console.log('🔍 Detección de Flutter WebView:', {
            hasDirectPrint,
            hasNativePrinter,
            hasFlutterConfig,
            isInWebView,
            hasPrintFunctions,
            isFlutter
          });
          
          return isFlutter;
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
            
            // Validar que se proporcione el array de impresoras
            if (!printData.printers || !Array.isArray(printData.printers)) {
              console.error('❌ Error: El campo "printers" es requerido y debe ser un array');
              alert('Error: El campo "printers" es requerido y debe ser un array');
              return;
            }
            
            // Validar cada impresora con su contenido específico
            for (let i = 0; i < printData.printers.length; i++) {
              const printer = printData.printers[i];
              
              // Validar IP
              if (!printer.ip || typeof printer.ip !== 'string') {
                console.error('❌ Error: Cada impresora debe tener un campo "ip" válido');
                alert('Error: Cada impresora debe tener un campo "ip" válido');
                return;
              }
              
              // Validar copias
              if (!printer.copies || typeof printer.copies !== 'number' || printer.copies < 1) {
                console.error('❌ Error: Cada impresora debe tener un campo "copies" válido (número >= 1)');
                alert('Error: Cada impresora debe tener un campo "copies" válido (número >= 1)');
                return;
              }
              
              // Validar contenido específico de cada impresora
              if (!printer.content || typeof printer.content !== 'string') {
                console.error('❌ Error: Cada impresora debe tener un campo "content" válido');
                alert('Error: Cada impresora debe tener un campo "content" válido');
                return;
              }
              
              // Validar título específico de cada impresora
              if (!printer.title || typeof printer.title !== 'string') {
                console.error('❌ Error: Cada impresora debe tener un campo "title" válido');
                alert('Error: Cada impresora debe tener un campo "title" válido');
                return;
              }
            }
            
            // Agregar timestamp y URL
            const finalPrintData = {
              printers: printData.printers.map(printer => ({
                ip: printer.ip.trim(),
                copies: printer.copies,
                content: printer.content.trim(),
                title: printer.title.trim()
              })),
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
        
        // --- EXPONER FUNCIONES GLOBALES ---
        window.callDirectPrint = callDirectPrint;
        window.isFlutterWebView = isFlutterWebView;
        
        // --- FUNCIÓN DE CONVENIENCIA PARA LLAMAR DESDE CÓDIGO WEB ---
        window.printToNative = function(printers) {
          return callDirectPrint({
            printers: printers
          });
        };
        
        console.log('✅ Sistema de impresión simplificado inicializado');
        console.log('🔍 Función isFlutterWebView() disponible para detectar Flutter WebView');
        console.log('📝 Uso: callDirectPrint({printers: [{ip: "192.168.1.13", copies: 1, content: "texto1", title: "título1"}, {ip: "192.168.1.8", copies: 2, content: "texto2", title: "título2"}]})');
        console.log('📝 O: printToNative([{ip: "192.168.1.13", copies: 1, content: "texto", title: "título"}])');
        console.log('🔍 O: isFlutterWebView() para detectar si estás en Flutter WebView');
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
          
          // Verificar si estamos en Flutter WebView
          if (typeof isFlutterWebView === 'function') {
            const isFlutter = isFlutterWebView();
            console.log('🔍 ¿Estamos en Flutter WebView?', isFlutter);
          }
          
          // Datos de prueba con contenido específico por impresora
          const testData = {
            printers: [
              {
                ip: "192.168.1.13",
                copies: 1,
                content: "Este es el contenido para la primera impresora\\n<imagen_grande>iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg== Fecha Impresion 2024-01-01",
                title: "Documento Impresora 1"
              },
              {
                ip: "192.168.1.8",
                copies: 2,
                content: "Este es contenido diferente para la segunda impresora\\nCon información específica para esta ubicación",
                title: "Documento Impresora 2"
              }
            ]
          };
          
          console.log('📋 Datos de prueba (contenido específico por impresora):', testData);
          
          // Llamar la función
          try {
            callDirectPrint(testData);
            console.log('✅ Función de impresión llamada exitosamente');
            return 'Función de impresión probada exitosamente con contenido específico por impresora';
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

  /// Returns JavaScript code to test the isFlutterWebView function.
  static String getTestIsFlutterWebViewScript() {
    return '''
      (function() {
        console.log('🔍 PROBANDO FUNCIÓN isFlutterWebView');
        console.log('=====================================');
        
        if (typeof isFlutterWebView === 'function') {
          console.log('✅ isFlutterWebView está disponible');
          
          const isFlutter = isFlutterWebView();
          console.log('🔍 Resultado de isFlutterWebView():', isFlutter);
          
          if (isFlutter) {
            console.log('✅ Estamos ejecutándose en Flutter WebView');
            console.log('📋 Funciones disponibles:');
            console.log('   - callDirectPrint:', typeof callDirectPrint === 'function');
            console.log('   - printToNative:', typeof printToNative === 'function');
            console.log('   - DirectPrint:', typeof DirectPrint !== 'undefined');
            console.log('   - window.NativePrinter:', typeof window.NativePrinter !== 'undefined');
            console.log('   - window.flutterPrintConfig:', typeof window.flutterPrintConfig !== 'undefined');
          } else {
            console.log('❌ NO estamos en Flutter WebView');
            console.log('💡 Esto puede indicar que estamos en un navegador normal');
          }
          
          return {
            isFlutterWebView: isFlutter,
            functions: {
              callDirectPrint: typeof callDirectPrint === 'function',
              printToNative: typeof printToNative === 'function',
              DirectPrint: typeof DirectPrint !== 'undefined',
              NativePrinter: typeof window.NativePrinter !== 'undefined',
              flutterPrintConfig: typeof window.flutterPrintConfig !== 'undefined'
            }
          };
        } else {
          console.log('❌ isFlutterWebView NO está disponible');
          return 'Error: Función isFlutterWebView no está disponible';
        }
      })();
    ''';
  }

  /// Returns JavaScript code to get function usage information.
  static String getFunctionUsageScript() {
    return '''
      (function() {
        const functionInfo = {
          available: typeof callDirectPrint === 'function',
          alternativeAvailable: typeof printToNative === 'function',
          usage: {
            method1: 'callDirectPrint({printers: [{ip: "192.168.1.13", copies: 1, content: "texto1", title: "título1"}, {ip: "192.168.1.8", copies: 2, content: "texto2", title: "título2"}]})',
            method2: 'printToNative([{ip: "192.168.1.13", copies: 1, content: "texto", title: "título"}])',
            method3: 'window.NativePrinter.postMessage(JSON.stringify({printers: [{ip: "192.168.1.13", copies: 1, content: "texto1", title: "título1"}, {ip: "192.168.1.8", copies: 2, content: "texto2", title: "título2"}]}))'
          },
          requiredFields: {
            printers: 'array - Lista de impresoras con ip (string), copies (number), content (string) y title (string)'
          },
          example: {
            printers: [
              { ip: "192.168.1.13", copies: 2, content: "Texto a imprimir en impresora 1", title: "Título para impresora 1" },
              { ip: "192.168.1.8", copies: 1, content: "Texto diferente para impresora 2", title: "Título para impresora 2" }
            ]
          },
          description: "Cada impresora puede tener contenido y título diferentes. Esto permite imprimir documentos específicos en cada ubicación."
        };
        
        console.log('📖 Información de uso de función de impresión:', functionInfo);
        return functionInfo;
      })();
    ''';
  }

  /// Returns JavaScript code to test invoice printing with a smaller QR.
  static String getTestInvoiceScript() {
    return '''
      (function() {
        console.log('🧾 PROBANDO IMPRESIÓN DE FACTURA');
        console.log('==================================');
        
        // Verificar si la función está disponible
        if (typeof callDirectPrint === 'function') {
          console.log('✅ callDirectPrint está disponible');
          
          // Datos de prueba de factura con QR real
          const testInvoiceData = {
            content: "FACTURA ELECTRÓNICA\\n" +
                     "Cliente: Juan Pérez\\n" +
                     "Fecha: 2024-01-15\\n" +
                     "\\n" +
                     "PRODUCTOS:\\n" +
                     "Producto 1 - \$10.00\\n" +
                     "Producto 2 - \$15.50\\n" +
                     "\\n" +
                     "TOTAL: \$25.50\\n" +
                     "\\n" +
                     "<imagen_grande>iVBORw0KGgoAAAANSUhEUgAAALQAAADECAYAAAA27wvzAAAAAXNSR0IArs4c6QAAGY1JREFUeF7tnQeoXNUTxk+s2HsvSey9YRdJYhe7WLEksSHYEBuKmkSxoiJiF01iw16xI0nAhg171yQq9q7Yy585sO//9r739rdf5uy+TTIXBHXOmfLNN3Pm3t13d8B///33X+qQ6/jjj0+XXnpp2mKLLdJTTz1V59X222+fHn/88XTSSSelCy+8sIjHl19+eTrmmGN61TX//POnRx55JG2++eZFbE0PSv7888900EEHpXvuuSf99ddf04PLPXwc0EmEfvHFF9NGG22UBgwYkD7++OO07LLLZoe/++67tOSSS2aQX3nllbTuuusWAbtGaCPt/fffn/V/+OGH6cwzz0wTJkxIAwcOTB988EGabbbZitjrdCXffPNNWmyxxdKss86a/v777053t1f/OorQ5uFqq62W3n333XTRRRelE044ITt9ww03pEMPPTSttdZa6fXXX092qFxyySXpuuuuS5aENdZYI40ePTpttdVWef0111yTxo4dm0aOHJnuvPPO9Pbbb6err7467bLLLnUg1Ag9ZMiQNHHixC7ZL7/8kpZZZpn0008/5S69ww47ZNnTTz+dzj333PTSSy+lOeaYI2277bbp7LPPTksvvXTXXpOdccYZ6YUXXkhzzz132nLLLdN5552XlltuufTmm2/mOAYNGpRuu+22vOedd95JI0aMyHLz9ccff0x2Gq2yyipp5513zvq//PLLtOuuu6YLLrggjRo1Kt11113JTpBTTjkl67OLMHn//fdz991ss83SBhtskHV9//33+QS67LLL0uKLL5422WSTHJtd9u+nnXZatvv777/nGO6444701VdfpRVXXDEdd9xx6YADDug40nccoc8666yctA033DCTwq4dd9wxPfroo+n888/PSTz99NPTOeeck5ZaaqmcoMceeyz98ccfmZQ2rtTkc801V/rnn3+yjtdeey2tuuqqTRHaFm2zzTbpySefzIQyfWbfCGb6jBDffvttmjp1aiai+bnEEktkwm688cbp119/zX78/PPPXXbfeOONZCeQ+Wt+GJHtqp1KRhI7DWpd0nyfc84509Zbb52eeOKJXFwLLbRQtmMnh8U8yyyzZD0rr7wyYmIn2/rrr58WWGCB3IGHDh2aTyEj9YEHHpjGjRuX9UyePDn7Zf4Yiffcc8/sw6RJk9LCCy+cfTfS23hixX3qqad2FKk7jtB25K+00koZJEvwIosskruHHYFGoAUXXLDrv23t8ssvnx588MHcSYxw9u/dCW8d3RJo+6pXXx3a1u299965E9pcb6fB6quvnslj87vN8TaeWMc3Ylm3stnfOu348eO7/vvff/9Nu+22W+7mtu/rr79umtDmg90z2ClgxLJuaTgY4azz22hmxWBd3Tp6DaO+MKkR2vS+9dZbOZ6777477bXXXmnw4MHpo48+6iqm7iPH7bffnvbbb7+M88svv5zzYeQeNmxYmn322fNoaEXWKVfHEdqAsS723HPP5S5sx7mNDrWx4Jlnnsndz5J6+OGHZxx/++23dO211+ak2vFcI7R1nptuuqlPrBsR2orjoYceyh3o2GOPzaeBzfY2jphtu+69997cwdZZZ5306quv5pHIunT3MaW7cYup2Q5t+6xobH6vjVzbbbddLiC7rICteG+++eZMSMKkRuhFF100F5ZdVuzmu92ffP75570S+sgjj8wjnJ2MdkLWLruPsVPPbiD32GOPTuFz6khC14i29tpr5yP94YcfzvPyYYcdlp9+2Fw6zzzz5GOz+2Wd0ACuEbrWOftCuxGhV1hhhdwNrePabG5+WOeyebJ2k2h+7bTTTrnbWdez4/i9997L/tqYVL1qhLb52O4T7KoVaHXk6N4lbRyworZuf9999+V9u+++e76RtYK1mZwwqRHaxpUpU6ZkHXbimO/WYb/44oteCW2YX3/99flGecyYMV0h2Whlo5Z18H322ScI3QgB6yDWmW3MsMQagQxwGxusA1u3tBnT/t98882XRxG7YbOuseaaa3YR2m4q7eZSIbTdXF155ZXp6KOPzp34k08+yXOndTGbb60rWve2y9ZcccUV+WbrxhtvzIR74IEHsn2bvWvEMx02ksw777x5/rYnCRaHdXwj5MEHH5xn1u4ztEJoG0sIk2YIbU+TbKSw2bx272E3jNYYjMDPPvtsln366ad53rbiNp/N9065OrJDGzjW+azT2WXHus17tWvffffNd9zWoffff//cQZ5//vn8VMQIXOvQzRLaur3N7UZmI+1nn32WTRkJLZl22XFr44ettVnZisl8MtJbp7InLTbz2jxrBWhrbBS65ZZb8s2UzbZGBjvybZSw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
                     Fecha Impresion 2024-01-15",
            title: "Factura Electrónica #FE-001",
            printers: [
              { ip: "192.168.1.13", copies: 1 }
            ]
          };
          
          console.log('📋 Datos de factura de prueba (con QR):', testInvoiceData);
          
          // Llamar la función
          try {
            callDirectPrint(testInvoiceData);
            console.log('✅ Factura enviada exitosamente');
            return 'Factura enviada exitosamente';
          } catch (error) {
            console.error('❌ Error al enviar factura:', error);
            return 'Error: ' + error.message;
          }
        } else {
          console.log('❌ callDirectPrint NO está disponible');
          return 'Error: Función callDirectPrint no está disponible';
        }
      })();
    ''';
  }

  /// Returns JavaScript code to setup textarea auto-processing.
  static String getTextareaAutoProcessingScript() {
    return '''
      (function() {
        console.log('🔧 Configurando procesamiento automático de textarea...');
        
        // Función para procesar contenido del textarea
        function processTextareaContent() {
          console.log('📝 Procesando contenido del textarea automáticamente...');
          
          // Buscar textarea por diferentes selectores
          const textarea = document.querySelector('textarea') ||
                          document.querySelector('#content') ||
                          document.querySelector('.content') ||
                          document.querySelector('[name="content"]') ||
                          document.querySelector('[placeholder*="factura"]') ||
                          document.querySelector('[placeholder*="contenido"]');
          
          if (!textarea) {
            console.log('❌ No se encontró textarea en la página');
            return;
          }
          
          const content = textarea.value.trim();
          if (!content) {
            console.log('❌ El textarea está vacío');
            return;
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
          
          // Crear botón de impresión si no existe
          let printButton = document.querySelector('#auto-print-button');
          if (!printButton) {
            printButton = document.createElement('button');
            printButton.id = 'auto-print-button';
            printButton.innerHTML = '🖨️ Imprimir';
            printButton.style.cssText = `
              position: fixed;
              top: 20px;
              right: 20px;
              z-index: 10000;
              background: #007bff;
              color: white;
              border: none;
              padding: 10px 20px;
              border-radius: 5px;
              cursor: pointer;
              font-size: 14px;
              box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            `;
            
            printButton.onclick = function() {
              console.log('🖨️ Botón de impresión automática clickeado');
              
              const printData = {
                printers: [
                  {
                    ip: printerIP,
                    copies: 1,
                    content: content,
                    title: title
                  }
                ]
              };
              
              console.log('📋 Datos de impresión:', printData);
              
              if (typeof callDirectPrint === 'function') {
                callDirectPrint(printData);
                printButton.innerHTML = '✅ Enviado';
                printButton.style.background = '#28a745';
                setTimeout(() => {
                  printButton.innerHTML = '🖨️ Imprimir';
                  printButton.style.background = '#007bff';
                }, 2000);
              } else {
                printButton.innerHTML = '❌ Error';
                printButton.style.background = '#dc3545';
                setTimeout(() => {
                  printButton.innerHTML = '🖨️ Imprimir';
                  printButton.style.background = '#007bff';
                }, 2000);
              }
            };
            
            document.body.appendChild(printButton);
            console.log('✅ Botón de impresión automática agregado');
          }
          
          // Mostrar información del contenido
          let infoDiv = document.querySelector('#content-info');
          if (!infoDiv) {
            infoDiv = document.createElement('div');
            infoDiv.id = 'content-info';
            infoDiv.style.cssText = `
              position: fixed;
              top: 70px;
              right: 20px;
              z-index: 10000;
              background: #f8f9fa;
              border: 1px solid #dee2e6;
              padding: 10px;
              border-radius: 5px;
              font-size: 12px;
              max-width: 200px;
              box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            `;
            document.body.appendChild(infoDiv);
          }
          
          infoDiv.innerHTML = `
            <strong>📄 Información del contenido:</strong><br>
            <strong>Título:</strong> \${title}<br>
            <strong>Tipo:</strong> \${isInvoice ? 'Factura' : 'Documento'}<br>
            <strong>Caracteres:</strong> \${content.length}<br>
            <strong>IP:</strong> \${printerIP}
          `;
          
          console.log('✅ Información del contenido mostrada');
        }
        
        // Configurar observador de cambios en textarea
        function setupTextareaObserver() {
          const textarea = document.querySelector('textarea') ||
                          document.querySelector('#content') ||
                          document.querySelector('.content') ||
                          document.querySelector('[name="content"]') ||
                          document.querySelector('[placeholder*="factura"]') ||
                          document.querySelector('[placeholder*="contenido"]');
          
          if (textarea) {
            console.log('✅ Textarea encontrado, configurando observador...');
            
            // Procesar contenido inicial
            processTextareaContent();
            
            // Observar cambios en el textarea
            let timeout;
            textarea.addEventListener('input', function() {
              clearTimeout(timeout);
              timeout = setTimeout(processTextareaContent, 1000); // Esperar 1 segundo después del último cambio
            });
            
            // Observar cambios en el DOM para detectar nuevos textareas
            const observer = new MutationObserver(function(mutations) {
              mutations.forEach(function(mutation) {
                if (mutation.type === 'childList') {
                  const newTextarea = document.querySelector('textarea') ||
                                    document.querySelector('#content') ||
                                    document.querySelector('.content') ||
                                    document.querySelector('[name="content"]') ||
                                    document.querySelector('[placeholder*="factura"]') ||
                                    document.querySelector('[placeholder*="contenido"]');
                  
                  if (newTextarea && newTextarea !== textarea) {
                    console.log('🆕 Nuevo textarea detectado, configurando...');
                    setupTextareaObserver();
                  }
                }
              });
            });
            
            observer.observe(document.body, {
              childList: true,
              subtree: true
            });
            
            console.log('✅ Observador de textarea configurado');
          } else {
            console.log('⚠️ No se encontró textarea, reintentando en 2 segundos...');
            setTimeout(setupTextareaObserver, 2000);
          }
        }
        
        // Iniciar configuración
        setupTextareaObserver();
        
        // Exponer función globalmente
        window.processTextareaContent = processTextareaContent;
        window.setupTextareaObserver = setupTextareaObserver;
        
        console.log('✅ Procesamiento automático de textarea configurado');
        return 'Procesamiento automático de textarea configurado';
      })();
    ''';
  }
}
