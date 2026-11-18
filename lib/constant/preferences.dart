import 'package:doctro/constant/prefConstatnt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      if ((value == null || value.isEmpty) &&
          legacy != null && legacy.isNotEmpty && legacy != 'N_A') {
        // Migration is only successful after durable keystore persistence.
        // Never trust a plaintext legacy token when secure storage fails.
        try {
          await _secureStorage.write(key: key, value: legacy);
          value = legacy;
        } catch (_) {
          value = null;
        }
      }
      if (legacy != null) {
        await _preferences!.remove(key);
      }
      if (value != null && value.isNotEmpty) {
        _secureCache[key] = value;
      } else {
        _secureCache.remove(key);
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
      // Do not report success if a revoked credential remains on disk.
      // Retain the in-memory token until deletion succeeds so callers can
      // distinguish an incomplete sign-out from a completed one.
      await _secureStorage.delete(key: key);
      _secureCache.remove(key);
      return true;
    }
    return await _preferences!.remove(key);
  }

  /// Await secure logout before navigating to a different account.
  static Future<void> clearPrefSecurely() async {
    // Revoke the durable credential before clearing the in-memory copy.
    // If keychain deletion fails, surface the error rather than reporting
    // a successful logout while a reusable token remains on disk.
    await _secureStorage.delete(key: Preferences.auth_token);
    _secureCache.remove(Preferences.auth_token);
    try {
      // Chat/Firestore must not remain signed in as the previous clinician.
      await FirebaseAuth.instance.signOut();
    } finally {
      // Clear cached profile/role information even when Firebase sign-out
      // fails, but preserve that failure for the caller to handle.
      await _preferences!.clear();
    }
  }

  /// Deprecated legacy API. Callers should await clearPrefSecurely() so
  /// navigation cannot race with credential and Firebase session deletion.
  @Deprecated('Use await clearPrefSecurely() for reliable logout.')
  static void clearPref() {
    // Preserve legacy call-site compatibility until every caller is audited.
    // A synchronous void method cannot guarantee logout completion.
    clearPrefSecurely();
  }
}
