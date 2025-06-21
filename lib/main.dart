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
          ..loadRequest(Uri.parse('https://print-web.vercel.app/'));

    // Initialize WebView communication service after controller
    _webViewService = WebViewCommunicationService(_controller);

    // Initialize test methods service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testMethodsService = TestMethodsService(_printerService, context);
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
      final String content = printData['content'] ?? '';
      final String title = printData['title'] ?? 'Documento';
      final List<Map<String, dynamic>> printers =
          (printData['printers'] as List? ?? []).cast<Map<String, dynamic>>();

      // Validate print data
      if (!PrintJobManager.validatePrintData(
        content: content,
        printers: printers,
      )) {
        _showSnackBar('⚠️ Datos de impresión inválidos', Colors.orange);
        _printJobManager.setPrintingStatus(false);
        return;
      }

      // Log print job info
      print(
        PrintJobManager.formatPrintJobInfo(
          title: title,
          content: content,
          printers: printers,
        ),
      );

      _showSnackBar('🖨️ Imprimiendo "$title"...', Colors.blue);

      // Print to multiple printers
      await _printToMultiplePrinters(content, title, printers);

      // Update web page
      await _webViewService.notifyPrintHistory(content);
      await _webViewService.clearTextarea();

      _printJobManager.setPrintingStatus(false);
    } catch (e) {
      print('❌ Error al procesar impresión directa: $e');
      _showSnackBar('❌ Error al procesar la impresión: $e', Colors.red);
      _printJobManager.setPrintingStatus(false);
    }
  }

  /// Prints to multiple printers.
  Future<void> _printToMultiplePrinters(
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
          await _printerService.printSpanish(content, title, ip);
          successCount++;
        } catch (e) {
          print('❌ Fallo al imprimir en $ip: $e');
        }
      }
    }

    _showSnackBar(
      '✅ Impresión completada: $successCount de $totalCopies copias en ${printers.length} impresora(s)',
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
            icon: const Icon(Icons.settings),
            onPressed: () => _showCharacterDialog(),
            tooltip: 'Configurar caracteres',
          ),
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () => _testMethodsService.runDiagnostic(),
            tooltip: 'Diagnóstico completo',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _webViewService.runDiagnostic(),
            tooltip: 'Diagnóstico de página web',
          ),
          IconButton(
            icon: const Icon(Icons.touch_app),
            onPressed: () => _webViewService.testManualPrint(),
            tooltip: 'Probar botón manualmente',
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => _webViewService.debugInjection(),
            tooltip: 'Depurar inyección JS',
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
