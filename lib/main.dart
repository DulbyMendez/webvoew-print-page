import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

// Clase para manejar la conexión con impresoras de red
class NetworkPrinter {
  static const String printerIP = '192.168.1.13';
  static const int printerPort =
      9100; // Puerto estándar para impresoras ESC/POS

  static Future<bool> printToNetworkPrinter(
    String content,
    String title, {
    Function(bool success)? onPrinted,
  }) async {
    try {
      print('🖨️ Conectando a impresora en $printerIP:$printerPort');

      // Crear socket para conectar a la impresora
      final socket = await Socket.connect(
        printerIP,
        printerPort,
        timeout: const Duration(seconds: 10),
      );

      print('✅ Conexión establecida con la impresora');

      // Preparar comandos ESC/POS para la impresora
      final List<int> commands = [];

      // Inicializar impresora
      commands.addAll([0x1B, 0x40]); // ESC @ - Initialize printer

      // Centrar texto
      commands.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment

      // Título en negrita
      commands.addAll([0x1B, 0x45, 0x01]); // ESC E 1 - Bold on
      commands.addAll(utf8.encode('$title\n'));
      commands.addAll([0x1B, 0x45, 0x00]); // ESC E 0 - Bold off

      // Fecha
      commands.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment
      commands.addAll(utf8.encode('Fecha: ${DateTime.now().toString()}\n'));
      commands.addAll(utf8.encode('Impreso desde Flutter WebView\n'));

      // Línea separadora arriba
      commands.addAll(utf8.encode('${'=' * 30}\n'));

      // Contenido principal (textarea)
      if (content.isNotEmpty) {
        commands.addAll(utf8.encode(content + '\n'));
      }

      // Línea separadora abajo
      commands.addAll(utf8.encode('${'=' * 30}\n'));

      // Finalizar documento
      commands.addAll([0x0C]); // Form feed

      // Enviar comandos a la impresora
      socket.add(commands);
      await socket.flush();

      // Cerrar conexión
      await socket.close();

      print('✅ Documento enviado exitosamente a la impresora');
      if (onPrinted != null) onPrinted(true);
      return true;
    } catch (e) {
      print('❌ Error al conectar con la impresora: $e');
      if (onPrinted != null) onPrinted(false);
      return false;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final socket = await Socket.connect(
        printerIP,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } catch (e) {
      print('❌ No se puede conectar a la impresora: $e');
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
                if (fallbackButton) {
                  console.log('🔍 Botón de imprimir encontrado por fallback:', fallbackButton);
                  
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
              timestamp: new Date().toISOString()
            };
            
            console.log('🖨️ Enviando datos para impresión directa:', printData);
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
      final Map<String, dynamic> printData = json.decode(message);
      final String html = printData['html'] ?? '';
      final String title = printData['title'] ?? 'Documento';
      final String url = printData['url'] ?? '';
      final String textContent = printData['textContent'] ?? '';

      print('🖨️ Procesando impresión nativa para: $title');
      print('📝 Contenido del textarea recibido: "$textContent"');

      // Obtener el contenido actual del textarea en tiempo real
      final String currentTextContent = await _getTextareaContent();
      final String finalContent =
          currentTextContent.isNotEmpty ? currentTextContent : textContent;

      print('📝 Contenido final a imprimir: "$finalContent"');

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
        return;
      }

      // Mostrar diálogo de confirmación de impresión
      final bool? shouldPrint = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar Impresión'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Desea imprimir "$title"?'),
                const SizedBox(height: 8),
                const Text(
                  'Impresora: 192.168.1.13:9100',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                label: const Text('Imprimir'),
              ),
            ],
          );
        },
      );

      if (shouldPrint == true) {
        // Cerrar el diálogo de confirmación
        Navigator.of(context).pop();

        // Probar conexión con la impresora
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Probando conexión con impresora...'),
            backgroundColor: Colors.blue,
          ),
        );

        final bool isConnected = await NetworkPrinter.testConnection();

        if (!isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se puede conectar a la impresora. Verifique la IP y el puerto.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Enviar documento a la impresora
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviando documento a impresora...'),
            backgroundColor: Colors.blue,
          ),
        );

        final bool printSuccess = await NetworkPrinter.printToNetworkPrinter(
          finalContent,
          title,
        );

        if (printSuccess) {
          print('✅ Documento impreso exitosamente en la impresora de red');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento enviado a impresora exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Notificar a la web para actualizar el historial
          await _notifyWebPrintHistory(finalContent);

          // Limpiar el textarea después de la impresión exitosa
          await _clearTextarea();

          // Forzar actualización visual
          await _forceTextareaUpdate();
        } else {
          print('❌ Error al imprimir en la impresora de red');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar documento a la impresora'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ Impresión cancelada por el usuario');
      }
    } catch (e) {
      print('❌ Error al procesar impresión nativa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar impresión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDirectPrint(String message) async {
    try {
      final Map<String, dynamic> printData = json.decode(message);
      final String content = printData['content'] ?? '';
      final String title = printData['title'] ?? 'Documento';

      print('🖨️ Procesando impresión directa para: $title');
      print('📝 Contenido a imprimir: "$content"');

      // Si no hay contenido, mostrar advertencia y salir
      if (content.isEmpty) {
        print('⚠️ No hay contenido para imprimir');
        return;
      }

      // Enviar directamente a la impresora sin confirmación
      final bool printSuccess = await NetworkPrinter.printToNetworkPrinter(
        content,
        title,
      );

      if (printSuccess) {
        print('✅ Documento impreso exitosamente en la impresora de red');

        // Notificar a la web para actualizar el historial
        await _notifyWebPrintHistory(content);

        // Limpiar el textarea después de la impresión exitosa
        await _clearTextarea();
      } else {
        print('❌ Error al imprimir en la impresora de red');
      }
    } catch (e) {
      print('❌ Error al procesar impresión directa: $e');
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
              final bool isConnected = await NetworkPrinter.testConnection();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isConnected
                        ? '✅ Conexión exitosa con impresora 192.168.1.13:9100'
                        : '❌ No se puede conectar a la impresora 192.168.1.13:9100',
                  ),
                  backgroundColor: isConnected ? Colors.green : Colors.red,
                ),
              );
            },
            tooltip: 'Probar conexión con impresora',
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
