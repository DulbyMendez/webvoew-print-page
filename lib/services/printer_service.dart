// Archivo para el servicio de impresión y la lógica de conexión.

import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../utils/character_fixer.dart';

/// Service class for handling all printer-related logic.
///
/// This includes connecting to the printer, generating ESC/POS commands,
/// and sending data for printing.
class PrinterService {
  // Static constants for the printer network configuration.
  // In a real app, these might come from user settings.
  static const String printerIP = '192.168.1.13';
  static const int printerPort = 9100;

  /// A simple method to test the connection to the default printer.
  Future<bool> testConnection() async {
    try {
      final socket = await Socket.connect(
        printerIP,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      print('✅ Conexión exitosa con la impresora.');
      return true;
    } catch (e) {
      print('❌ No se puede conectar a la impresora: $e');
      return false;
    }
  }

  /// Prints a ticket optimized for Spanish text using CP1252 encoding.
  ///
  /// This is the recommended method for printing Spanish text with accents and special characters.
  Future<void> printSpanish(String content, String title, String ip) async {
    try {
      // Limpia el texto específicamente para problemas de Android ANTES de procesarlo.
      final cleanTitle = cleanAndroidText(title);
      final cleanContent = cleanAndroidText(content);

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Usa el texto limpio con la codificación CP1252.
      bytes += generator.text(
        cleanTitle,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          codeTable: 'CP1252',
        ),
      );

      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Contenido:',
        styles: const PosStyles(codeTable: 'CP1252'),
      );
      bytes += generator.text(
        cleanContent,
        styles: const PosStyles(codeTable: 'CP1252'),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Fecha: ${DateTime.now().toString()}',
        styles: const PosStyles(codeTable: 'CP1252'),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      final socket = await Socket.connect(
        ip,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      socket.close();

      print('✅ Impresión en español enviada a $ip');
    } catch (e) {
      print('❌ Error al imprimir en español en $ip: $e');
      throw e;
    }
  }

  /// Prints a ticket using the Latin-1 (CP1252) encoding.
  ///
  /// This method is ideal for printing text with Spanish characters like accents and 'ñ'.
  /// It specifies the 'CP1252' code table for each text segment.
  Future<void> printLatin1(String content, String title, String ip) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Use CP1252 on each line to support Latin characters
      bytes += generator.text(
        title,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          codeTable: 'CP1252',
        ),
      );

      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Contenido:',
        styles: const PosStyles(codeTable: 'CP1252'),
      );
      bytes += generator.text(
        content,
        styles: const PosStyles(codeTable: 'CP1252'),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.feed(2);
      bytes += generator.cut();

      final socket = await Socket.connect(
        ip,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      socket.close();

      print('✅ Impresión Latin1 enviada a $ip');
    } catch (e) {
      print('❌ Error al imprimir con Latin1 en $ip: $e');
      // Optionally re-throw or handle the error as needed
      throw e;
    }
  }

  /// Prints a ticket using full normalization for maximum compatibility.
  ///
  /// This method converts all special characters to their basic ASCII equivalents.
  Future<void> printSimple(String content, String title, String ip) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text(
        normalizeText(title), // Uses full normalization
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text(normalizeText('Contenido:'));
      bytes += generator.text(normalizeText(content));
      bytes += generator.feed(2);
      bytes += generator.cut();

      final socket = await Socket.connect(
        ip,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      socket.close();

      print('✅ Impresión simple (normalizada) enviada a $ip');
    } catch (e) {
      print('❌ Error al imprimir de forma simple en $ip: $e');
      throw e;
    }
  }

  /// Runs a series of tests to find a compatible character encoding.
  Future<Map<String, bool>> testCharacterStrategies(String ip) async {
    final Map<String, bool> results = {};
    final List<String> codeTables = ['CP437', 'CP850', 'CP858', 'CP1252'];
    final String testText = 'Prueba: á, é, í, ó, ú, Ñ, ¿¡';

    for (final codeTable in codeTables) {
      try {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);
        List<int> bytes = [];
        bytes += generator.text(
          'Probando $codeTable...\n$testText',
          styles: PosStyles(codeTable: codeTable),
        );
        bytes += generator.cut();

        final socket = await Socket.connect(
          ip,
          printerPort,
          timeout: const Duration(seconds: 3),
        );
        socket.add(bytes);
        await socket.flush();
        socket.close();
        results[codeTable] = true;
        print('✅ Estrategia $codeTable funcionó.');
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        results[codeTable] = false;
        print('❌ Estrategia $codeTable falló: $e');
      }
    }
    return results;
  }
}
