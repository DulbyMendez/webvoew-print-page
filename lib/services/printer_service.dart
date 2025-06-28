// Archivo para el servicio de impresión y la lógica de conexión.

import 'dart:io';
import 'dart:convert';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../utils/character_fixer.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

// Logger simple para evitar warnings de linter
class Logger {
  static void log(String message) {
    // En modo debug, usar print. En producción, usar un logger real
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      print(message);
    }
  }
}

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
      Logger.log('✅ Conexión exitosa con la impresora.');
      return true;
    } catch (e) {
      Logger.log('❌ No se puede conectar a la impresora: $e');
      return false;
    }
  }

  /// Prints a ticket optimized for Spanish text using CP1252 encoding.
  ///
  /// This is the recommended method for printing Spanish text with accents and special characters.
  Future<void> printSpanish(String content, String title, String ip) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Normalize text to remove incompatible characters while preserving Spanish accents
      final normalizedTitle = normalizeSpanishText(title);
      final normalizedContent = normalizeSpanishText(content);

      // Use CP1252 for Spanish text (optimized for á, é, í, ó, ú, ñ, ¿, ¡)
      bytes += generator.text(
        normalizedTitle,
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
        normalizedContent,
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

      Logger.log('✅ Impresión en español enviada a $ip');
    } catch (e) {
      Logger.log('❌ Error al imprimir en español en $ip: $e');
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

      // Normalize text to remove incompatible characters while preserving Spanish accents
      final normalizedTitle = normalizeSpanishText(title);
      final normalizedContent = normalizeSpanishText(content);

      // Use CP1252 on each line to support Latin characters
      bytes += generator.text(
        normalizedTitle,
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
        normalizedContent,
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

      Logger.log('✅ Impresión Latin1 enviada a $ip');
    } catch (e) {
      Logger.log('❌ Error al imprimir con Latin1 en $ip: $e');
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

      Logger.log('✅ Impresión simple (normalizada) enviada a $ip');
    } catch (e) {
      Logger.log('❌ Error al imprimir de forma simple en $ip: $e');
      throw e;
    }
  }

  /// Decodifica los bytes de una imagen QR y devuelve un objeto Image listo para imprimir.
  /// Devuelve null si la imagen no es válida o no se puede decodificar.
  img.Image? decodeQrImageForPrint(List<int> imageBytes) {
    try {
      // Asegurarse de que los bytes sean Uint8List para compatibilidad
      final bytes =
          imageBytes is Uint8List ? imageBytes : Uint8List.fromList(imageBytes);
      final qrImg = img.decodeImage(bytes);
      if (qrImg == null) {
        Logger.log('❌ No se pudo decodificar la imagen QR.');
        return null;
      }
      // Escalar la imagen a 300x300 para que sea más visible en la impresora
      final resized = img.copyResize(qrImg, width: 300, height: 300);
      return resized;
    } catch (e) {
      Logger.log('❌ Error al decodificar la imagen QR: $e');
      return null;
    }
  }

  /// Divide y centra el título para impresión térmica.
  /// [maxChars] es el ancho máximo de la impresora (por ejemplo, 32 o 42).
  List<String> splitAndCenterTitle(String title, {int maxChars = 32}) {
    final words = title.split(' ');
    List<String> lines = [];
    String current = '';
    for (final word in words) {
      if ((current + ' ' + word).trim().length > maxChars) {
        lines.add(current.trim());
        current = word;
      } else {
        current += ' ' + word;
      }
    }
    if (current.trim().isNotEmpty) lines.add(current.trim());
    return lines;
  }

  /// Procesa y imprime una factura que contiene texto y una imagen QR en base64.
  /// Ahora usa la función de formateo para mantener el método limpio y atómico.
  /// Extrae automáticamente el título de la primera línea del contenido.
  Future<void> printInvoice(String content, String title, String ip) async {
    try {
      final bool isSimulationMode = ip == '127.0.0.1' || ip == 'localhost';
      if (isSimulationMode) {
        Logger.log('🧪 MODO SIMULACIÓN: Procesando factura sin impresora real');

        // Extraer título de la primera línea del contenido
        final extractedTitle = extractTitleFromContent(content);
        Logger.log('📄 Título extraído: $extractedTitle');

        // Primero formatear el string desde la web usando la nueva función mejorada
        final formattedContent = processWebContent(content);
        Logger.log(
          '📝 Contenido formateado desde web: ${formattedContent.length} caracteres',
        );

        final formattedLines = formatInvoiceContent(formattedContent);
        for (final line in formattedLines) {
          if (line.isImage) {
            Logger.log('🖼️ Imagen: ${line.imageBytes?.length ?? 0} bytes');
          } else {
            Logger.log('   ${line.text}');
          }
        }
        await Future.delayed(const Duration(seconds: 2));
        Logger.log('✅ SIMULACIÓN: Factura procesada exitosamente');
        return;
      }
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Extraer título de la primera línea del contenido
      final extractedTitle = extractTitleFromContent(content);
      Logger.log('📄 Título extraído para impresión: $extractedTitle');

      // Imprimir título dividido y centrado
      final titleLines = splitAndCenterTitle(
        extractedTitle,
        maxChars: 32,
      ); // Ajusta maxChars según tu impresora
      for (final line in titleLines) {
        bytes += generator.text(
          normalizeSpanishText(line),
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            codeTable: 'CP1252',
          ),
        );
      }
      bytes += generator.emptyLines(1);

      // Primero formatear el string desde la web usando la nueva función mejorada
      final formattedContent = processWebContent(content);
      Logger.log(
        '📝 Contenido formateado desde web: ${formattedContent.length} caracteres',
      );

      // Imprimir líneas formateadas
      final formattedLines = formatInvoiceContent(formattedContent);
      for (final line in formattedLines) {
        if (line.isImage &&
            line.imageBytes != null &&
            line.imageBytes!.isNotEmpty) {
          // Usar la misma lógica que funciona en printTestQr
          try {
            // Convertir los bytes a string base64 y luego decodificar como en printTestQr
            final base64String = base64Encode(line.imageBytes!);
            final qrBytes = base64Decode(
              base64String.trim().replaceAll(' ', ''),
            );
            final qrImg = decodeQrImageForPrint(qrBytes);

            if (qrImg != null) {
              // Imprimir la imagen QR centrada
              bytes += generator.image(qrImg, align: PosAlign.center);
              bytes += generator.emptyLines(1);
            } else {
              // Si la imagen no es válida, imprimir un marcador de error
              bytes += generator.text(
                '[IMAGEN QR INVÁLIDA]',
                styles: const PosStyles(
                  align: PosAlign.center,
                  codeTable: 'CP1252',
                ),
              );
            }
          } catch (e) {
            Logger.log('❌ Error procesando QR en factura: $e');
            bytes += generator.text(
              '[ERROR EN QR]',
              styles: const PosStyles(
                align: PosAlign.center,
                codeTable: 'CP1252',
              ),
            );
          }
          continue;
        } else {
          bytes += generator.text(
            normalizeSpanishText(line.text),
            styles: PosStyles(
              align: line.align,
              bold: line.bold,
              codeTable: 'CP1252',
            ),
          );
        }
      }
      bytes += generator.emptyLines(1);
      final currentDate = DateTime.now().toString();
      bytes += generator.text(
        'Fecha: $currentDate',
        styles: const PosStyles(codeTable: 'CP1252', align: PosAlign.center),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();
      final socket = await Socket.connect(
        ip,
        printerPort,
        timeout: const Duration(seconds: 10),
      );
      socket.add(bytes);
      await socket.flush();
      socket.close();
      Logger.log('✅ Factura impresa exitosamente en $ip');
    } catch (e) {
      if (e.toString().contains('Connection timed out')) {
        Logger.log(
          '❌ Error de conexión: No se pudo conectar a la impresora $ip',
        );
        Logger.log('💡 Verifique que:');
        Logger.log('   - La impresora esté encendida');
        Logger.log('   - La IP $ip sea correcta');
        Logger.log('   - La impresora esté en la misma red');
        Logger.log('   - El puerto $printerPort esté abierto');
      } else {
        Logger.log('❌ Error al imprimir factura en $ip: $e');
      }
      throw e;
    }
  }

  /// Extrae el título de la primera línea del contenido.
  /// Remueve etiquetas de formato y retorna el texto limpio.
  String extractTitleFromContent(String content) {
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
                .replaceAll('[CENTER]', '')
                .replaceAll('[BOLD]', '')
                .replaceAll('[CENTER][BOLD]', '')
                .replaceAll('[BOLD][CENTER]', '')
                .trim();

        Logger.log('📄 Título extraído: "$cleanTitle"');
        return cleanTitle;
      }
    }

    // Si no se encuentra título, usar un valor por defecto
    Logger.log(
      '⚠️ No se pudo extraer título del contenido, usando valor por defecto',
    );
    return 'FACTURA';
  }

  /// Imprime solo un QR de prueba, centrado, usando un string base64.
  /// Útil para pruebas rápidas de impresión de QR.
  Future<void> printTestQr(String ip, String base64Qr) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Decodificar el QR
      final qrBytes = base64Decode(base64Qr.trim().replaceAll(' ', ''));
      final qrImg = decodeQrImageForPrint(qrBytes);

      if (qrImg != null) {
        bytes += generator.text(
          'PRUEBA QR',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            codeTable: 'CP1252',
          ),
        );
        bytes += generator.emptyLines(1);
        bytes += generator.image(qrImg, align: PosAlign.center);
        bytes += generator.emptyLines(2);
        bytes += generator.cut();

        final socket = await Socket.connect(
          ip,
          PrinterService.printerPort,
          timeout: const Duration(seconds: 10),
        );
        socket.add(bytes);
        await socket.flush();
        socket.close();
        Logger.log('✅ QR de prueba impreso en $ip');
      } else {
        Logger.log('❌ No se pudo decodificar el QR de prueba');
      }
    } catch (e) {
      Logger.log('❌ Error al imprimir QR de prueba: $e');
    }
  }

  /// Método estático para imprimir un QR de prueba con base64 válido.
  /// Útil para pruebas rápidas sin necesidad de proporcionar base64.
  static Future<void> printTestQrSimple(String ip) async {
    // QR simple de 1x1 pixel (válido y funcional)
    const testQrBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAALQAAADECAYAAAA27wvzAAAAAXNSR0IArs4c6QAAGY1JREFUeF7tnQeoXNUTxk+s2HsvSey9YRdJYhe7WLEksSHYEBuKmkSxoiJiF01iw16xI0nAhg171yQq9q7Yy585sO//9r739rdf5uy+TTIXBHXOmfLNN3Pm3t13d8B///33X+qQ6/jjj0+XXnpp2mKLLdJTTz1V59X222+fHn/88XTSSSelCy+8sIjHl19+eTrmmGN61TX//POnRx55JG2++eZFbE0PSv7888900EEHpXvuuSf99ddf04PLPXwc0EmEfvHFF9NGG22UBgwYkD7++OO07LLLZoe/++67tOSSS2aQX3nllbTuuusWAbtGaCPt/fffn/V/+OGH6cwzz0wTJkxIAwcOTB988EGabbbZitjrdCXffPNNWmyxxdKss86a/v777053t1f/OorQ5uFqq62W3n333XTRRRelE044ITt9ww03pEMPPTSttdZa6fXXX092qFxyySXpuuuuS5aENdZYI40ePTpttdVWef0111yTxo4dm0aOHJnuvPPO9Pbbb6err7467bLLLnUg1Ag9ZMiQNHHixC7ZL7/8kpZZZpn0008/5S69ww47ZNnTTz+dzj333PTSSy+lOeaYI2277bbp7LPPTksvvXTXXpOdccYZ6YUXXkhzzz132nLLLdN5552XlltuufTmm2/mOAYNGpRuu+22vOedd95JI0aMyHLz9ccff0x2Gq2yyipp5513zvq//PLLtOuuu6YLLrggjRo1Kt11113JTpBTTjkl67OLMHn//fdz991ss83SBhtskHV9//33+QS67LLL0uKLL5422WSTHJtd9u+nnXZatvv777/nGO6444701VdfpRVXXDEdd9xx6YADDug40nccoc8666yctA033DCTwq4dd9wxPfroo+n888/PSTz99NPTOeeck5ZaaqmcoMceeyz98ccfmZQ2rtTkc801V/rnn3+yjtdeey2tuuqqTRHaFm2zzTbpySefzIQyfWbfCGb6jBDffvttmjp1aiai+bnEEktkwm688cbp119/zX78/PPPXXbfeOONZCeQ+Wt+GJHtqp1KRhI7DWpd0nyfc84509Zbb52eeOKJXFwLLbRQtmMnh8U8yyyzZD0rr7wyYmIn2/rrr58WWGCB3IGHDh2aTyEj9YEHHpjGjRuX9UyePDn7Zf4Yiffcc8/sw6RJk9LCCy+cfTfS23hixX3qqad2FKk7jtB25K+00koZJEvwIosskruHHYFGoAUXXLDrv23t8ssvnx588MHcSYxw9u/dCW8d3RJo+6pXXx3a1u299965E9pcb6fB6quvnslj87vN8TaeWMc3Ylm3stnfOu348eO7/vvff/9Nu+22W+7mtu/rr79umtDmg90z2ClgxLJuaTgY4azz22hmxWBd3Tp6DaO+MKkR2vS+9dZbOZ6777477bXXXmnw4MHpo48+6iqm7iPH7bffnvbbb7+M88svv5zzYeQeNmxYmn322fNoaEXWKVfHEdqAsS723HPP5S5sx7mNDrWx4Jlnnsndz5J6+OGHZxx/++23dO211+ak2vFcI7R1nptuuqlPrBsR2orjoYceyh3o2GOPzaeBzfY2jphtu+69997cwdZZZ5306quv5pHIunT3MaW7cYup2Q5t+6xobH6vjVzbbbddLiC7rICteG+++eZMSMKkRuhFF100F5ZdVuzmu92ffP75570S+sgjj8wjnJ2MdkLWLruPsVPPbiD32GOPTuFz6khC14i29tpr5yP94YcfzvPyYYcdlp9+2Fw6zzzz5GOz+2Wd0ACuEbrWOftCuxGhV1hhhdwNrePabG5+WOeyebJ2k2h+7bTTTrnbWdez4/i9997L/tqYVL1qhLb52O4T7KoVaHXk6N4lbRyworZuf9999+V9u+++e76RtYK1mZwwqRHaxpUpU6ZkHXbimO/WYb/44oteCW2YX3/99flGecyYMV0h2Whlo5Z18H322ScI3QgB6yDWmW3MsMQagQxwGxusA1u3tBnT/t98882XRxG7YbOuseaaa3YR2m4q7eZSIbTdXF155ZXp6KOPzp34k08+yXOndTGbb60rWve2y9ZcccUV+WbrxhtvzIR74IEHsn2bvWvEMx02ksw777x5/rYnCRaHdXwj5MEHH5xn1u4ztEJoG0sIk2YIbU+TbKSw2bx272E3jNYYjMDPPvtsln366ad53rbiNp/N9065OrJDGzjW+azT2WXHus17tWvffffNd9zWoffff//cQZ5//vn8VMQIXOvQzRLaur3N7UZmI+1nn32WTRkJLZl22XFr44ettVnZisl8MtJbp7InLTbz2jxrBWhrbBS65ZZb8s2UzbZGBjvybZSw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';
    await PrinterService().printTestQr(ip, testQrBase64);
  }

  /// Formatea una tabla de factura con columnas alineadas.
  /// Detecta automáticamente las columnas y las alinea correctamente.
  String formatInvoiceTable(String tableContent) {
    final lines = tableContent.split('\n');
    final formattedLines = <String>[];

    // Definir anchos de columnas (ajustar según tu impresora)
    const int maxWidth = 32; // Ancho máximo de la impresora
    const int col1Width = 15; // Artículo
    const int col2Width = 6; // Cantidad
    const int col3Width = 6; // Valor
    const int col4Width = 8; // Total

    Logger.log('📊 Formateando tabla de factura:');
    Logger.log('   - Ancho máximo: $maxWidth caracteres');
    Logger.log('   - Columna 1 (Artículo): $col1Width caracteres');
    Logger.log('   - Columna 2 (Cantidad): $col2Width caracteres');
    Logger.log('   - Columna 3 (Valor): $col3Width caracteres');
    Logger.log('   - Columna 4 (Total): $col4Width caracteres');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // Detectar si es el encabezado de la tabla
      if (line.toLowerCase().contains('articulo') ||
          line.toLowerCase().contains('cant') ||
          line.toLowerCase().contains('valor') ||
          line.toLowerCase().contains('total')) {
        // Formatear encabezado
        String formattedHeader = _formatTableRow(
          ['Artículo', 'Can', 'Valor', 'Total'],
          [col1Width, col2Width, col3Width, col4Width],
        );
        formattedLines.add(formattedHeader);
        Logger.log('   - 📋 Encabezado formateado: "$formattedHeader"');
        continue;
      }

      // Detectar líneas de productos (empiezan con guión o tienen números)
      if (line.startsWith('-') ||
          line.contains('\$') ||
          line.contains(RegExp(r'[0-9]'))) {
        // Extraer datos de la línea
        List<String> columns = _extractTableColumns(line);

        if (columns.length >= 4) {
          String formattedRow = _formatTableRow(columns, [
            col1Width,
            col2Width,
            col3Width,
            col4Width,
          ]);
          formattedLines.add(formattedRow);
          Logger.log('   - 📦 Fila de producto: "$formattedRow"');
        } else {
          // Si no tiene suficientes columnas, agregar como línea normal
          formattedLines.add(line);
          Logger.log('   - 📝 Línea normal: "$line"');
        }
        continue;
      }

      // Líneas de totales o subtotales
      if (line.contains('TOTAL') ||
          line.contains('SUBTOTAL') ||
          line.contains('---------')) {
        // Alinear totales a la derecha
        String formattedTotal = _formatTotalLine(line, maxWidth);
        formattedLines.add(formattedTotal);
        Logger.log('   - 💰 Línea de total: "$formattedTotal"');
        continue;
      }

      // Otras líneas (descripciones, etc.)
      formattedLines.add(line);
      Logger.log('   - 📄 Línea descriptiva: "$line"');
    }

    return formattedLines.join('\n');
  }

  /// Extrae las columnas de una línea de tabla.
  List<String> _extractTableColumns(String line) {
    // Remover guión inicial si existe
    String cleanLine = line.startsWith('-') ? line.substring(1).trim() : line;

    // Dividir por espacios múltiples
    List<String> parts = cleanLine.split(RegExp(r'\s+'));

    if (parts.length >= 4) {
      // Caso típico: Artículo Cantidad Valor Total
      return [
        parts[0], // Artículo
        parts[1], // Cantidad
        parts[2], // Valor
        parts[3], // Total
      ];
    } else if (parts.length == 3) {
      // Caso con 3 columnas
      return [
        parts[0], // Artículo
        parts[1], // Cantidad
        parts[2], // Valor
        '', // Total vacío
      ];
    } else if (parts.length == 2) {
      // Caso con 2 columnas
      return [
        parts[0], // Artículo
        parts[1], // Cantidad
        '', // Valor vacío
        '', // Total vacío
      ];
    }

    // Si no se puede parsear, devolver la línea completa en la primera columna
    return [cleanLine, '', '', ''];
  }

  /// Formatea una fila de tabla con columnas alineadas.
  String _formatTableRow(List<String> columns, List<int> widths) {
    String result = '';

    for (int i = 0; i < columns.length && i < widths.length; i++) {
      String column = columns[i];
      int width = widths[i];

      // Truncar si es muy largo
      if (column.length > width) {
        column = column.substring(0, width - 1) + '...';
      }

      // Alinear a la izquierda para la primera columna, derecha para las demás
      if (i == 0) {
        // Artículo: alinear a la izquierda
        result += column.padRight(width);
      } else {
        // Cantidad, Valor, Total: alinear a la derecha
        result += column.padLeft(width);
      }
    }

    return result;
  }

  /// Formatea una línea de total alineada a la derecha.
  String _formatTotalLine(String line, int maxWidth) {
    // Remover espacios extra
    String cleanLine = line.trim();

    // Si es un separador, centrarlo
    if (cleanLine.replaceAll('-', '').isEmpty) {
      return cleanLine.padLeft((maxWidth + cleanLine.length) ~/ 2);
    }

    // Para totales, alinear a la derecha
    return cleanLine.padLeft(maxWidth);
  }
}

