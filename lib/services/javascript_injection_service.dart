/// Service for handling JavaScript injection and WebView communication.
class JavaScriptInjectionService {
  /// Returns the JavaScript code that intercepts print functionality.
  static String getPrintInterceptorScript() {
    return '''
      (function() {
        console.log('🚀 Inicializando interceptor de impresión...');
        
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
            
            // 1. Obtener contenido a imprimir (múltiples selectores para compatibilidad)
            let content = '';
            const textareaSelectors = [
              '#textInput',
              '#content',
              'textarea',
              '.text-input',
              '[data-print-content]'
            ];
            
            for (const selector of textareaSelectors) {
              const element = document.querySelector(selector);
              if (element) {
                content = element.value || element.textContent || element.innerText || '';
                console.log('📝 Contenido encontrado con selector: ' + selector);
                break;
              }
            }
            
            if (!content.trim()) {
              alert('No hay contenido para imprimir. Por favor, escriba algo en el área de texto.');
              console.warn('❌ Impresión cancelada: no hay contenido.');
              return;
            }
            
            // 2. Obtener configuración de impresoras (múltiples selectores)
            const printers = [];
            const printerSelectors = [
              '.printer-row',
              '.printer-config',
              '[data-printer]',
              '.printer-item'
            ];
            
            for (const selector of printerSelectors) {
              const rows = document.querySelectorAll(selector);
              if (rows.length > 0) {
                console.log('🖨️ Impresoras encontradas con selector: ' + selector);
                rows.forEach(function(row) {
                  const ipInput = row.querySelector('.printer-ip') || 
                                 row.querySelector('[data-ip]') ||
                                 row.querySelector('input[type="text"]');
                  const copiesInput = row.querySelector('.printer-copies') ||
                                     row.querySelector('[data-copies]') ||
                                     row.querySelector('input[type="number"]');
                  
                  if (ipInput) {
                    const ip = ipInput.value.trim();
                    const copies = copiesInput ? (parseInt(copiesInput.value, 10) || 1) : 1;
                    
                    if (ip) {
                      printers.push({ ip: ip, copies: copies });
                    }
                  }
                });
                break;
              }
            }
            
            // Si no hay impresoras configuradas, usar la impresora por defecto
            if (printers.length === 0) {
              console.log('⚠️ No hay impresoras configuradas, usando impresora por defecto');
              printers.push({ ip: '192.168.1.13', copies: 1 });
            }
            
            console.log('🖨️ Impresoras configuradas:', printers);
            
            // 3. Obtener título
            const title = document.title || 
                         document.querySelector('h1')?.textContent ||
                         'Documento';
            
            // 4. Construir y enviar los datos a Flutter
            const printData = {
              content: content.trim(),
              title: title.trim(),
              printers: printers,
              url: window.location.href,
              timestamp: new Date().toISOString()
            };
            
            console.log('➡️ Enviando datos a Flutter:', printData);
            
            // Intentar usar window.NativePrinter primero, luego DirectPrint como fallback
            if (window.NativePrinter && window.NativePrinter.postMessage) {
              window.NativePrinter.postMessage(JSON.stringify(printData));
            } else if (typeof DirectPrint !== 'undefined') {
              DirectPrint.postMessage(JSON.stringify(printData));
            } else {
              console.error('❌ No se encontró canal de comunicación con Flutter');
              alert('Error: No se puede comunicar con la aplicación Flutter');
            }
            
          } catch (error) {
            console.error('❌ Error al preparar datos para impresión:', error);
            alert('Error al intentar imprimir: ' + error.message);
          }
        }
        
        // --- INTERCEPTOR DE BOTÓN DE IMPRESIÓN ---
        function interceptPrintButton() {
          const buttonSelectors = [
            '#printBtn',
            '#print-button',
            '.print-btn',
            '[data-print]',
            'button[onclick*="print"]',
            'button:contains("Imprimir")',
            'button:contains("Print")',
            'input[value*="Imprimir"]',
            'input[value*="Print"]',
            'button',
            'input[type="button"]',
            'input[type="submit"]'
          ];
          
          let foundButtons = 0;
          
          for (const selector of buttonSelectors) {
            try {
              const buttons = document.querySelectorAll(selector);
              buttons.forEach((button, index) => {
                const buttonText = button.textContent?.toLowerCase() || '';
                const buttonValue = button.value?.toLowerCase() || '';
                const buttonId = button.id?.toLowerCase() || '';
                const buttonClass = button.className?.toLowerCase() || '';
                
                // Verificar si el botón está relacionado con impresión
                const isPrintButton = 
                  buttonText.includes('imprimir') ||
                  buttonText.includes('print') ||
                  buttonValue.includes('imprimir') ||
                  buttonValue.includes('print') ||
                  buttonId.includes('print') ||
                  buttonClass.includes('print') ||
                  button.hasAttribute('data-print') ||
                  button.onclick?.toString().includes('print') ||
                  selector.includes('print');
                
                if (isPrintButton && !button.hasAttribute('data-intercepted')) {
                  foundButtons++;
                  console.log('🔍 Botón de imprimir encontrado:', {
                    selector: selector,
                    index: index,
                    text: button.textContent?.trim(),
                    id: button.id,
                    class: button.className,
                    value: button.value
                  });
                  
                  button.setAttribute('data-intercepted', 'true');
                  
                  // Remover listeners existentes
                  const newButton = button.cloneNode(true);
                  button.parentNode.replaceChild(newButton, button);
                  
                  // Agregar nuestro listener
                  newButton.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    console.log('🎯 Clic en botón de imprimir interceptado!');
                    callDirectPrint();
                    return false;
                  });
                  
                  console.log('✅ Interceptor instalado en:', selector, 'índice:', index);
                }
              });
            } catch (error) {
              console.log('⚠️ Error con selector:', selector, error);
            }
          }
          
          return foundButtons > 0;
        }
        
        // --- INTERCEPTAR window.print() ---
        const originalPrint = window.print;
        window.print = function() {
          console.log('🎯 window.print() interceptado!');
          callDirectPrint();
        };
        
        // --- EJECUTAR INTERCEPTOR ---
        let attempts = 0;
        const maxAttempts = 10;
        
        function tryIntercept() {
          attempts++;
          if (interceptPrintButton()) {
            console.log('✅ Interceptor de impresión activado en intento ' + attempts);
          } else if (attempts < maxAttempts) {
            console.log('⏳ Reintentando interceptor... (' + attempts + '/' + maxAttempts + ')');
            setTimeout(tryIntercept, 500);
          } else {
            console.log('⚠️ No se pudo encontrar botón de imprimir después de ' + maxAttempts + ' intentos');
          }
        }
        
        // --- INICIALIZAR ---
        tryIntercept();
        
        // --- FORZAR DETECCIÓN DE WEBVIEW PARA FLUTTER ---
        function forceWebViewDetection() {
          console.log('🔍 Forzando detección de WebView para Flutter...');
          
          // Simular que es un WebView de Flutter
          window.isWebView = true;
          window.isFlutterWebView = true;
          window.webViewDetected = true;
          window.webViewPlatform = 'flutter';
          
          // Detectar plataforma
          if (navigator.userAgent.indexOf('iPhone') !== -1 || navigator.userAgent.indexOf('iPad') !== -1) {
            window.isIOS = true;
            window.isAndroid = false;
            console.log('✅ Detectado como iOS WebView');
          } else if (navigator.userAgent.indexOf('Android') !== -1) {
            window.isAndroid = true;
            window.isIOS = false;
            console.log('✅ Detectado como Android WebView');
          } else {
            window.isAndroid = false;
            window.isIOS = false;
            console.log('⚠️ Plataforma no detectada, asumiendo WebView genérico');
          }
          
          // Llamar funciones de activación si existen
          var activationFunctions = [
            'activatePrintButton',
            'enablePrintButton',
            'showPrintButton',
            'initWebViewPrint',
            'setupWebViewPrint'
          ];
          
          for (var i = 0; i < activationFunctions.length; i++) {
            var funcName = activationFunctions[i];
            if (typeof window[funcName] === 'function') {
              console.log('✅ Ejecutando ' + funcName + '...');
              try {
                window[funcName]();
                console.log('✅ ' + funcName + ' ejecutada exitosamente');
              } catch (e) {
                console.log('❌ Error ejecutando ' + funcName + ':', e.message);
              }
            }
          }
          
          console.log('✅ Detección de WebView forzada para Flutter');
        }
        
        // Forzar detección de WebView
        forceWebViewDetection();
        
        // También intentar cuando el DOM cambie
        const observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            if (mutation.addedNodes.length > 0) {
              setTimeout(tryIntercept, 100);
            }
          });
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
        
        // --- EXPONER FUNCIONES GLOBALES ---
        window.callDirectPrint = callDirectPrint;
        window.isFlutterWebView = function() {
          return typeof DirectPrint !== 'undefined' || typeof window.NativePrinter !== 'undefined';
        };
        
        console.log('✅ Interceptor de impresión inicializado completamente');
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

  /// Returns JavaScript code to diagnose the page structure.
  static String getDiagnosticScript() {
    return '''
(function() {
  console.log('🔍 DIAGNÓSTICO DE LA PÁGINA WEB');
  console.log('=====================================');
  
  // 1. Buscar botones de impresión
  console.log('1. BUSCANDO BOTONES DE IMPRESIÓN:');
  var buttonSelectors = [
    '#printBtn',
    '#print-button',
    '.print-btn',
    '[data-print]',
    'button[onclick*="print"]',
    'button',
    'input[type="button"]',
    'input[type="submit"]'
  ];
  
  for (var i = 0; i < buttonSelectors.length; i++) {
    var selector = buttonSelectors[i];
    var elements = document.querySelectorAll(selector);
    console.log('Selector "' + selector + '": ' + elements.length + ' elementos encontrados');
    for (var j = 0; j < elements.length; j++) {
      var el = elements[j];
      var text = el.textContent ? el.textContent.trim() : '';
      console.log('  ' + (j + 1) + '. ' + el.tagName + ' - ID: "' + (el.id || '') + '" - Class: "' + (el.className || '') + '" - Text: "' + text + '"');
    }
  }
  
  // 2. Buscar textareas
  console.log('\\n2. BUSCANDO TEXTAREAS:');
  var textareaSelectors = [
    '#textInput',
    '#content',
    'textarea',
    '.text-input',
    '[data-print-content]',
    'input[type="text"]'
  ];
  
  for (var i = 0; i < textareaSelectors.length; i++) {
    var selector = textareaSelectors[i];
    var elements = document.querySelectorAll(selector);
    console.log('Selector "' + selector + '": ' + elements.length + ' elementos encontrados');
    for (var j = 0; j < elements.length; j++) {
      var el = elements[j];
      var value = el.value ? el.value.substring(0, 50) : '';
      console.log('  ' + (j + 1) + '. ' + el.tagName + ' - ID: "' + (el.id || '') + '" - Class: "' + (el.className || '') + '" - Value: "' + value + '..."');
    }
  }
  
  // 3. Buscar configuraciones de impresoras
  console.log('\\n3. BUSCANDO CONFIGURACIONES DE IMPRESORAS:');
  var printerSelectors = [
    '.printer-row',
    '.printer-config',
    '[data-printer]',
    '.printer-item',
    'input[placeholder*="ip"]',
    'input[placeholder*="IP"]'
  ];
  
  for (var i = 0; i < printerSelectors.length; i++) {
    var selector = printerSelectors[i];
    var elements = document.querySelectorAll(selector);
    console.log('Selector "' + selector + '": ' + elements.length + ' elementos encontrados');
  }
  
  // 4. Información general de la página
  console.log('\\n4. INFORMACIÓN GENERAL:');
  console.log('  Título: "' + document.title + '"');
  console.log('  URL: "' + window.location.href + '"');
  console.log('  Elementos totales: ' + document.querySelectorAll('*').length);
  
  // 5. Buscar elementos con texto relacionado con imprimir
  console.log('\\n5. ELEMENTOS CON TEXTO "IMPRIMIR":');
  var allElements = document.querySelectorAll('*');
  for (var i = 0; i < allElements.length; i++) {
    var el = allElements[i];
    if (el.textContent && el.textContent.toLowerCase().indexOf('imprimir') !== -1) {
      console.log('  ' + el.tagName + ' - ID: "' + (el.id || '') + '" - Class: "' + (el.className || '') + '" - Text: "' + el.textContent.trim() + '"');
    }
  }
  
  console.log('\\n✅ DIAGNÓSTICO COMPLETADO');
  return 'Diagnóstico completado. Revisa la consola para más detalles.';
})();
    ''';
  }

  /// Returns JavaScript code to manually test print button functionality.
  static String getManualPrintTestScript() {
    return '''
(function() {
  console.log('🧪 PRUEBA MANUAL DE BOTÓN DE IMPRESIÓN');
  console.log('==========================================');
  
  // Buscar todos los botones
  var allButtons = document.querySelectorAll('button, input[type="button"], input[type="submit"]');
  console.log('Total de botones encontrados:', allButtons.length);
  
  var printButtons = [];
  
  for (var i = 0; i < allButtons.length; i++) {
    var button = allButtons[i];
    var text = button.textContent ? button.textContent.toLowerCase() : '';
    var value = button.value ? button.value.toLowerCase() : '';
    var id = button.id ? button.id.toLowerCase() : '';
    var className = button.className ? button.className.toLowerCase() : '';
    
    if (text.indexOf('imprimir') !== -1 || text.indexOf('print') !== -1 || 
        value.indexOf('imprimir') !== -1 || value.indexOf('print') !== -1 ||
        id.indexOf('print') !== -1 || className.indexOf('print') !== -1) {
      printButtons.push({
        element: button,
        index: i,
        text: button.textContent ? button.textContent.trim() : '',
        id: button.id || '',
        class: button.className || '',
        value: button.value || ''
      });
    }
  }
  
  console.log('Botones de impresión encontrados:', printButtons.length);
  for (var i = 0; i < printButtons.length; i++) {
    console.log('Botón ' + (i + 1) + ':', printButtons[i]);
  }
  
  // Simular clic en el primer botón de impresión encontrado
  if (printButtons.length > 0) {
    var firstButton = printButtons[0].element;
    console.log('🎯 Simulando clic en:', printButtons[0]);
    
    try {
      // Crear un evento de clic
      var clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      });
      
      // Disparar el evento
      firstButton.dispatchEvent(clickEvent);
      console.log('✅ Evento de clic disparado exitosamente');
      
      return 'Clic simulado en: ' + printButtons[0].text;
    } catch (error) {
      console.error('❌ Error al simular clic:', error);
      return 'Error: ' + error.message;
    }
  } else {
    console.log('⚠️ No se encontraron botones de impresión');
    return 'No se encontraron botones de impresión';
  }
})();
    ''';
  }

  /// Returns JavaScript code to debug JavaScript injection and event handling.
  static String getDebugInjectionScript() {
    return '''
