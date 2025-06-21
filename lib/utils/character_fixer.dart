// Archivo para funciones de normalización y corrección de caracteres.
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Limpia el texto crudo que viene del WebView de Android.
///
/// Android puede enviar caracteres de escape como strings literales (p. ej., "\\n").
/// Esta función los convierte a sus contrapartes reales.
String cleanAndroidText(String text) {
  // Aplicar solo si la plataforma es Android.
  if (!kIsWeb && Platform.isAndroid) {
    String cleanedText = text
        .replaceAll(r'\\n', '\n') // Reemplaza la secuencia literal '\\n' por un salto de línea.
        .replaceAll(r'\\r', '\r') // Reemplaza la secuencia literal '\\r' por un retorno de carro.
        .replaceAll(r'\\t', '\t'); // Reemplaza la secuencia literal '\\t' por un tabulador.
    return cleanedText;
  }
  // Si no es Android, devuelve el texto sin modificar.
  return text;
}

/// Contiene funciones para la normalización y corrección de cadenas de texto
/// antes de ser enviadas a la impresora.

/// Normaliza un texto reemplazando un amplio conjunto de caracteres especiales
/// por sus equivalentes ASCII. Ideal para impresoras con soporte de caracteres muy limitado.
String normalizeText(String text) {
  if (text.isEmpty) return text;

  // Mapeo de caracteres especiales específicos para Latinoamérica
  // Solo reemplazar caracteres que realmente causan problemas en impresoras ESC/POS
  final Map<String, String> charMap = {
    // Caracteres que suelen causar problemas en impresoras ESC/POS
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
    'ñ': 'n', 'Ñ': 'N', 'ü': 'u', 'Ü': 'U',
    '¿': '?', '¡': '!', '«': '"', '»': '"', '…': '...',
    '–': '-', '—': '-', '°': 'o', '€': 'EUR', '¢': 'cent', '£': 'GBP',
    '¥': 'JPY', '§': 'S', '©': '(c)', '®': '(R)', '™': '(TM)', '±': '+/-',
    '×': 'x', '÷': '/', '≤': '<=', '≥': '>=', '≠': '!=', '≈': '~',
    '∞': 'inf', '√': 'sqrt', '²': '2', '³': '3', '¼': '1/4', '½': '1/2',
    '¾': '3/4', 'µ': 'u',
    // Caracteres griegos
    'α': 'a', 'β': 'b', 'γ': 'g', 'δ': 'd', 'ε': 'e',
    'θ': 'theta',
    'λ': 'lambda',
    'π': 'pi',
    'σ': 'sigma',
    'φ': 'phi',
    'ω': 'omega',
  };

  String normalized = text;

  // Aplicar mapeo de caracteres problemáticos
  charMap.forEach((special, replacement) {
    normalized = normalized.replaceAll(special, replacement);
  });

  // Limpiar caracteres no imprimibles (control characters)
  normalized = normalized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  // Limpiar espacios múltiples
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

  // Limpiar espacios al inicio y final
  normalized = normalized.trim();

  return normalized;
}

/// Normaliza un texto reemplazando solo los caracteres que comúnmente
/// causan problemas en impresoras (puntuación especial, símbolos),
/// pero intenta preservar los caracteres acentuados del español.
String normalizeSpanishText(String text) {
  if (text.isEmpty) return text;

  // Solo reemplazar caracteres que realmente causan problemas
  // Mantener á,é,í,ó,ú,ñ,ü si la impresora los soporta
  final Map<String, String> spanishCharMap = {
    '¿': '?',
    '¡': '!',
    '«': '"',
    '»': '"',
    '…': '...',
    '–': '-',
    '—': '-',
    '°': 'o',
    '€': 'EUR',
    '¢': 'cent',
    '£': 'GBP',
    '¥': 'JPY',
    '§': 'S',
    '©': '(c)',
    '®': '(R)',
    '™': '(TM)',
    '±': '+/-',
    '×': 'x',
    '÷': '/',
    '≤': '<=',
    '≥': '>=',
    '≠': '!=',
    '≈': '~',
    '∞': 'inf',
    '√': 'sqrt',
    '²': '2',
    '³': '3',
    '¼': '1/4',
    '½': '1/2',
    '¾': '3/4',
    'µ': 'u',
  };

  String normalized = text;

  // Aplicar mapeo de caracteres problemáticos
  spanishCharMap.forEach((special, replacement) {
    normalized = normalized.replaceAll(special, replacement);
  });

  // Limpiar caracteres no imprimibles (control characters)
  normalized = normalized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  // Limpiar espacios múltiples
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

  // Limpiar espacios al inicio y final
  normalized = normalized.trim();

  return normalized;
}
