/// Service for managing print jobs and preventing multiple simultaneous prints.
class PrintJobManager {
  bool _isPrinting = false;
  DateTime? _lastPrintTime;
  final int _minIntervalMs =
      1000; // Minimum time between prints in milliseconds

  /// Checks if a new print job can be started.
  bool get canPrint {
    if (_isPrinting) {
      print('⚠️ Impresión en progreso, ignorando nueva solicitud');
      return false;
    }

    if (_lastPrintTime != null) {
      final timeSinceLastPrint =
          DateTime.now().difference(_lastPrintTime!).inMilliseconds;
      if (timeSinceLastPrint < _minIntervalMs) {
        print('⚠️ Impresión muy reciente (${timeSinceLastPrint}ms), ignorando');
        return false;
      }
    }

    return true;
  }

  /// Gets the current printing status.
  bool get isPrinting => _isPrinting;

  /// Gets the time since the last print job.
  Duration? get timeSinceLastPrint {
    if (_lastPrintTime == null) return null;
    return DateTime.now().difference(_lastPrintTime!);
  }

  /// Sets the printing status and updates the last print time.
  void setPrintingStatus(bool isPrinting) {
    _isPrinting = isPrinting;
    if (isPrinting) {
      _lastPrintTime = DateTime.now();
      print('🖨️ Estado de impresión: INICIADO');
    } else {
      print('🖨️ Estado de impresión: FINALIZADO');
    }
  }

  /// Resets the print job manager state.
  void reset() {
    _isPrinting = false;
    _lastPrintTime = null;
    print('🔄 Estado de impresión reseteado');
  }

  /// Gets a summary of the current print job status.
  String getStatusSummary() {
    if (_isPrinting) {
      return '🖨️ Impresión en progreso';
    }

    if (_lastPrintTime != null) {
      final timeSince = timeSinceLastPrint!;
      return '✅ Última impresión: ${timeSince.inSeconds} segundos atrás';
    }

    return '⏸️ Sin impresiones recientes';
  }

  /// Validates print data before processing.
  static bool validatePrintData({
    required String content,
    required List<Map<String, dynamic>> printers,
  }) {
    if (content.trim().isEmpty) {
      print('❌ Validación fallida: contenido vacío');
      return false;
    }

    if (printers.isEmpty) {
      print('❌ Validación fallida: no hay impresoras configuradas');
      return false;
    }

    for (final printer in printers) {
      final ip = printer['ip']?.toString().trim();
      if (ip == null || ip.isEmpty) {
        print('❌ Validación fallida: IP de impresora inválida');
        return false;
      }

      final copies = printer['copies'];
      if (copies == null || copies < 1) {
        print('❌ Validación fallida: número de copias inválido');
        return false;
      }
    }

    print('✅ Validación de datos de impresión exitosa');
    return true;
  }

  /// Formats print job information for logging.
  static String formatPrintJobInfo({
    required String title,
    required String content,
    required List<Map<String, dynamic>> printers,
  }) {
    final totalCopies = printers.fold<int>(
      0,
      (sum, printer) => sum + (printer['copies'] as int),
    );

    return '''
📋 Información del trabajo de impresión:
   Título: $title
   Contenido: ${content.length} caracteres
   Impresoras: ${printers.length}
   Copias totales: $totalCopies
   Timestamp: ${DateTime.now().toIso8601String()}
''';
  }

  /// Validates invoice data specifically for invoice printing.
  static bool validateInvoiceData({
    required String content,
    required String title,
    required List<Map<String, dynamic>> printers,
  }) {
    // Validar datos básicos
    if (!validatePrintData(content: content, printers: printers)) {
      return false;
    }

    // Validar título
    if (title.trim().isEmpty) {
      print('❌ Validación de factura fallida: título vacío');
      return false;
    }

    // Verificar si contiene elementos de factura
    final hasInvoiceElements =
        content.contains('FACTURA') ||
        content.contains('NIT:') ||
        content.contains('TOTAL:') ||
        content.contains('SUBTOTAL:');

    if (!hasInvoiceElements) {
      print('⚠️ Advertencia: El contenido no parece ser una factura');
    }

    // Verificar si contiene imagen QR
    final hasQRImage = content.contains('<imagen_grande>');
    if (hasQRImage) {
      print('✅ Factura con imagen QR detectada');
    } else {
      print('⚠️ Advertencia: No se detectó imagen QR en la factura');
    }

    print('✅ Validación de factura exitosa');
    return true;
  }

  /// Formats invoice job information for logging.
  static String formatInvoiceJobInfo({
    required String title,
    required String content,
    required List<Map<String, dynamic>> printers,
  }) {
    final totalCopies = printers.fold<int>(
      0,
      (sum, printer) => sum + (printer['copies'] as int),
    );

    final hasQRImage = content.contains('<imagen_grande>');
    final hasInvoiceElements =
        content.contains('FACTURA') ||
        content.contains('NIT:') ||
        content.contains('TOTAL:');

    return '''
🧾 Información del trabajo de impresión de factura:
   Título: $title
   Contenido: ${content.length} caracteres
   Impresoras: ${printers.length}
   Copias totales: $totalCopies
   Contiene QR: ${hasQRImage ? 'Sí' : 'No'}
   Elementos de factura: ${hasInvoiceElements ? 'Sí' : 'No'}
   Timestamp: ${DateTime.now().toIso8601String()}
''';
  }
}