(function() {
  console.log('🔧 DEPURACIÓN DE INYECCIÓN DE JAVASCRIPT');
  console.log('==========================================');
  
  // 1. Verificar si DirectPrint está disponible
  console.log('1. CANAL DIRECTPRINT:');
  if (typeof DirectPrint !== 'undefined') {
    console.log('✅ DirectPrint está disponible');
    console.log('DirectPrint:', DirectPrint);
  } else {
    console.log('❌ DirectPrint NO está disponible');
  }
  
  // 2. Verificar si callDirectPrint está definida
  console.log('\\n2. FUNCIÓN CALLDIRECTPRINT:');
  if (typeof callDirectPrint === 'function') {
    console.log('✅ callDirectPrint está definida');
  } else {
    console.log('❌ callDirectPrint NO está definida');
  }
  
  // 3. Verificar si interceptPrintButton está definida
  console.log('\\n3. FUNCIÓN INTERCEPTPRINTBUTTON:');
  if (typeof interceptPrintButton === 'function') {
    console.log('✅ interceptPrintButton está definida');
  } else {
    console.log('❌ interceptPrintButton NO está definida');
  }
  
  // 4. Verificar window.print
  console.log('\\n4. WINDOW.PRINT:');
  if (window.print && window.print.toString().indexOf('callDirectPrint') !== -1) {
    console.log('✅ window.print está interceptado');
  } else {
    console.log('❌ window.print NO está interceptado');
    console.log('window.print original:', window.print);
  }
  
  // 5. Verificar elementos interceptados
  console.log('\\n5. ELEMENTOS INTERCEPTADOS:');
  var interceptedElements = document.querySelectorAll('[data-intercepted="true"]');
  console.log('Elementos con data-intercepted:', interceptedElements.length);
  for (var i = 0; i < interceptedElements.length; i++) {
    var el = interceptedElements[i];
    var text = el.textContent ? el.textContent.trim() : '';
    console.log('  ' + (i + 1) + '. ' + el.tagName + ' - ID: "' + (el.id || '') + '" - Text: "' + text + '"');
  }
  
  // 6. Verificar listeners de eventos
  console.log('\\n6. VERIFICANDO LISTENERS DE EVENTOS:');
  var allButtons = document.querySelectorAll('button, input[type="button"], input[type="submit"]');
  for (var i = 0; i < allButtons.length; i++) {
    var button = allButtons[i];
    var text = button.textContent ? button.textContent.toLowerCase() : '';
    if (text.indexOf('imprimir') !== -1 || text.indexOf('print') !== -1) {
      var buttonText = button.textContent ? button.textContent.trim() : '';
      console.log('Botón ' + (i + 1) + ': "' + buttonText + '"');
      console.log('  - data-intercepted: ' + button.hasAttribute('data-intercepted'));
      console.log('  - onclick: ' + button.onclick);
      console.log('  - addEventListener disponible: ' + (typeof button.addEventListener === 'function'));
    }
  }
  
  console.log('\\n✅ DEPURACIÓN COMPLETADA');
  return 'Depuración completada. Revisa la consola para más detalles.';
})();
    ''';
  }

  /// Returns JavaScript code to force WebView detection for Flutter.
  static String getForceWebViewDetectionScript() {
    return '''
