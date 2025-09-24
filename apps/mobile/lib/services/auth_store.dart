import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStore extends ChangeNotifier {
  AuthStore._(this._prefs);
  final SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';
  static const _deviceIdKey = 'device_id';

  String? _token;
  String? _role; // STUDENT | TEACHER | ADMIN
  String? _userId;
  String? _deviceId;

  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;
  String get deviceId => _deviceId ??= _ensureDeviceId();
  bool get isAuthenticated => _token != null;

  static Future<AuthStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AuthStore._(prefs);
    store._token = prefs.getString(_tokenKey);
    store._role = prefs.getString(_roleKey);
    store._userId = prefs.getString(_userIdKey);
    store._deviceId = prefs.getString(_deviceIdKey);
    return store;
  }

  Future<void> setAuth({required String token, required String role, required String userId}) async {
    _token = token;
    _role = role;
    _userId = userId;
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_roleKey, role);
    await _prefs.setString(_userIdKey, userId);
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _role = null;
    _userId = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_roleKey);
    await _prefs.remove(_userIdKey);
    notifyListeners();
  }

  String _ensureDeviceId() {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final id = base64Url.encode(List<int>.generate(16, (i) => i * 37 % 256));
    _prefs.setString(_deviceIdKey, id);
    return id;
  }
}

