import 'package:flutter/material.dart';
import 'printer_service.dart';

/// Service for handling basic printer test methods.
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

  /// Tests printing with custom configuration.
  Future<void> testCustomConfiguration({
    required String codeTable,
    required bool normalizeChars,
    required bool fullNormalization,
  }) async {
    _showSnackBar('🧪 Probando configuración: $codeTable', Colors.blue);

    try {
      // Log the configuration for debugging
      print(
        'Prueba con: $codeTable, Normalizar: $normalizeChars, Completo: $fullNormalization',
      );

      // Use the appropriate print method based on configuration
      if (fullNormalization) {
        await _printerService.printSimple(
          'Prueba de configuración personalizada\nCaracteres: áéíóú ñÑ üÜ ¿¡\nConfiguración: $codeTable (normalización completa)',
          'Prueba Configuración',
          PrinterService.printerIP,
        );
      } else if (codeTable == 'CP1252') {
        await _printerService.printSpanish(
          'Prueba de configuración personalizada\nCaracteres: áéíóú ñÑ üÜ ¿¡\nConfiguración: $codeTable',
          'Prueba Configuración',
          PrinterService.printerIP,
        );
      } else {
        await _printerService.printLatin1(
          'Prueba de configuración personalizada\nCaracteres: áéíóú ñÑ üÜ ¿¡\nConfiguración: $codeTable',
          'Prueba Configuración',
          PrinterService.printerIP,
        );
      }

      _showSnackBar(
        '✅ Configuración $codeTable probada exitosamente',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('❌ Error probando configuración: $e', Colors.red);
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