(function() {
  console.log('🔍 FORZANDO DETECCIÓN DE WEBVIEW PARA FLUTTER');
  console.log('==============================================');
  
  // 1. Verificar detección actual
  console.log('1. DETECCIÓN ACTUAL:');
  console.log('  User Agent:', navigator.userAgent);
  console.log('  Platform:', navigator.platform);
  console.log('  Vendor:', navigator.vendor);
  
  // 2. Verificar si hay funciones de detección de WebView
  var webViewDetectionFunctions = [
    'isWebView',
    'detectWebView',
    'checkWebView',
    'isAndroidWebView',
    'isIOSWebView',
    'isFlutterWebView'
  ];
  
  console.log('\\n2. FUNCIONES DE DETECCIÓN:');
  for (var i = 0; i < webViewDetectionFunctions.length; i++) {
    var funcName = webViewDetectionFunctions[i];
    if (typeof window[funcName] === 'function') {
      console.log('  ✅ ' + funcName + ' está definida');
      try {
        var result = window[funcName]();
        console.log('    Resultado:', result);
      } catch (e) {
        console.log('    Error al ejecutar:', e.message);
      }
    } else {
      console.log('  ❌ ' + funcName + ' NO está definida');
    }
  }
  
  // 3. Verificar variables globales de WebView
  var webViewVariables = [
    'isWebView',
    'webViewDetected',
    'isAndroid',
    'isIOS',
    'isFlutter',
    'webViewPlatform'
  ];
  
  console.log('\\n3. VARIABLES GLOBALES:');
  for (var i = 0; i < webViewVariables.length; i++) {
    var varName = webViewVariables[i];
    if (typeof window[varName] !== 'undefined') {
      console.log('  ✅ ' + varName + ' =', window[varName]);
    } else {
      console.log('  ❌ ' + varName + ' NO está definida');
    }
  }
  
  // 4. Forzar detección de Flutter WebView
  console.log('\\n4. FORZANDO DETECCIÓN:');
  
  // Simular que es un WebView de Flutter
  window.isWebView = true;
  window.isFlutterWebView = true;
  window.webViewDetected = true;
  window.webViewPlatform = 'flutter';
  
  // Detectar plataforma
  if (navigator.userAgent.indexOf('iPhone') !== -1 || navigator.userAgent.indexOf('iPad') !== -1) {
    window.isIOS = true;
    window.isAndroid = false;
    console.log('  ✅ Detectado como iOS');
  } else if (navigator.userAgent.indexOf('Android') !== -1) {
    window.isAndroid = true;
    window.isIOS = false;
    console.log('  ✅ Detectado como Android');
  } else {
    window.isAndroid = false;
    window.isIOS = false;
    console.log('  ⚠️ Plataforma no detectada');
  }
  
  // 5. Verificar si hay funciones que necesiten ser llamadas
  var activationFunctions = [
    'activatePrintButton',
    'enablePrintButton',
    'showPrintButton',
    'initWebViewPrint',
    'setupWebViewPrint'
  ];
  
  console.log('\\n5. FUNCIONES DE ACTIVACIÓN:');
  for (var i = 0; i < activationFunctions.length; i++) {
    var funcName = activationFunctions[i];
    if (typeof window[funcName] === 'function') {
      console.log('  ✅ ' + funcName + ' está definida, ejecutando...');
      try {
        window[funcName]();
        console.log('    ✅ Ejecutada exitosamente');
      } catch (e) {
        console.log('    ❌ Error al ejecutar:', e.message);
      }
    } else {
      console.log('  ❌ ' + funcName + ' NO está definida');
    }
  }
  
  // 6. Verificar botones después de la activación
  console.log('\\n6. VERIFICANDO BOTONES DESPUÉS DE ACTIVACIÓN:');
  var printButtons = document.querySelectorAll('button, input[type="button"], input[type="submit"]');
  for (var i = 0; i < printButtons.length; i++) {
    var button = printButtons[i];
    var text = button.textContent ? button.textContent.toLowerCase() : '';
    if (text.indexOf('imprimir') !== -1 || text.indexOf('print') !== -1) {
      console.log('  Botón encontrado:', button.textContent.trim());
      console.log('    - Visible:', button.offsetParent !== null);
      console.log('    - Habilitado:', !button.disabled);
      console.log('    - Display:', window.getComputedStyle(button).display);
      console.log('    - Visibility:', window.getComputedStyle(button).visibility);
    }
  }
  
  console.log('\\n✅ DETECCIÓN DE WEBVIEW FORZADA');
  return 'Detección de WebView forzada para Flutter. Revisa la consola para más detalles.';
})();
    ''';
  }
}
