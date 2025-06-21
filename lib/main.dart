import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'dart:convert';


// Clase para manejar la conexión con impresoras de red
class NetworkPrinter {
  static const int printerPort = 9100; // Puerto estándar para impresoras ESC/POS

  // Detectar si estamos en Android
  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  
  // Detectar si estamos en macOS
  static bool get _isMacOS => !kIsWeb && Platform.isMacOS;
  
  // Detectar si estamos en iOS
  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  // Mapa de caracteres especiales para codificación CP437 (IBM437)
  static const Map<String, int> _specialChars = {
    // Vocales con acentos
    'á': 0x85, 'é': 0x82, 'í': 0xA1, 'ó': 0xA2, 'ú': 0xA3,
    'ñ': 0xA4, 'ü': 0x81, 'Á': 0xB5, 'É': 0x90, 'Í': 0xD6,
    'Ó': 0xE0, 'Ú': 0xE9, 'Ñ': 0xA5, 'Ü': 0x9A,
    
    // Caracteres especiales españoles
    '¡': 0xAD, '¿': 0xA8, '°': 0xF8, '€': 0xEE,
    'ç': 0x87, 'Ç': 0x80, 'ß': 0xE1,
    
    // Otros caracteres especiales
    '©': 0x9F, '®': 0xAE, '™': 0x99,
    '¢': 0x9B, '£': 0x9C, '¥': 0x9D,
    '§': 0x15, '¶': 0x14, '†': 0x86, '‡': 0x87,
    '•': 0x07, '·': 0xFA, '¸': 0xFE,
    '¹': 0xBC, '²': 0xB2, '³': 0xB3,
    '¼': 0xBE, '½': 0xBD, '¾': 0xBF,
    '×': 0xD8, '÷': 0xF6,
    '±': 0xF1, '¬': 0xAA,
    '≤': 0xFB, '≥': 0xFC, '≠': 0xF0,
    '≈': 0xF7, '∞': 0xEC,
    '∫': 0xF2, '∑': 0xE6,
  };

  // Función para convertir texto a bytes compatibles con ESC/POS
  static List<int> _encodeTextForPrinter(String text) {
    List<int> bytes = [];
    
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      
      // Manejar saltos de línea
      if (char == '\n') {
        bytes.add(0x0A); // LF (Line Feed)
        bytes.add(0x0D); // CR (Carriage Return)
        continue;
      }
      
      // Manejar tabulaciones
      if (char == '\t') {
        bytes.add(0x09); // HT (Horizontal Tab)
        continue;
      }
      
      // Buscar caracteres especiales en el mapa
      if (_specialChars.containsKey(char)) {
        bytes.add(_specialChars[char]!);
        continue;
      }
      
      // Para caracteres ASCII estándar (0-127)
      int charCode = char.codeUnitAt(0);
      if (charCode >= 32 && charCode <= 126) {
        bytes.add(charCode);
        continue;
      }
      
      // Para caracteres no soportados, intentar mapeo alternativo
      String fallbackChar = _getFallbackChar(char);
      if (fallbackChar != char) {
        bytes.addAll(_encodeTextForPrinter(fallbackChar));
        continue;
      }
      
      // Si no se puede mapear, usar un espacio
      bytes.add(0x20);
    }
    