/// Clase para representar una línea a imprimir.
class PrintLine {
  final String text;
  final PosAlign align;
  final bool bold;
  final bool isImage;
  final List<int>? imageBytes;
  PrintLine({
    required this.text,
    this.align = PosAlign.left,
    this.bold = false,
    this.isImage = false,
    this.imageBytes,
  });
}

/// Función mejorada para procesar contenido desde la web con etiquetas HTML.
/// Maneja etiquetas como <center>, <negrita>, <imagen_grande> y caracteres de escape.
/// Omite la primera línea ya que se usa como título.
String processWebContent(String rawContent) {
  Logger.log('🔄 Procesando contenido web mejorado:');
  Logger.log('   - Longitud original: ${rawContent.length} caracteres');

  // 1. Normalizar caracteres de escape
  String processedContent = rawContent
      .replaceAll('\\n', '\n') // Convertir \\n a saltos de línea reales
      .replaceAll('\\t', '\t') // Convertir \\t a tabulaciones
      .replaceAll('\\r', '\r'); // Convertir \\r a retornos de carro

  // 2. Normalizar saltos de línea
  processedContent = processedContent
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  Logger.log(
    '   - Después de normalizar escapes: ${processedContent.length} caracteres',
  );

  // 3. Procesar etiquetas HTML
  final lines = processedContent.split('\n');
  final processedLines = <String>[];

  // Omitir la primera línea ya que se usa como título
  bool isFirstLine = true;

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i].trim();
    if (line.isEmpty) continue;

    // Omitir la primera línea no vacía (título)
    if (isFirstLine) {
      Logger.log(
        '   - Línea ${i + 1}: [TÍTULO] "${line.substring(0, line.length > 50 ? 50 : line.length)}${line.length > 50 ? '...' : ''}" - OMITIDA',
      );
      isFirstLine = false;
      continue;
    }

    // Procesar etiquetas de formato
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
      processedLines.add(
        line,
      ); // Mantener la línea original para procesamiento posterior
      Logger.log('   - Línea ${i + 1}: [IMAGEN QR] detectada');
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

      processedLines.add(formattedLine);
      Logger.log(
        '   - Línea ${i + 1}: ${isCentered ? '[CENTRADA] ' : ''}${isBold ? '[NEGRITA] ' : ''}"${line.substring(0, line.length > 30 ? 30 : line.length)}${line.length > 30 ? '...' : ''}"',
      );
    }
  }

  final result = processedLines.join('\n');
  Logger.log(
    '   - Resultado final: ${result.length} caracteres, ${processedLines.length} líneas',
  );
  return result;
}

