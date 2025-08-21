import 'package:hive_flutter/hive_flutter.dart';

class SessionService {
  static const _boxName = 'sessionBox';
  static const _keyUsername = 'username';
  static const _keyUserData = 'userData';
  static const _keyAuthToken = 'authToken';

  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  Future<void> saveUserSession(String username) async {
    final box = await _openBox();
    await box.put(_keyUsername, username);
  }

  Future<String?> getUsername() async {
    final box = await _openBox();
    return box.get(_keyUsername);
  }

  Future<bool> isLoggedIn() async {
    final username = await getUsername();
    return username != null && username.isNotEmpty;
  }

  Future<void> clearSession() async {
    final box = await _openBox();

    await box.delete(_keyUsername);
    await box.delete(_keyUserData);
    await box.delete(_keyAuthToken);

   await box.clear();

  }


}