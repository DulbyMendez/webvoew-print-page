import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing persistent configuration settings.
class ConfigService {
  static const String _keyCodeTable = 'selected_code_table';
  static const String _keyNormalizeChars = 'normalize_characters';
  static const String _keyFullNormalization = 'full_normalization';
  static const String _keyDefaultPrinterIP = 'default_printer_ip';

  /// Gets the saved code table configuration.
  static Future<String> getCodeTable() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCodeTable) ?? 'CP1252'; // Default to CP1252
  }

  /// Saves the code table configuration.
  static Future<void> setCodeTable(String codeTable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCodeTable, codeTable);
  }

  /// Gets the normalize characters setting.
  static Future<bool> getNormalizeCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNormalizeChars) ?? true; // Default to true
  }

  /// Saves the normalize characters setting.
  static Future<void> setNormalizeCharacters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNormalizeChars, value);
  }

  /// Gets the full normalization setting.
  static Future<bool> getFullNormalization() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFullNormalization) ?? false; // Default to false
  }

  /// Saves the full normalization setting.
  static Future<void> setFullNormalization(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFullNormalization, value);
  }

  /// Gets the default printer IP.
  static Future<String> getDefaultPrinterIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultPrinterIP) ?? '192.168.1.13';
  }

  /// Saves the default printer IP.
  static Future<void> setDefaultPrinterIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultPrinterIP, ip);
  }

  /// Saves all configuration settings at once.
  static Future<void> saveConfig({
    required String codeTable,
    required bool normalizeChars,
    required bool fullNormalization,
    String? defaultPrinterIP,
  }) async {
    await setCodeTable(codeTable);
    await setNormalizeCharacters(normalizeChars);
    await setFullNormalization(fullNormalization);
    if (defaultPrinterIP != null) {
      await setDefaultPrinterIP(defaultPrinterIP);
    }
  }

  /// Loads all configuration settings.
  static Future<Map<String, dynamic>> loadConfig() async {
    return {
      'codeTable': await getCodeTable(),
      'normalizeChars': await getNormalizeCharacters(),
      'fullNormalization': await getFullNormalization(),
      'defaultPrinterIP': await getDefaultPrinterIP(),
    };
  }

  /// Clears all saved configuration.
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCodeTable);
    await prefs.remove(_keyNormalizeChars);
    await prefs.remove(_keyFullNormalization);
    await prefs.remove(_keyDefaultPrinterIP);
  }
}
