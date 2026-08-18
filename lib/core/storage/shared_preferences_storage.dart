import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';

final class SharedPreferencesStorage implements LocalStorage {
  const SharedPreferencesStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  bool? getBool(String key) => _preferences.getBool(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> clear() => _preferences.clear();
}
