import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around secure storage for the JWT.
class TokenStorage {
  static const _key = 'teamup_jwt';
  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> clear() => _storage.delete(key: _key);
}
