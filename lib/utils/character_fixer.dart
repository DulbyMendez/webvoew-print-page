// Archivo para funciones de normalización y corrección de caracteres.

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
/// causan problemas en impresoras (puntuación especial, símbolos, emojis),
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

  // Remover emojis y caracteres Unicode no compatibles con CP1252
  // Usar un enfoque más simple y seguro
  normalized = _removeUnicodeCharacters(normalized);

  // Limpiar caracteres no imprimibles (control characters)
  normalized = normalized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  // Limpiar espacios múltiples
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

  // Limpiar espacios al inicio y final
  normalized = normalized.trim();

  return normalized;
}

/// Función auxiliar para remover caracteres Unicode de forma segura
String _removeUnicodeCharacters(String text) {
  String result = '';
  for (int i = 0; i < text.length; i++) {
    int code = text.codeUnitAt(i);
    // Solo mantener caracteres en el rango CP1252 (0x00-0xFF)
    if (code <= 0xFF) {
      result += text[i];
    }
    // Para caracteres Unicode que requieren 2 code units (surrogate pairs)
    else if (code >= 0xD800 && code <= 0xDBFF && i + 1 < text.length) {
      // Es el primer code unit de un surrogate pair, saltar al siguiente
      i++;
    }
    // Para otros caracteres Unicode, simplemente omitirlos
  }
  return result;
}
