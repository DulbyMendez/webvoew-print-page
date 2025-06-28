import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import './services/printer_service.dart';
import './services/webview_communication_service.dart';
import './services/print_job_manager.dart';
import './services/test_methods_service.dart';
import './services/config_service.dart';
import './widgets/character_dialog.dart';
import './widgets/print_status_widget.dart';

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
  // Services
  late final PrinterService _printerService;
  late final WebViewCommunicationService _webViewService;
  late final PrintJobManager _printJobManager;
  late TestMethodsService _testMethodsService;

  // WebView controller
  late final WebViewController _controller;

  // Configuration state
  String _selectedCodeTable = 'CP1252';
  bool _normalizeCharacters = true;
  bool _fullNormalization = false;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _printerService = PrinterService();
    _printJobManager = PrintJobManager();

    // Load saved configuration
    _loadSavedConfig();

    // Initialize WebView controller
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                _webViewService.injectPrintInterceptor();
              },
            ),
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
          ..addJavaScriptChannel(
            'NativePrinter',
            onMessageReceived: (JavaScriptMessage message) {
              print(
                '🖨️ Mensaje de NativePrinter recibido: ${message.message}',
              );
              _handleDirectPrint(message.message);
            },
          )
          ..loadRequest(Uri.parse('https://print-web.vercel.app/'));

    // Initialize WebView communication service after controller
    _webViewService = WebViewCommunicationService(_controller);

    // Initialize test methods service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testMethodsService = TestMethodsService(
        _printerService,
        context,
        _webViewService,
      );
    });

    // Activar procesamiento automático de textarea
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webViewService.activateTextareaAutoProcessing();
    });
  }

  /// Loads saved configuration from persistent storage.
  Future<void> _loadSavedConfig() async {
    try {
      final config = await ConfigService.loadConfig();
      setState(() {
        _selectedCodeTable = config['codeTable'] as String;
        _normalizeCharacters = config['normalizeChars'] as bool;
        _fullNormalization = config['fullNormalization'] as bool;
      });
      print('✅ Configuración cargada: $_selectedCodeTable');

      // Enviar configuración a la web después de que se inicialice el WebView
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _webViewService.sendPrintConfiguration(
          codeTable: _selectedCodeTable,
          normalizeCharacters: _normalizeCharacters,
          fullNormalization: _fullNormalization,
        );
      });
    } catch (e) {
      print('⚠️ Error cargando configuración: $e');
    }
  }

  /// Handles direct print requests from the WebView.
  Future<void> _handleDirectPrint(String message) async {
    try {
      if (!_printJobManager.canPrint) {
        _showSnackBar(
          '⚠️ Impresión en progreso, espere un momento',
          Colors.orange,
        );
        return;
      }

      _printJobManager.setPrintingStatus(true);

      final Map<String, dynamic> printData = json.decode(message);

      // Verificar si es un mensaje con tipo específico
      final String? messageType = printData['type'];

      if (messageType == 'printToPrinter') {
        // Manejar formato printToPrinter (formato simple con ip, content, copies)
        await _handlePrintToPrinter(printData);
      } else if (messageType == 'processInvoiceWithImage') {
        // Manejar factura con imagen
        await _handleInvoiceWithImage(printData);
      } else {
        // Manejar impresión directa normal
        await _handleNormalPrint(printData);
      }

      _printJobManager.setPrintingStatus(false);
    } catch (e) {
      print('❌ Error al procesar impresión directa: $e');
      _showSnackBar('❌ Error al procesar la impresión: $e', Colors.red);
      _printJobManager.setPrintingStatus(false);
    }
  }

  /// Handles printToPrinter format (simple format with ip, content, copies).
  Future<void> _handlePrintToPrinter(Map<String, dynamic> printData) async {
    try {
      String content = printData['content'] ?? '';
      final String ip = printData['ip'] ?? '';
      final int copies = printData['copies'] ?? 1;

      print('🖨️ Procesando impresión printToPrinter:');
      print('   - IP: $ip');
      print('   - Copias: $copies');
      print('   - Contenido original: ${content.length} caracteres');

      // Validar datos básicos
      if (ip.isEmpty) {
        _showSnackBar('⚠️ IP de impresora no especificada', Colors.orange);
        return;
      }

      if (content.isEmpty) {
        _showSnackBar('⚠️ Contenido vacío', Colors.orange);
        return;
      }

      // FORMATO MEJORADO: Procesar el contenido como en "probar factura"
      print('🔄 Aplicando formato mejorado al contenido...');

      // 1. Normalizar saltos de línea (manejar tanto \n como \\n)
      content = content
          .replaceAll('\\n', '\n') // Convertir \\n a \n
          .replaceAll('\\t', '\t') // Convertir \\t a \t
          .replaceAll('\\r', '\r'); // Convertir \\r a \r

      // 2. Normalizar saltos de línea para consistencia
      content = content
          .replaceAll('\r\n', '\n') // Convertir Windows CRLF a LF
          .replaceAll('\r', '\n'); // Convertir Mac OS 9 CR a LF

      print(
        '   - Después de normalizar saltos de línea: ${content.length} caracteres',
      );

      // 3. Extraer título de la primera línea del contenido
      final String title = _extractTitleFromContent(content);
      print('   - Título extraído: "$title"');

      // 4. Detectar si es una factura
      final bool isInvoice = _isInvoiceContent(content);
      print('   - Tipo de documento: ${isInvoice ? 'Factura' : 'Documento'}');

      // 5. Aplicar formato específico para facturas
      if (isInvoice) {
        print('   - Aplicando formato de factura...');
        content = _formatInvoiceContent(content);
        print('   - Contenido formateado: ${content.length} caracteres');
      }

      _showSnackBar(
        '🖨️ Imprimiendo ${isInvoice ? 'factura' : 'documento'} "$title"...',
        Colors.blue,
      );

      // Imprimir según el tipo de contenido
      int successCount = 0;
      for (int i = 0; i < copies; i++) {
        try {
          if (isInvoice) {
            await _printerService.printInvoice(content, title, ip);
          } else {
            await _printerService.printSpanish(content, title, ip);
          }
          successCount++;
          print('✅ Copia ${i + 1} impresa exitosamente en $ip');
        } catch (e) {
          print('❌ Fallo al imprimir copia ${i + 1} en $ip: $e');
        }
      }

      // Update web page
      await _webViewService.notifyPrintHistory(content);
      await _webViewService.clearTextarea();

      _showSnackBar(
        '✅ Impresión completada: $successCount de $copies copias en $ip',
        Colors.green,
      );
    } catch (e) {
      print('❌ Error procesando printToPrinter: $e');
      _showSnackBar('❌ Error procesando impresión: $e', Colors.red);
    }
  }

  /// Extracts title from the first line of content.
  String _extractTitleFromContent(String content) {
    // Normalizar saltos de línea
    String normalizedContent = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    // Obtener la primera línea no vacía
    final lines = normalizedContent.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        // Remover etiquetas de formato del título
        String cleanTitle =
            trimmedLine
                .replaceAll('<center>', '')
                .replaceAll('<negrita>', '')
                .replaceAll('<imagen_grande>', '')
                .trim();

        print('📄 Título extraído: "$cleanTitle"');
        return cleanTitle;
      }
    }

    // Si no se encuentra título, usar un valor por defecto
    print(
      '⚠️ No se pudo extraer título del contenido, usando valor por defecto',
    );
    return 'Documento';
  }

  /// Formats invoice content for better printing.
  /// Applies the same formatting logic as "probar factura".
  String _formatInvoiceContent(String content) {
    print('📝 Aplicando formato de factura...');

    // Dividir en líneas
    final lines = content.split('\n');
    final formattedLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      print(
        '   - Línea ${i + 1}: "${line.substring(0, line.length > 50 ? 50 : line.length)}${line.length > 50 ? '...' : ''}"',
      );

      // Procesar etiquetas HTML
      bool isCentered = false;
      bool isBold = false;

      // Detectar etiquetas
      if (line.contains('<center>')) {
        isCentered = true;
        line = line.replaceAll('<center>', '');
      }
      if (line.contains('<negrita>')) {
        isBold = true;
        line = line.replaceAll('<negrita>', '');
      }

      // Manejar imágenes QR
      if (line.startsWith('<imagen_grande>')) {
        formattedLines.add(
          line,
        ); // Mantener la línea original para procesamiento posterior
        print('   - [IMAGEN QR] detectada');
        continue;
      }

      // Limpiar espacios extra
      line = line.trim();

      // Solo agregar líneas con contenido
      if (line.isNotEmpty) {
        // Agregar marcadores de formato
        String formattedLine = '';
        if (isCentered) formattedLine += '[CENTER]';
        if (isBold) formattedLine += '[BOLD]';
        formattedLine += line;

        formattedLines.add(formattedLine);
        print(
          '   - ${isCentered ? '[CENTRADA] ' : ''}${isBold ? '[NEGRITA] ' : ''}"${line.substring(0, line.length > 30 ? 30 : line.length)}${line.length > 30 ? '...' : ''}"',
        );
      }
    }

    final result = formattedLines.join('\n');
    print(
      '📝 Resultado formateado: ${result.length} caracteres, ${formattedLines.length} líneas',
    );
    return result;
  }

  /// Handles invoice with image processing.
  Future<void> _handleInvoiceWithImage(Map<String, dynamic> printData) async {
    try {
      final String content = printData['content'] ?? '';
      final String title = printData['title'] ?? 'Factura con Imagen';
      final List<Map<String, dynamic>> printers =
          (printData['printers'] as List? ?? []).cast<Map<String, dynamic>>();

      print('🧾 Procesando factura con imagen: $title');
      print('📄 Contenido de factura recibido (${content.length} caracteres)');

      // Validar datos de factura
      if (!PrintJobManager.validateInvoiceData(
        content: content,
        title: title,
        printers: printers,
      )) {
        _showSnackBar('⚠️ Datos de factura inválidos', Colors.orange);
        return;
      }

      // Log invoice job info
      print(
        PrintJobManager.formatInvoiceJobInfo(
          title: title,
          content: content,
          printers: printers,
        ),
      );

      _showSnackBar('🧾 Procesando factura "$title"...', Colors.blue);

      // Imprimir factura
      await _printInvoiceToMultiplePrinters(content, title, printers);

      // Update web page
      await _webViewService.notifyPrintHistory(content);
      await _webViewService.clearTextarea();

      _showSnackBar('✅ Factura procesada exitosamente', Colors.green);
    } catch (e) {
      print('❌ Error procesando factura con imagen: $e');
      _showSnackBar('❌ Error procesando factura: $e', Colors.red);
    }
  }

  /// Handles normal print requests with the new structure where each printer has its own content.
  Future<void> _handleNormalPrint(Map<String, dynamic> printData) async {
    try {
      final List<Map<String, dynamic>> printers =
          (printData['printers'] as List? ?? []).cast<Map<String, dynamic>>();

      if (printers.isEmpty) {
        _showSnackBar('⚠️ No hay impresoras configuradas', Colors.orange);
        return;
      }

      print('🖨️ Procesando impresión con contenido específico por impresora:');
      print('   - Número de impresoras: ${printers.length}');

      int totalSuccessCount = 0;
      int totalCopies = 0;

      for (
        int printerIndex = 0;
        printerIndex < printers.length;
        printerIndex++
      ) {
        final printer = printers[printerIndex];
        final String ip = printer['ip'] ?? '';
        final int copies = printer['copies'] ?? 1;
        String content = printer['content'] ?? '';
        String title = printer['title'] ?? 'Documento';

        print('   📍 Impresora ${printerIndex + 1}: $ip');
        print('   - Copias: $copies');
        print('   - Título: "$title"');
        print('   - Contenido: ${content.length} caracteres');

        // Validar datos de la impresora
        if (ip.isEmpty) {
          print('❌ IP de impresora ${printerIndex + 1} no especificada');
          continue;
        }

        if (content.isEmpty) {
          print('❌ Contenido de impresora ${printerIndex + 1} vacío');
          continue;
        }

        // Procesar contenido específico de esta impresora
        print('🔄 Procesando contenido para impresora $ip...');

        // 1. Normalizar saltos de línea
        content = content
            .replaceAll('\\n', '\n')
            .replaceAll('\\t', '\t')
            .replaceAll('\\r', '\r')
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n');

        // 2. Detectar si es una factura
        final bool isInvoice = _isInvoiceContent(content);
        print('   - Tipo de documento: ${isInvoice ? 'Factura' : 'Documento'}');

        // 3. Aplicar formato específico para facturas
        if (isInvoice) {
          print('   - Aplicando formato de factura...');
          content = _formatInvoiceContent(content);
        }

        // 4. Imprimir en esta impresora
        int successCount = 0;
        for (int i = 0; i < copies; i++) {
          try {
            if (isInvoice) {
              await _printerService.printInvoice(content, title, ip);
            } else {
              await _printerService.printSpanish(content, title, ip);
            }
            successCount++;
            print('✅ Copia ${i + 1} impresa exitosamente en $ip');
          } catch (e) {
            print('❌ Fallo al imprimir copia ${i + 1} en $ip: $e');
          }
        }

        totalSuccessCount += successCount;
        totalCopies += copies;

        // Notificar historial para esta impresora
        await _webViewService.notifyPrintHistory(
          'Impreso en $ip: $title (${successCount}/${copies} copias)',
        );
      }

      // Limpiar textarea después de todas las impresiones
      await _webViewService.clearTextarea();

      // Mostrar resumen final
      if (totalSuccessCount > 0) {
        _showSnackBar(
          '✅ Impresión completada: $totalSuccessCount de $totalCopies copias en ${printers.length} impresora(s)',
          Colors.green,
        );
      } else {
        _showSnackBar('❌ No se pudo imprimir en ninguna impresora', Colors.red);
      }
    } catch (e) {
      print('❌ Error procesando impresión normal: $e');
      _showSnackBar('❌ Error procesando impresión: $e', Colors.red);
    }
  }

  /// Detects if the content is an invoice based on its structure.
  bool _isInvoiceContent(String content) {
    final hasInvoiceElements =
        content.contains('FACTURA') ||
        content.contains('NIT:') ||
        content.contains('TOTAL:') ||
        content.contains('SUBTOTAL:') ||
        content.contains('SUBTOTAL:') ||
        content.contains('Articulo') ||
        content.contains('Cantidad') ||
        content.contains('Valor');

    final hasQRImage = content.contains('<imagen_grande>');

    return hasInvoiceElements || hasQRImage;
  }

  /// Prints invoice to multiple printers.
  Future<void> _printInvoiceToMultiplePrinters(
    String content,
    String title,
    List<Map<String, dynamic>> printers,
  ) async {
    int successCount = 0;
    int totalCopies = 0;

    for (final printer in printers) {
      final String ip = printer['ip'];
      final int copies = printer['copies'];
      totalCopies += copies;

      for (int i = 0; i < copies; i++) {
        try {
          await _printerService.printInvoice(content, title, ip);
          successCount++;
        } catch (e) {
          print('❌ Fallo al imprimir factura en $ip: $e');
        }
      }
    }

    _showSnackBar(
      '✅ Factura impresa: $successCount de $totalCopies copias en ${printers.length} impresora(s)',
      Colors.green,
    );
  }

  /// Shows the character configuration dialog.
  Future<void> _showCharacterDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CharacterDialog(
          initialCodeTable: _selectedCodeTable,
          initialNormalize: _normalizeCharacters,
          initialFullNormalize: _fullNormalization,
          onConfigSaved: (codeTable, normalize, fullNormalize) async {
            setState(() {
              _selectedCodeTable = codeTable;
              _normalizeCharacters = normalize;
              _fullNormalization = fullNormalize;
            });

            // Save configuration to persistent storage
            try {
              await ConfigService.saveConfig(
                codeTable: codeTable,
                normalizeChars: normalize,
                fullNormalization: fullNormalize,
              );
              print('✅ Configuración guardada: $codeTable');

              // Enviar nueva configuración a la web
              await _webViewService.sendPrintConfiguration(
                codeTable: codeTable,
                normalizeCharacters: normalize,
                fullNormalization: fullNormalize,
              );
            } catch (e) {
              print('❌ Error guardando configuración: $e');
            }

            // Test the new configuration
            _testMethodsService.testCustomConfiguration(
              codeTable: codeTable,
              normalizeChars: normalize,
              fullNormalization: fullNormalize,
            );
          },
        );
      },
    );
  }

  /// Shows a snackbar with the given message and color.
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
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
          // === BOTONES DE PRUEBA BÁSICA ===
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _testMethodsService.testQuickPrint(),
            tooltip: 'Impresión rápida (CP1252)',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _testMethodsService.testConnection(),
            tooltip: 'Probar conexión',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _testMethodsService.testLatin1Print(),
            tooltip: 'Probar caracteres españoles',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => _testMethodsService.testCharacterNormalization(),
            tooltip: 'Probar normalización',
          ),

          // Separador visual
          const VerticalDivider(color: Colors.white54, width: 1),

          // === BOTONES DE FACTURA ===
          IconButton(
            icon: const Icon(Icons.receipt),
            onPressed: () => _webViewService.sendInvoiceFromFile(),
            tooltip: 'Probar factura con QR desde archivo',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () async {
              await PrinterService.printTestQrSimple('192.168.1.13');
            },
            tooltip: 'Imprimir QR de prueba',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => _webViewService.processTextareaContent(),
            tooltip: 'Procesar textarea para impresión',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () => _webViewService.activateTextareaAutoProcessing(),
            tooltip: 'Activar procesamiento automático',
          ),

          // Separador visual
          const VerticalDivider(color: Colors.white54, width: 1),

          // === BOTONES DE CONFIGURACIÓN ===
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showCharacterDialog(),
            tooltip: 'Configurar caracteres',
          ),
          IconButton(
            icon: const Icon(Icons.settings_applications),
            onPressed:
                () => _webViewService.sendPrintConfiguration(
                  codeTable: _selectedCodeTable,
                  normalizeCharacters: _normalizeCharacters,
                  fullNormalization: _fullNormalization,
                ),
            tooltip: 'Enviar configuración a web',
          ),

          // Separador visual
          const VerticalDivider(color: Colors.white54, width: 1),

          // === BOTONES DE AYUDA ===
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () => _webViewService.getFunctionUsage(),
            tooltip: 'Información de uso',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _webViewService.testIsFlutterWebView(),
            tooltip: 'Probar isFlutterWebView',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status widget at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PrintStatusWidget(
              printJobManager: _printJobManager,
              selectedCodeTable: _selectedCodeTable,
              normalizeCharacters: _normalizeCharacters,
            ),
          ),
          // WebView takes the rest of the space
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