    return bytes;
  }

  // Función para obtener caracteres de respaldo para caracteres no soportados
  static String _getFallbackChar(String char) {
    // Mapeo de caracteres similares para casos no cubiertos
    const Map<String, String> fallbackMap = {
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
      'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u',
      'ã': 'a', 'õ': 'o',
      'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o',
      'å': 'a', 'æ': 'ae', 'œ': 'oe',
      'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U',
      'Â': 'A', 'Ê': 'E', 'Î': 'I', 'Ô': 'O', 'Û': 'U',
      'Ã': 'A', 'Õ': 'O',
      'Ä': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O',
      'Å': 'A', 'Æ': 'AE', 'Œ': 'OE',
      // Caracteres específicos de macOS
      '—': '-', '–': '-', '"': '"', '"': '"', ''': "'", ''': "'", '…': '...',
    };
    
    return fallbackMap[char] ?? char;
  }

  // Función para limpiar y normalizar el texto antes de imprimir
  static String _normalizeText(String text) {
    // Limpiar caracteres problemáticos específicos de Android
    if (_isAndroid) {
      // En Android, los caracteres especiales pueden venir codificados de manera diferente
      text = text.replaceAll(RegExp(r'\\n'), '\n'); // Convertir \n literal a salto real
      text = text.replaceAll(RegExp(r'\\t'), '\t'); // Convertir \t literal a tab real
      text = text.replaceAll(RegExp(r'\\r'), '\n'); // Convertir \r literal a salto real
      
      // Limpiar caracteres de escape adicionales que pueden venir de Android
      text = text.replaceAll(RegExp(r'\\'), ''); // Eliminar barras invertidas extra
      
      // Manejar caracteres específicos de Android que pueden causar problemas
      text = text.replaceAll('\\u00e1', 'á'); // á
      text = text.replaceAll('\\u00e9', 'é'); // é
      text = text.replaceAll('\\u00ed', 'í'); // í
      text = text.replaceAll('\\u00f3', 'ó'); // ó
      text = text.replaceAll('\\u00fa', 'ú'); // ú
      text = text.replaceAll('\\u00f1', 'ñ'); // ñ
      text = text.replaceAll('\\u00fc', 'ü'); // ü
      text = text.replaceAll('\\u00a1', '¡'); // ¡
      text = text.replaceAll('\\u00bf', '¿'); // ¿
    }
    
    // Limpiar caracteres problemáticos específicos de macOS
    if (_isMacOS) {
      // En macOS, los caracteres pueden venir con codificación UTF-8 nativa
      // pero las impresoras ESC/POS esperan CP437
      
      // Normalizar caracteres específicos de macOS
      text = text.replaceAll('—', '-'); // Em dash a guión normal
      text = text.replaceAll('–', '-'); // En dash a guión normal
      text = text.replaceAll('"', '"'); // Smart quotes a comillas normales
      text = text.replaceAll('"', '"'); // Smart quotes a comillas normales
      text = text.replaceAll(''', "'"); // Smart apostrophe a apóstrofe normal
      text = text.replaceAll(''', "'"); // Smart apostrophe a apóstrofe normal
      text = text.replaceAll('…', '...'); // Ellipsis a tres puntos
      
      // Manejar caracteres de control específicos de macOS
      text = text.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');
      
      // En macOS, los saltos de línea pueden venir como \r\n o \r
      text = text.replaceAll(RegExp(r'\r\n|\r'), '\n');
    }
    
    // Limpiar caracteres problemáticos específicos de iOS
    if (_isIOS) {
      // iOS puede tener comportamientos similares a macOS
      text = text.replaceAll('—', '-');
      text = text.replaceAll('–', '-');
      text = text.replaceAll('"', '"');
      text = text.replaceAll('"', '"');
      text = text.replaceAll(''', "'");
      text = text.replaceAll(''', "'");
      text = text.replaceAll('…', '...');
    }
    
    // Reemplazar múltiples espacios en blanco por uno solo
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Normalizar saltos de línea (Windows, Unix, Mac)
    text = text.replaceAll(RegExp(r'\r\n|\r|\n'), '\n');
    
    // Eliminar caracteres de control excepto \n y \t
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    return text.trim();
  }

  // Función para debug: mostrar información de codificación
  static void _debugEncoding(String originalText, String normalizedText, List<int> encodedBytes) {
    print('🔍 DEBUG CODIFICACIÓN:');
    print('📝 Texto original: "$originalText"');
    print('📝 Texto normalizado: "$normalizedText"');
    print('📝 Bytes codificados: ${encodedBytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    print('📝 Longitud original: ${originalText.length}, normalizada: ${normalizedText.length}, bytes: ${encodedBytes.length}');
    
    // Mostrar caracteres problemáticos
    for (int i = 0; i < originalText.length; i++) {
      String char = originalText[i];
      int charCode = char.codeUnitAt(0);
      if (charCode > 127 || char == '\n' || char == '\t') {
        print('🔤 Carácter especial [$i]: "$char" (código: $charCode, hex: 0x${charCode.toRadixString(16)})');
      }
    }
    
    // Mostrar información específica de plataforma
    if (_isMacOS) {
      print('🍎 macOS detectado - usando normalización específica');
    } else if (_isAndroid) {
      print('🤖 Android detectado - usando normalización específica');
    } else if (_isIOS) {
      print('📱 iOS detectado - usando normalización específica');
    }
  }

  static Future<bool> printToNetworkPrinter(
    String content,
    String title, {
    Function(bool success)? onPrinted,
  }) async {
    // Esta función ya no se usa directamente, se debe usar printToNetworkPrinterWithIP
    // con una IP específica obtenida de la configuración
    throw UnimplementedError('Use printToNetworkPrinterWithIP with specific IP');
  }

  static Future<bool> printToNetworkPrinterWithIP(
    String content,
    String title,
    String ip, {
    Function(bool success)? onPrinted,
    int copyNumber = 1,
    int totalCopies = 1,
  }) async {
    try {
      print('🖨️ Conectando a impresora en $ip:$printerPort');
      print('🌐 Plataforma detectada: ${_isAndroid ? 'Android' : _isMacOS ? 'macOS' : _isIOS ? 'iOS' : 'Otro'}');

      // Crear socket para conectar a la impresora
      final socket = await Socket.connect(
        ip,
        printerPort,
        timeout: const Duration(seconds: 10),
      );

      print('✅ Conexión establecida con la impresora $ip');

      // Normalizar el contenido antes de procesar
      final String normalizedContent = _normalizeText(content);
      final String normalizedTitle = _normalizeText(title);

      // Preparar comandos ESC/POS para la impresora
      final List<int> commands = [];

      // Inicializar impresora
      commands.addAll([0x1B, 0x40]); // ESC @ - Initialize printer

      // Centrar texto
      commands.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment

      // Título en negrita
      commands.addAll([0x1B, 0x45, 0x01]); // ESC E 1 - Bold on
      final List<int> titleBytes = _encodeTextForPrinter('$normalizedTitle\n');
      commands.addAll(titleBytes);
      commands.addAll([0x1B, 0x45, 0x00]); // ESC E 0 - Bold off

      // Información de copias si hay más de una
      if (totalCopies > 1) {
        commands.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment
        commands.addAll(_encodeTextForPrinter('Copia $copyNumber de $totalCopies\n'));
      }

      // Fecha
      commands.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment
      final String currentDate = DateTime.now().toString().split('.')[0]; // Sin milisegundos
      commands.addAll(_encodeTextForPrinter('Fecha: $currentDate\n'));
      commands.addAll(_encodeTextForPrinter('Impreso desde Flutter WebView\n'));
      commands.addAll(_encodeTextForPrinter('Impresora: $ip\n'));

      // Línea separadora arriba
      commands.addAll(_encodeTextForPrinter('${'=' * 30}\n'));

      // Contenido principal (textarea)
      if (normalizedContent.isNotEmpty) {
        final List<int> contentBytes = _encodeTextForPrinter('$normalizedContent\n');
        commands.addAll(contentBytes);
        
        // Debug de codificación para el contenido principal
        _debugEncoding(content, normalizedContent, contentBytes);
      }

      // Línea separadora abajo
      commands.addAll(_encodeTextForPrinter('${'=' * 30}\n'));

      // Finalizar documento
      commands.addAll([0x0C]); // Form feed

      // Enviar comandos a la impresora
      socket.add(commands);
      await socket.flush();

      // Cerrar conexión
      await socket.close();

      print('✅ Documento enviado exitosamente a la impresora $ip');
      print('📝 Contenido normalizado enviado: "$normalizedContent"');
      print('📊 Total de bytes enviados: ${commands.length}');
      if (onPrinted != null) onPrinted(true);
      return true;
    } catch (e) {
      print('❌ Error al conectar con la impresora $ip: $e');
      if (onPrinted != null) onPrinted(false);
      return false;
    }
  }

  static Future<bool> testConnection(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } catch (e) {
      print('❌ No se puede conectar a la impresora $ip: $e');
      return false;
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impresor Flutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isPrinting = false; // Control para evitar impresiones múltiples
  DateTime? _lastPrintTime; // Control de tiempo entre impresiones

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                _injectPrintInterceptor();
              },
            ),
          )
          ..addJavaScriptChannel(
            'PrintInterceptor',
            onMessageReceived: (JavaScriptMessage message) {
              print('🎯 BOTÓN DE IMPRIMIR INTERCEPTADO: ${message.message}');
              print('📄 Iniciando proceso de impresión...');
              print('🖨️  Preparando documento para impresión...');
              print('✅ Impresión completada (simulada)');
            },
          )
          ..addJavaScriptChannel(
            'NativePrinter',
            onMessageReceived: (JavaScriptMessage message) {
              print(
                '🖨️ Llamada a impresión nativa recibida: ${message.message}',
              );
              _handleNativePrint(message.message);
            },
          )
          ..addJavaScriptChannel(
            'DirectPrint',
            onMessageReceived: (JavaScriptMessage message) {
              print(
                '🖨️ Llamada directa a impresión recibida: ${message.message}',
              );
              _handleDirectPrint(message.message);
            },
          )
          ..loadRequest(Uri.parse('https://print-web.vercel.app/'));
  }

  void _injectPrintInterceptor() {
    const String script = '''
      (function() {
        // Interceptar el botón de imprimir específico
        function interceptPrintButton() {
          // Buscar el botón específico por ID
          const printButton = document.getElementById('printBtn');
          
          if (printButton) {
            console.log('🔍 Botón de imprimir encontrado:', printButton);
            
            // Verificar si ya está interceptado
            if (printButton.hasAttribute('data-intercepted')) {
              console.log('✅ Botón ya interceptado, saltando...');
              return;
            }
            
            // Marcar como interceptado
            printButton.setAttribute('data-intercepted', 'true');
            
            // Guardar el onclick original
            const originalOnClick = printButton.onclick;
            const originalOnClickAttr = printButton.getAttribute('onclick');
            
            // Interceptar el clic
            printButton.addEventListener('click', function(e) {
              e.preventDefault();
              e.stopPropagation();
              
              console.log('🎯 Clic en botón de imprimir (printBtn) interceptado!');
              
              // Enviar mensaje a Flutter
              PrintInterceptor.postMessage('Botón printBtn clickeado - ' + new Date().toLocaleString());
              
              // Llamar a la impresión nativa
              callNativePrint();
              
              // Ejecutar la función original si existe
              if (originalOnClick) {
                originalOnClick.call(this, e);
              } else if (originalOnClickAttr) {
                try {
                  eval(originalOnClickAttr);
                } catch (error) {
                  console.log('Error ejecutando onclick original:', error);
                }
              }
              
              return false;
            }, true);
            
            console.log('✅ Interceptor de impresión instalado en printBtn');
          } else {
            console.log('⚠️ Botón con ID "printBtn" no encontrado');
            
            // Fallback: buscar por otros métodos si no encuentra el ID específico
            const fallbackSelectors = [
              'button[onclick*="print"]',
              'button:contains("Imprimir")',
              'button:contains("Print")',
              '.print-button',
              '#print-button',
              '[data-print]'
            ];
            
            for (let selector of fallbackSelectors) {
              try {
                const fallbackButton = document.querySelector(selector);
                if (fallbackButton && !fallbackButton.hasAttribute('data-intercepted')) {
                  console.log('🔍 Botón de imprimir encontrado por fallback:', fallbackButton);
                  
                  // Marcar como interceptado
                  fallbackButton.setAttribute('data-intercepted', 'true');
                  
                  const originalOnClick = fallbackButton.onclick;
                  const originalOnClickAttr = fallbackButton.getAttribute('onclick');
                  
                  fallbackButton.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    console.log('🎯 Clic en botón de imprimir (fallback) interceptado!');
                    PrintInterceptor.postMessage('Botón de imprimir (fallback) clickeado - ' + new Date().toLocaleString());
                    
                    // Llamar a la impresión nativa
                    callNativePrint();
                    
                    if (originalOnClick) {
                      originalOnClick.call(this, e);
                    } else if (originalOnClickAttr) {
                      try {
                        eval(originalOnClickAttr);
                      } catch (error) {
                        console.log('Error ejecutando onclick original:', error);
                      }
                    }
                    
                    return false;
                  }, true);
                  
                  console.log('✅ Interceptor de impresión instalado por fallback');
                  break;
                }
              } catch (e) {
                console.log('Selector fallback no válido:', selector);
              }
            }
          }
        }
        
        // Función para llamar a la impresión nativa
        function callNativePrint() {
          try {
            // Obtener el contenido actual del textarea
            const textarea = document.getElementById('textInput');
            let textContent = '';
            
            if (textarea) {
              textContent = textarea.value || textarea.textContent || '';
              console.log('📝 Contenido del textarea capturado:', textContent);
            }
            
            // Obtener el contenido HTML de la página
            const pageContent = document.documentElement.outerHTML;
            const pageTitle = document.title || 'Documento';
            const printData = {
              html: pageContent,
              title: pageTitle,
              url: window.location.href,
              timestamp: new Date().toISOString(),
              textContent: textContent // Agregar el contenido del textarea
            };
            
            console.log('🖨️ Enviando datos para impresión nativa:', printData);
            NativePrinter.postMessage(JSON.stringify(printData));
          } catch (error) {
            console.error('Error al preparar datos para impresión nativa:', error);
          }
        }
        
        // Función para llamar directamente a la impresión (sin confirmación)
        function callDirectPrint(content, title) {
          try {
            const printData = {
              content: content || '',
              title: title || 'Documento',
              url: window.location.href,
              timestamp: new Date().toISOString(),
              source: 'WebView'
            };
            
            console.log('🖨️ Enviando datos para impresión directa desde WebView:', printData);
            DirectPrint.postMessage(JSON.stringify(printData));
          } catch (error) {
            console.error('Error al preparar datos para impresión directa:', error);
          }
        }
        
        // Función para imprimir el contenido del textarea directamente
        function printTextareaContent() {
          const textarea = document.getElementById('textInput');
          if (textarea) {
            const content = textarea.value || textarea.textContent || '';
            const title = document.title || 'Impresor de Texto';
            callDirectPrint(content, title);
          } else {
            console.error('Textarea no encontrado');
          }
        }
        
        // Detectar si estamos en WebView
        function detectWebView() {
          const isWebView = window.navigator.userAgent.includes('WebView') || 
                           window.navigator.userAgent.includes('Flutter') ||
                           typeof PrintInterceptor !== 'undefined' ||
                           typeof NativePrinter !== 'undefined' ||
                           typeof DirectPrint !== 'undefined';
          
          if (isWebView) {
            console.log('🌐 Detectado: Ejecutando en WebView de Flutter');
            document.body.classList.add('webview-mode');
            
            // Agregar indicador visual de WebView
            const webviewIndicator = document.createElement('div');
            webviewIndicator.id = 'webview-indicator';
            webviewIndicator.innerHTML = '🌐 WebView Mode';
            webviewIndicator.style.cssText = `
              position: fixed;
              top: 10px;
              right: 10px;
              background: #667eea;
              color: white;
              padding: 4px 8px;
              border-radius: 4px;
              font-size: 12px;
              z-index: 1000;
              pointer-events: none;
            `;
            document.body.appendChild(webviewIndicator);
          } else {
            console.log('🌐 No detectado: Ejecutando en navegador normal');
          }
          
          return isWebView;
        }
        
        // Ejecutar detección de WebView
        detectWebView();
        
        // Interceptar window.print() también
        const originalPrint = window.print;
        window.print = function() {
          console.log('🎯 window.print() interceptado!');
          PrintInterceptor.postMessage('window.print() llamado - ' + new Date().toLocaleString());
          
          // Llamar a la impresión nativa
          callNativePrint();
          
          return originalPrint.apply(this, arguments);
        };
        
        // Ejecutar inmediatamente
        interceptPrintButton();
        
        // También ejecutar después de un pequeño delay por si el contenido se carga dinámicamente
        setTimeout(interceptPrintButton, 1000);
        setTimeout(interceptPrintButton, 3000);
        
        console.log('🚀 Interceptor de impresión inicializado para printBtn');
      })();
    ''';

    _controller.runJavaScript(script);
  }

  Future<void> _handleNativePrint(String message) async {
    try {
      // Verificar si se puede imprimir
      if (!await _canPrint()) {
        return;
      }

      // Marcar como imprimiendo
      await _setPrintingStatus(true);

      final Map<String, dynamic> printData = json.decode(message);
      final String title = printData['title'] ?? 'Documento';
      final String url = printData['url'] ?? '';
      final String textContent = printData['textContent'] ?? '';

      // Obtener información del WebView
      final bool isWebView = await _isWebViewMode();
      final Map<String, dynamic> webViewInfo = await _getWebViewInfo();

      // Obtener configuración de impresoras
      final List<Map<String, dynamic>> printers = await _getPrintersConfig();

      print('🖨️ Procesando impresión nativa para: $title');
      print('📝 Contenido del textarea recibido: "$textContent"');
      print('🌐 Detectado: Impresión desde WebView (URL: $url)');
      print('🌐 Modo WebView: $isWebView');
      print('🌐 Info WebView: $webViewInfo');
      print('🖨️ Impresoras configuradas: $printers');

      // Obtener el contenido actual del textarea en tiempo real
      final String currentTextContent = await _getTextareaContent();
      final String finalContent =
          currentTextContent.isNotEmpty ? currentTextContent : textContent;

      print('📝 Contenido final a imprimir: "$finalContent"');

      if(!mounted) return;
      // Si no hay contenido, mostrar advertencia y salir
      if (finalContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ No hay contenido para imprimir. Escribe algo en el textarea.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        await _setPrintingStatus(false);
        return;
      }

      // Si viene desde WebView, imprimir directamente sin diálogo
      if (isWebView) {
        print(
          '🌐 Imprimiendo directamente desde WebView sin diálogo de confirmación',
        );

        if(!mounted) return;
        // Mostrar notificación de que se está imprimiendo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.web, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Imprimiendo desde WebView: $title')),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );

        // Usar configuración de impresoras múltiples
        await _printToMultiplePrinters(finalContent, title);

        // Notificar a la web para actualizar el historial
        await _notifyWebPrintHistory(finalContent);

        // Limpiar el textarea después de la impresión exitosa
        await _clearTextarea();

        // Forzar actualización visual
        await _forceTextareaUpdate();

        // Marcar como no imprimiendo
        await _setPrintingStatus(false);

        return;
      }

      // Solo mostrar diálogo si NO viene desde WebView (caso de uso nativo)
      final bool? shouldPrint = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.web, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Confirmar Impresión desde WebView'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Desea imprimir "$title"?'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌐 Origen: WebView de Flutter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text('URL: $url', style: const TextStyle(fontSize: 12)),
                      Text(
                        'User Agent: ${webViewInfo['userAgent'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Impresora: 192.168.1.13:9100',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (printers.isNotEmpty) ...[
                        const Text(
                          '🖨️ Impresoras configuradas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        ...printers.map(
                          (printer) => Text(
                            '  • ${printer['ip']} - ${printer['copies']} copia(s)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          '🖨️ Usando impresora por defecto: 192.168.1.13:9100',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contenido a imprimir:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    finalContent,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.print),
                label: const Text('Imprimir desde WebView'),
              ),
            ],
          );
        },
      );

      if (shouldPrint == true) {
        if(!mounted) return;
        // Cerrar el diálogo de confirmación
        Navigator.of(context).pop();

        // Probar conexión con la impresora
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Probando conexión con impresora...'),
            backgroundColor: Colors.blue,
          ),
        );

        // Obtener configuración de impresoras para la prueba de conexión
        final List<Map<String, dynamic>> printers = await _getPrintersConfig();
        String testIP = '192.168.1.13'; // IP por defecto
        
        if (printers.isNotEmpty) {
          testIP = printers[0]['ip'];
        }
        
        final bool isConnected = await NetworkPrinter.testConnection(testIP);

        if (!isConnected) {
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se puede conectar a la impresora. Verifique la IP y el puerto.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          await _setPrintingStatus(false);
          return;
        }

        if(!mounted) return;
        // Enviar documento a la impresora
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviando documento a impresora...'),
            backgroundColor: Colors.blue,
          ),
        );

        // Usar configuración de impresoras múltiples
        await _printToMultiplePrinters(finalContent, title);

        // Notificar a la web para actualizar el historial
        await _notifyWebPrintHistory(finalContent);

        // Limpiar el textarea después de la impresión exitosa
        await _clearTextarea();

        // Forzar actualización visual
        await _forceTextareaUpdate();

        // Marcar como no imprimiendo
        await _setPrintingStatus(false);
      } else {
        print('❌ Impresión cancelada por el usuario');
        await _setPrintingStatus(false);
      }
    } catch (e) {
      print('❌ Error al procesar impresión nativa: $e');
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar impresión: $e'),
          backgroundColor: Colors.red,
        ),
      );
      await _setPrintingStatus(false);
    }
  }

  Future<void> _handleDirectPrint(String message) async {
    try {
      // Verificar si se puede imprimir
      if (!await _canPrint()) {
        return;
      }

      // Marcar como imprimiendo
      await _setPrintingStatus(true);

      final Map<String, dynamic> printData = json.decode(message);
      final String content = printData['content'] ?? '';
      final String title = printData['title'] ?? 'Documento';
      final String url = printData['url'] ?? 'WebView';

      print('🖨️ Procesando impresión directa para: $title');
      print('📝 Contenido a imprimir: "$content"');
      print('🌐 Detectado: Impresión directa desde WebView (URL: $url)');

      // Si no hay contenido, mostrar advertencia y salir
      if (content.isEmpty) {
        print('⚠️ No hay contenido para imprimir');
        await _setPrintingStatus(false);
        return;
      }

      if(!mounted) return;
      // Mostrar notificación de que se está imprimiendo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.web, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Imprimiendo desde WebView: $title')),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Enviar directamente a la impresora sin confirmación
      await _printToMultiplePrinters(content, title);

      // Notificar a la web para actualizar el historial
      await _notifyWebPrintHistory(content);

      // Limpiar el textarea después de la impresión exitosa
      await _clearTextarea();

      // Forzar actualización visual
      await _forceTextareaUpdate();

      // Marcar como no imprimiendo
      await _setPrintingStatus(false);
    } catch (e) {
      print('❌ Error al procesar impresión directa desde WebView: $e');
      await _setPrintingStatus(false);
    }
  }

  // Método para extraer texto del textarea del HTML
  String _extractTextFromHTML(String html) {
    try {
      print('🔍 Extrayendo texto del HTML...');

      // Buscar el contenido del textarea por ID específico con diferentes patrones
      final List<RegExp> textareaPatterns = [
        // Patrón 1: textarea con contenido entre tags
        RegExp(
          r'<textarea[^>]*id="textInput"[^>]*>(.*?)</textarea>',
          dotAll: true,
        ),
        // Patrón 2: textarea con valor en atributo value
        RegExp(
          r'<textarea[^>]*id="textInput"[^>]*value="([^"]*)"[^>]*>',
          dotAll: true,
        ),
        // Patrón 3: textarea con cualquier atributo que contenga el contenido
        RegExp(
          r'<textarea[^>]*id="textInput"[^>]*>([^<]*)</textarea>',
          dotAll: true,
        ),
      ];

      for (final pattern in textareaPatterns) {
        final match = pattern.firstMatch(html);
        if (match != null && match.group(1) != null) {
          final String extractedText = match.group(1)!.trim();
          if (extractedText.isNotEmpty) {
            print(
              '📝 Texto extraído del textarea (patrón ${textareaPatterns.indexOf(pattern) + 1}): "$extractedText"',
            );
            return extractedText;
          }
        }
      }

      // Si no encuentra el textarea con contenido, buscar el elemento vacío
      final RegExp emptyTextareaRegex = RegExp(
        r'<textarea[^>]*id="textInput"[^>]*></textarea>',
        dotAll: true,
      );
      if (emptyTextareaRegex.hasMatch(html)) {
        print('📝 Textarea encontrado pero está vacío');
        return '';
      }

      // Fallback: buscar contenido en el historial de impresiones
      final RegExp historyRegex = RegExp(
        r'<div class="print-preview">(.*?)</div>',
        dotAll: true,
      );
      final matches = historyRegex.allMatches(html);

      if (matches.isNotEmpty) {
        final String historyText = matches
            .map((m) => m.group(1)?.trim() ?? '')
            .where((text) => text.isNotEmpty)
            .join('\n');
        if (historyText.isNotEmpty) {
          print('📝 Texto extraído del historial: "$historyText"');
          return historyText;
        }
      }

      // Último fallback: buscar cualquier contenido de texto en la página
      final RegExp anyTextRegex = RegExp(r'>([^<>]{10,})<', dotAll: true);
      final textMatches = anyTextRegex.allMatches(html);

      if (textMatches.isNotEmpty) {
        final String anyText = textMatches
            .map((m) => m.group(1)?.trim() ?? '')
            .where((text) => text.isNotEmpty && text.length > 10)
            .take(3) // Tomar solo los primeros 3 textos más largos
            .join('\n');
        if (anyText.isNotEmpty) {
          print('📝 Texto extraído como fallback: "$anyText"');
          return anyText;
        }
      }

      print('⚠️ No se encontró contenido para extraer');
      return '';
    } catch (e) {
      print('❌ Error al extraer texto del HTML: $e');
      return '';
    }
  }

  // Método para obtener el contenido del textarea ejecutando JavaScript
  Future<String> _getTextareaContent() async {
    try {
      final String script = '''
        (function() {
          const textarea = document.getElementById('textInput');
          if (textarea) {
            return textarea.value || textarea.textContent || '';
          }
          return '';
        })();
      ''';

      final String result =
          await _controller.runJavaScriptReturningResult(script) as String;
      print('📝 Contenido del textarea obtenido via JavaScript: "$result"');
      return result;
    } catch (e) {
      print('❌ Error al obtener contenido del textarea: $e');
      return '';
    }
  }

  Future<void> _notifyWebPrintHistory(String text) async {
    // Primero verificar si la función addPrintHistory existe
    final bool hasAddPrintHistory = await _checkAddPrintHistoryFunction();

    if (hasAddPrintHistory) {
      // Si existe la función, usarla
      final String js = '''
        (function() {
          try {
            // Intentar llamar a la función addPrintHistory en el contexto actual
            if (typeof addPrintHistory === 'function') {
              addPrintHistory("${text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}");
              console.log('✅ Historial actualizado desde Flutter');
              return true;
            }
            
            // Intentar en window
            if (window && typeof window.addPrintHistory === 'function') {
              window.addPrintHistory("${text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}");
              console.log('✅ Historial actualizado desde Flutter (window)');
              return true;
            }
            
            // Intentar en window.parent
            if (window && window.parent && typeof window.parent.addPrintHistory === 'function') {
              window.parent.addPrintHistory("${text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}");
              console.log('✅ Historial actualizado desde Flutter (window.parent)');
              return true;
            }
            
            return false;
          } catch (error) {
            console.error('Error actualizando historial:', error);
            return false;
          }
        })();
      ''';

      try {
        final result = await _controller.runJavaScriptReturningResult(js);
        print(
          '📝 Notificado a la web para agregar al historial de impresiones: $result',
        );
        if (result == true) {
          return; // Si funcionó, salir
        }
      } catch (e) {
        print('❌ Error notificando a la web: $e');
      }
    }

    // Si no existe la función o falló, crear el historial manualmente
    await _createManualPrintHistory(text);
  }

  Future<bool> _checkAddPrintHistoryFunction() async {
    final String js = '''
      (function() {
        return typeof addPrintHistory === 'function' || 
               (window && typeof window.addPrintHistory === 'function') ||
               (window && window.parent && typeof window.parent.addPrintHistory === 'function');
      })();
    ''';

    try {
      final result = await _controller.runJavaScriptReturningResult(js);
      return result == true;
    } catch (e) {
      print('❌ Error verificando función addPrintHistory: $e');
      return false;
    }
  }

  Future<void> _createManualPrintHistory(String text) async {
    final String js = '''
      (function() {
        try {
          console.log('⚠️ Función addPrintHistory no encontrada, creando historial manualmente...');
          
          // Buscar el contenedor del historial
          const historyContainer = document.getElementById('printHistory');
          if (historyContainer) {
            const timestamp = new Date().toLocaleString();
            const historyItem = document.createElement('div');
            historyItem.className = 'print-item';
            historyItem.innerHTML = 
              '<div class="print-header">' +
                '<span class="print-time">' + timestamp + '</span>' +
                '<span class="print-status success">Exitoso</span>' +
              '</div>' +
              '<div class="print-content">' +
                '<strong>Texto impreso:</strong>' +
                '<div class="print-preview">' + "${text.replaceAll('"', '&quot;').replaceAll('\n', '<br>')}" + '</div>' +
              '</div>';
            
            // Insertar al principio del historial
            historyContainer.insertBefore(historyItem, historyContainer.firstChild);
            console.log('✅ Historial actualizado manualmente desde Flutter');
            return true;
          }
          
          console.log('❌ No se pudo actualizar el historial - contenedor no encontrado');
          return false;
        } catch (error) {
          console.error('Error actualizando historial manualmente:', error);
          return false;
        }
      })();
    ''';

    try {
      final result = await _controller.runJavaScriptReturningResult(js);
      print('📝 Historial creado manualmente: $result');
    } catch (e) {
      print('❌ Error creando historial manualmente: $e');
    }
  }

  Future<void> _clearTextarea() async {
    try {
      // Método simple y directo
      final String script = '''
        (function() {
          const textarea = document.getElementById('textInput');
          if (textarea) {
            // Limpiar el contenido
            textarea.value = '';
            
            // Disparar eventos para notificar cambios
            textarea.dispatchEvent(new Event('input'));
            textarea.dispatchEvent(new Event('change'));
            
            console.log('✅ Textarea limpiado exitosamente');
            return true;
          }
          return false;
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('📝 Textarea limpiado exitosamente: $result');

      // Esperar un momento y verificar
      await Future.delayed(const Duration(milliseconds: 500));
      await _verifyTextareaCleared();
    } catch (e) {
      print('❌ Error al limpiar el textarea: $e');
    }
  }

  Future<bool> _verifyTextareaCleared() async {
    try {
      final String script = '''
        (function() {
          const textarea = document.getElementById('textInput');
          if (textarea) {
            const value = textarea.value || '';
            const textContent = textarea.textContent || '';
            console.log('🔍 Verificación - value:', value, 'textContent:', textContent);
            return value === '' && textContent === '';
          }
          return false;
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('🔍 Verificación de limpieza del textarea: $result');
      return result == true;
    } catch (e) {
      print('❌ Error verificando limpieza del textarea: $e');
      return false;
    }
  }

  Future<void> _forceTextareaUpdate() async {
    try {
      final String script = '''
        (function() {
          const textarea = document.getElementById('textInput');
          if (textarea) {
            // Forzar actualización visual
            textarea.focus();
            textarea.blur();
            
            console.log('✅ Textarea forzado actualizado exitosamente');
            return true;
          } else {
            console.log('❌ Textarea no encontrado');
            return false;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      print('📝 Textarea forzado actualizado exitosamente: $result');
    } catch (e) {
      print('❌ Error al forzar actualización del textarea: $e');
    }
  }

  Future<bool> _isWebViewMode() async {
    try {
      final String script = '''
        (function() {
          return typeof PrintInterceptor !== 'undefined' || 
                 typeof NativePrinter !== 'undefined' || 
                 typeof DirectPrint !== 'undefined' ||
                 window.navigator.userAgent.includes('WebView') ||
                 window.navigator.userAgent.includes('Flutter');
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      return result == true;
    } catch (e) {
      print('❌ Error detectando modo WebView: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _getWebViewInfo() async {
    try {
      final String script = '''
        (function() {
          const info = {
            userAgent: window.navigator.userAgent,
            url: window.location.href,
            title: document.title,
            hasPrintInterceptor: typeof PrintInterceptor !== 'undefined',
            hasNativePrinter: typeof NativePrinter !== 'undefined',
            hasDirectPrint: typeof DirectPrint !== 'undefined',
            isWebView: window.navigator.userAgent.includes('WebView') || 
                      window.navigator.userAgent.includes('Flutter')
          };
          return JSON.stringify(info);
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      if (result is String) {
        return json.decode(result);
      }
      return {};
    } catch (e) {
      print('❌ Error obteniendo información del WebView: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getPrintersConfig() async {
    try {
      final String script = '''
        (function() {
          const printers = [];
          const printerRows = document.querySelectorAll('.printer-row');
          
          printerRows.forEach(function(row) {
            const ipInput = row.querySelector('.printer-ip');
            const copiesInput = row.querySelector('.printer-copies');
            
            if (ipInput && copiesInput) {
              const ip = ipInput.value.trim();
              const copies = parseInt(copiesInput.value) || 1;
              
              if (ip) {
                printers.push({
                  ip: ip,
                  copies: copies
                });
              }
            }
          });
          
          console.log('🖨️ Configuración de impresoras detectada:', printers);
          return JSON.stringify(printers);
        })();
      ''';

      final result =
          await _controller.runJavaScriptReturningResult(script) as String;
      final List<dynamic> printersList = json.decode(result);

      return printersList.map((printer) {
        return {
          'ip': printer['ip'] as String,
          'copies': printer['copies'] as int,
        };
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo configuración de impresoras: $e');
      return [];
    }
  }

  Future<void> _printToMultiplePrinters(String content, String title) async {
    try {
      final List<Map<String, dynamic>> printers = await _getPrintersConfig();

      if (printers.isEmpty) {
        print(
          '⚠️ No se encontraron impresoras configuradas, usando impresora por defecto',
        );
        // Usar impresora por defecto (IP local común)
        const String defaultIP = '192.168.1.13';
        await NetworkPrinter.printToNetworkPrinterWithIP(
          content,
          title,
          defaultIP,
          copyNumber: 1,
          totalCopies: 1,
        );
        return;
      }

      print(
        '🖨️ Imprimiendo en ${printers.length} impresora(s) configurada(s)',
      );

      int successCount = 0;
      int totalCopies = 0;

      for (final printer in printers) {
        final String ip = printer['ip'];
        final int copies = printer['copies'];

        print('🖨️ Imprimiendo en $ip - $copies copia(s)');

        // Imprimir las copias especificadas
        for (int i = 0; i < copies; i++) {
          final bool success = await NetworkPrinter.printToNetworkPrinterWithIP(
            content,
            title,
            ip,
            copyNumber: i + 1,
            totalCopies: copies,
          );

          if (success) {
            successCount++;
            totalCopies++;
            print('✅ Copia ${i + 1} de $copies impresa exitosamente en $ip');
          } else {
            print('❌ Error imprimiendo copia ${i + 1} de $copies en $ip');
          }

          // Pequeña pausa entre copias
          if (i < copies - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      print(
        '📊 Resumen: $successCount copias impresas exitosamente de $totalCopies total',
      );

      if(!mounted) return;
      // Mostrar notificación de resumen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Impresión completada: $successCount copias en ${printers.length} impresora(s)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Error en impresión múltiple: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error en impresión múltiple: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _canPrint() async {
    // Evitar impresiones múltiples simultáneas
    if (_isPrinting) {
      print('⚠️ Impresión en progreso, ignorando nueva solicitud');
      return false;
    }

    // Evitar impresiones muy rápidas (más de una por segundo)
    if (_lastPrintTime != null) {
      final timeDiff = DateTime.now().difference(_lastPrintTime!);
      if (timeDiff.inMilliseconds < 1000) {
        print(
          '⚠️ Impresión muy reciente (${timeDiff.inMilliseconds}ms), ignorando',
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _setPrintingStatus(bool isPrinting) async {
    _isPrinting = isPrinting;
    if (isPrinting) {
      _lastPrintTime = DateTime.now();
    }
  }

  void safeUseContext(void Function(BuildContext context) action) {
    if (!mounted) return;
    action(context);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(
        child: Text('WebView no es compatible con Flutter Web.'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impresor WebView'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              // Obtener configuración de impresoras
              final List<Map<String, dynamic>> printers = await _getPrintersConfig();
              String testIP = '192.168.1.13'; // IP por defecto
              
              if (printers.isNotEmpty) {
                testIP = printers[0]['ip'];
              }
              
              final bool isConnected = await NetworkPrinter.testConnection(testIP);
              if(!mounted) return;
              safeUseContext((ctx){
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      isConnected
                          ? '✅ Conexión exitosa con impresora $testIP:9100'
                          : '❌ No se puede conectar a la impresora $testIP:9100',
                    ),
                    backgroundColor: isConnected ? Colors.green : Colors.red,
                  ),
                );
              });
            },
            tooltip: 'Probar conexión con impresora',
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
