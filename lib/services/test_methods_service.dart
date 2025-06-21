import 'package:flutter/material.dart';
import 'printer_service.dart';

/// Service for handling printer test methods and diagnostics.
class TestMethodsService {
  final PrinterService _printerService;
  final BuildContext _context;

  TestMethodsService(this._printerService, this._context);

  /// Tests the connection to the printer.
  Future<void> testConnection() async {
    _showSnackBar('🔍 Probando conexión con impresora...', Colors.blue);

    final bool isConnected = await _printerService.testConnection();

    _showSnackBar(
      isConnected
          ? '✅ Conexión exitosa con la impresora'
          : '❌ No se puede conectar a la impresora',
      isConnected ? Colors.green : Colors.red,
    );
  }

  /// Tests simple printing with normalization.
  Future<void> testSimplePrint() async {
    _showSnackBar('🖨️ Probando impresión simple...', Colors.blue);

    try {
      await _printerService.printSimple(
        'Prueba de impresión simple\ncon normalización.\nFecha: ${DateTime.now().toString()}',
        'Prueba Simple',
        PrinterService.printerIP,
      );
      _showSnackBar('✅ Impresión simple exitosa', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error en impresión simple: $e', Colors.red);
    }
  }

  /// Tests Latin1 printing with Spanish characters.
  Future<void> testLatin1Print() async {
    _showSnackBar('🖨️ Probando impresión Latin1...', Colors.blue);

    try {
      await _printerService.printLatin1(
        '¡Hola mundo con acentos y eñes!\nPrueba de impresión con CP1252 (Latin1).\nDebería funcionar correctamente. 🤓\nFecha: ${DateTime.now().toString()}',
        'Prueba Latin1',
        PrinterService.printerIP,
      );
      _showSnackBar('✅ Impresión Latin1 exitosa', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error en impresión Latin1: $e', Colors.red);
    }
  }

  /// Tests different character encoding strategies.
  Future<void> testCharacterStrategies() async {
    _showSnackBar(
      '🧪 Probando estrategias de codificación...',
      Colors.blue,
      duration: const Duration(seconds: 10),
    );

    try {
      final results = await _printerService.testCharacterStrategies(
        PrinterService.printerIP,
      );

      String message = 'Resultados de estrategias:\n';
      results.forEach((key, value) {
        message += '${value ? "✅" : "❌"} $key\n';
      });

      _showSnackBar(
        message,
        results.values.contains(true) ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      _showSnackBar('❌ Error probando estrategias: $e', Colors.red);
    }
  }

  /// Tests printing with custom configuration.
  Future<void> testCustomConfiguration({
    required String codeTable,
    required bool normalizeChars,
    required bool fullNormalization,
  }) async {
    _showSnackBar('🧪 Probando configuración: $codeTable', Colors.blue);

    try {
      // This would need to be implemented in PrinterService
      // For now, we'll just log the configuration
      print(
        'Prueba con: $codeTable, Normalizar: $normalizeChars, Completo: $fullNormalization',
      );

      // Example of how it could be called:
      // await _printerService.printWithCustomConfig(
      //   'Prueba de configuración personalizada\nCaracteres: áéíóú ñÑ üÜ ¿¡\nConfiguración: $codeTable',
      //   'Prueba Configuración',
      //   PrinterService.printerIP,
      //   codeTable: codeTable,
      //   normalizeChars: normalizeChars,
      //   fullNormalization: fullNormalization,
      // );

      _showSnackBar(
        '✅ Configuración $codeTable probada (solo log)',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('❌ Error probando configuración: $e', Colors.red);
    }
  }

  /// Runs a comprehensive printer diagnostic.
  Future<void> runDiagnostic() async {
    _showSnackBar(
      '🔧 Ejecutando diagnóstico completo...',
      Colors.blue,
      duration: const Duration(seconds: 15),
    );

    try {
      // Test 1: Connection
      final isConnected = await _printerService.testConnection();

      if (!isConnected) {
        _showSnackBar('❌ Diagnóstico falló: No hay conexión', Colors.red);
        return;
      }

      // Test 2: Character strategies
      final strategies = await _printerService.testCharacterStrategies(
        PrinterService.printerIP,
      );

      // Test 3: Simple print
      await _printerService.printSimple(
        'Diagnóstico completo\nFecha: ${DateTime.now().toString()}',
        'Diagnóstico',
        PrinterService.printerIP,
      );

      // Summary
      final workingStrategies = strategies.values.where((v) => v).length;
      final totalStrategies = strategies.length;

      String summary = '🔧 Diagnóstico completado:\n';
      summary += '✅ Conexión: OK\n';
      summary += '✅ Impresión simple: OK\n';
      summary +=
          '📊 Estrategias de caracteres: $workingStrategies/$totalStrategies funcionan\n';

      _showSnackBar(
        summary,
        workingStrategies > 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 8),
      );
    } catch (e) {
      _showSnackBar('❌ Error en diagnóstico: $e', Colors.red);
    }
  }

  /// Tests quick printing with Spanish optimization (CP1252).
  Future<void> testQuickPrint() async {
    _showSnackBar('⚡ Impresión rápida en español...', Colors.blue);

    try {
      await _printerService.printSpanish(
        '¡Impresión rápida!\nCaracteres españoles: áéíóú ñÑ üÜ ¿¡\nFecha: ${DateTime.now().toString()}',
        'Prueba Rápida',
        PrinterService.printerIP,
      );
      _showSnackBar('✅ Impresión rápida exitosa', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error en impresión rápida: $e', Colors.red);
    }
  }

  /// Shows a snackbar with the given message and color.
  void _showSnackBar(
    String message,
    Color backgroundColor, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}
