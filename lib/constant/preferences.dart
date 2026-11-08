import 'package:doctro/constant/prefConstatnt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static Future<SharedPreferences> get _instance async => _preferences ??= await SharedPreferences.getInstance();

  static SharedPreferences? _preferences;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );

  /// Keys kept in the platform keystore/keychain instead of cleartext SharedPreferences. They are mirrored in memory
  /// so [getString] can stay synchronous.
  static const List<String> _secureKeys = [Preferences.auth_token];

  static final Map<String, String> _secureCache = {};

  // call this method from iniState() function of mainApp().
  static Future<SharedPreferences?> init() async {
    _preferences = await _instance;
    // Remove passwords retained by legacy app versions before any reauthentication.
    await _preferences!.remove(Preferences.password);
    for (final key in _secureKeys) {
      String? value;
      try {
        value = await _secureStorage.read(key: key);
      } catch (_) {}
      final legacy = _preferences!.getString(key);
      if ((value == null || value.isEmpty) && legacy != null && legacy.isNotEmpty && legacy != 'N_A') {
        value = legacy;
        try {
          await _secureStorage.write(key: key, value: value);
        } catch (_) {}
      }
      if (legacy != null) {
        await _preferences!.remove(key);
      }
      if (value != null && value.isNotEmpty) {
        _secureCache[key] = value;
      }
    }
    return _preferences;
  }

  //sets
  static Future setBoolean(String key, bool value) async => await _preferences!.setBool(key, value);

  static Future<bool> setDouble(String key, double value) async => await _preferences!.setDouble(key, value);

  static Future<bool> setInt(String key, int value) async => await _preferences!.setInt(key, value);

  static Future<bool> setString(String key, String value) async {
    if (key == Preferences.password) {
      throw StateError('Storing a password in SharedPreferences is prohibited.');
    }
    if (_secureKeys.contains(key)) {
      // Never claim a successful login if keystore/keychain persistence fails.
      // Do not fall back to plaintext app preferences.
      await _secureStorage.write(key: key, value: value);
      _secureCache[key] = value;
      return true;
    }
    return await _preferences!.setString(key, value);
  }

  static Future<bool> setStringList(String key, List<String> value) async => await _preferences!.setStringList(key, value);

  //gets

  static bool getBoolean(String key) => _preferences!.getBool(key) ?? false;

  static double getDouble(String key) => _preferences!.getDouble(key) ?? 0.0;

  static int getInt(String key) => _preferences!.getInt(key) ?? 0;

  static String getString(String key) {
    if (_secureKeys.contains(key)) {
      return _secureCache[key] ?? 'N_A';
    }
    return _preferences?.getString(key) ?? 'N_A';
  }

  static List<String> getStringList(String key) => _preferences!.getStringList(key) ?? [];

  //deletes..
  static Future<bool> remove(String key) async {
    if (_secureKeys.contains(key)) {
      _secureCache.remove(key);
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
      return true;
    }
    return await _preferences!.remove(key);
  }

  /// Await secure logout before navigating to a different account.
  static Future<void> clearPrefSecurely() async {
    _secureCache.clear();
    try {
      await _secureStorage.delete(key: Preferences.auth_token);
    } finally {
      await _preferences!.clear();
    }
  }

  static void clearPref() {
    _preferences!.clear();
    _secureCache.clear();
    _secureStorage.deleteAll().catchError((_) {});
  }
}
