import 'package:shared_preferences/shared_preferences.dart';

bool isNotEmpty(String str) {
  return !(str?.isEmpty ?? true);
}

class Prefs {
  static SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setString(String key, dynamic value) async {
    if (_prefs == null) await init();
    return _prefs.setString(key, value);
  }

  static Future<String> getString(String key) async {
    if (_prefs == null) await init();
    return _prefs.getString(key);
  }

  static Future<bool> hasString(String key) async {
    if (_prefs == null) await init();
    return _prefs.containsKey(key) && isNotEmpty(_prefs.getString(key));
  }

  static Future<bool> has(String key) async {
    if (_prefs == null) await init();
    return _prefs.containsKey(key);
  }

  static Future<Set<String>> getKeys() async {
    if (_prefs == null) await init();
     return _prefs.getKeys();
  }

  static Future<List<String>> getList(String key) async {
    if (_prefs == null) await init();
    return _prefs.getStringList(key);
  }

  static Future<void> setList(String key, List<String> list) async {
    if (_prefs == null) await init();
    return _prefs.setStringList(key, list);
  }
}
