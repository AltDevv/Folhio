import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CriptografiaBackupService {
  CriptografiaBackupService._();

  static final CriptografiaBackupService instance = CriptografiaBackupService._();

  static const String encryptedFormat = 'folhio-encrypted-backup';
  static const String plainFormat = 'folhio-local-first-backup';
  static const String _keyStorageKey = 'folhio.backup.masterKey.v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final AesGcm _cipher = AesGcm.with256bits();

  Future<Map<String, Object?>> criptografarBackup(
    Map<String, Object?> payload,
  ) async {
    final secretKey = await _chaveSecreta();
    final clearBytes = utf8.encode(jsonEncode(payload));
    final secretBox = await _cipher.encrypt(clearBytes, secretKey: secretKey);

    return {
      'format': encryptedFormat,
      'version': 1,
      'algorithm': 'AES-256-GCM',
      'createdAt': DateTime.now().toIso8601String(),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
      'cipherText': base64Encode(secretBox.cipherText),
    };
  }

  Future<Map<String, dynamic>> descriptografarBackup(
    Map<String, dynamic> encrypted,
  ) async {
    if (encrypted['format'] != encryptedFormat) {
      return encrypted;
    }

    final secretKey = await _chaveSecreta();
    final secretBox = SecretBox(
      base64Decode(_textoObrigatorio(encrypted, 'cipherText')),
      nonce: base64Decode(_textoObrigatorio(encrypted, 'nonce')),
      mac: Mac(base64Decode(_textoObrigatorio(encrypted, 'mac'))),
    );
    final clearBytes = await _cipher.decrypt(secretBox, secretKey: secretKey);
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map<String, dynamic> || decoded['format'] != plainFormat) {
      throw const FormatException('Backup descriptografado inválido.');
    }
    return decoded;
  }

  Future<SecretKey> _chaveSecreta() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }

    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(key: _keyStorageKey, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  String _textoObrigatorio(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Backup criptografado sem campo obrigatório: $key.');
  }
}