/// Función para formatear el contenido de la factura en líneas imprimibles.
/// Maneja diferentes tipos de saltos de línea y procesa marcadores de formato.
List<PrintLine> formatInvoiceContent(String content) {
  final lines = <PrintLine>[];

  // Normalizar saltos de línea para consistencia
  String normalizedContent = content
      .replaceAll('\r\n', '\n') // Convertir Windows CRLF a LF
      .replaceAll('\r', '\n'); // Convertir Mac OS 9 CR a LF

  final splitted = normalizedContent.split('\n');

  Logger.log('📄 Procesando líneas para impresión:');
  Logger.log('   - Líneas a procesar: ${splitted.length}');

  for (int i = 0; i < splitted.length; i++) {
    String line = splitted[i].trim();
    if (line.isEmpty) {
      Logger.log('   - Línea ${i + 1}: [VACÍA] - omitida');
      continue;
    }

    Logger.log(
      '   - Línea ${i + 1}: "${line.substring(0, line.length > 40 ? 40 : line.length)}${line.length > 40 ? '...' : ''}"',
    );

    // Imagen grande (QR u otra)
    if (line.startsWith('<imagen_grande>')) {
      // Extraer el contenido después de la etiqueta
      String qrData = line.substring('<imagen_grande>'.length);

      // Limpiar caracteres de escape y espacios
      qrData = qrData
          .replaceAll('\\n', '') // Remover \\n
          .replaceAll('\\t', '') // Remover \\t
          .replaceAll('\\r', '') // Remover \\r
          .replaceAll(' ', ''); // Remover espacios

      // Si contiene " Fecha Impresion ", solo tomar hasta ahí
      final fechaIdx = qrData.indexOf('FechaImpresion');
      if (fechaIdx != -1) {
        qrData = qrData.substring(0, fechaIdx);
      }

      Logger.log('   - 🔍 QR data limpia: ${qrData.length} caracteres');

      if (qrData.isNotEmpty) {
        try {
          final imageBytes = base64Decode(qrData);
          lines.add(PrintLine(text: '', isImage: true, imageBytes: imageBytes));
          Logger.log('   - 🖼️ Imagen QR agregada: ${imageBytes.length} bytes');
        } catch (e) {
          Logger.log('   - ❌ Error decodificando QR: $e');
          Logger.log(
            '   - 🔍 QR data problemática: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}',
          );
          lines.add(
            PrintLine(text: '[IMAGEN NO VÁLIDA]', align: PosAlign.center),
          );
        }
      } else {
        lines.add(PrintLine(text: '[IMAGEN QR]', align: PosAlign.center));
        Logger.log('   - ⚠️ QR vacío detectado');
      }
      continue;
    }

    // Procesar líneas con marcadores de formato
    String processedLine = line;
    bool isBold = false;
    bool isCentered = false;
    PosAlign alignment = PosAlign.left;

    // Extraer marcadores de formato
    if (processedLine.startsWith('[CENTER][BOLD]')) {
      isCentered = true;
      isBold = true;
      processedLine = processedLine.substring('[CENTER][BOLD]'.length);
      Logger.log('   - 📍🔤 Marcadores [CENTER][BOLD] detectados');
    } else if (processedLine.startsWith('[BOLD][CENTER]')) {
      isBold = true;
      isCentered = true;
      processedLine = processedLine.substring('[BOLD][CENTER]'.length);
      Logger.log('   - 🔤📍 Marcadores [BOLD][CENTER] detectados');
    } else if (processedLine.startsWith('[CENTER]')) {
      isCentered = true;
      processedLine = processedLine.substring('[CENTER]'.length);
      Logger.log('   - 📍 Marcador [CENTER] detectado');
    } else if (processedLine.startsWith('[BOLD]')) {
      isBold = true;
      processedLine = processedLine.substring('[BOLD]'.length);
      Logger.log('   - 🔤 Marcador [BOLD] detectado');
    }

    // Limpiar espacios extra
    processedLine = processedLine.trim();

    // Determinar alineación
    if (isCentered) {
      alignment = PosAlign.center;
    }

    // Separador - siempre centrado
    if (processedLine.replaceAll('-', '').isEmpty && processedLine.length > 5) {
      lines.add(PrintLine(text: processedLine, align: PosAlign.center));
      Logger.log('   - ➖ Separador agregado (centrado)');
      continue;
    }

    // Solo agregar línea si tiene contenido
    if (processedLine.isNotEmpty) {
      lines.add(PrintLine(text: processedLine, align: alignment, bold: isBold));
      Logger.log(
        '   - ✅ Línea agregada: ${isBold ? 'NEGRITA ' : ''}${isCentered ? 'CENTRADA ' : ''}"${processedLine.substring(0, processedLine.length > 30 ? 30 : processedLine.length)}${processedLine.length > 30 ? '...' : ''}"',
      );
    }
  }

  Logger.log('📄 Resultado: ${lines.length} líneas procesadas para impresión');
  return lines;
}
