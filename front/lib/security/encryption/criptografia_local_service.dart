import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CriptografiaLocalService {
  CriptografiaLocalService._();

  static final CriptografiaLocalService instance = CriptografiaLocalService._();

  static const textPrefix = 'folhio:enc:v1:';
  static final Uint8List bytesPrefix = Uint8List.fromList(
    utf8.encode('FOLHIOENC1\n'),
  );

  static const _keyStorageKey = 'folhio.local.masterKey.v1';
  static final _storage = FlutterSecureStorage();

  final AesGcm _cipher = AesGcm.with256bits();
  SecretKey? _cachedKey;

  bool ehTextoCriptografado(String value) => value.startsWith(textPrefix);

  bool ehBytesCriptografados(List<int> value) {
    if (value.length < bytesPrefix.length) return false;
    for (var index = 0; index < bytesPrefix.length; index += 1) {
      if (value[index] != bytesPrefix[index]) return false;
    }
    return true;
  }

  Future<String> criptografarTexto(String value) async {
    if (value.isEmpty || ehTextoCriptografado(value)) return value;
    final box = await _cipher.encrypt(
      utf8.encode(value),
      secretKey: await _chaveSecreta(),
    );
    final envelope = _caixaSegredoParaJson(box);
    return '$textPrefix${_base64UrlSemEspacamento(utf8.encode(jsonEncode(envelope)))}';
  }

  Future<String?> criptografarTextoOpcional(String? value) async {
    if (value == null) return null;
    return criptografarTexto(value);
  }

  Future<String> descriptografarTexto(String value) async {
    if (value.isEmpty || !ehTextoCriptografado(value)) return value;
    try {
      final encodedEnvelope = value.substring(textPrefix.length);
      final envelopeText = utf8.decode(
        _base64UrlDecodificarSemEspacamento(encodedEnvelope),
      );
      final envelope = jsonDecode(envelopeText);
      if (envelope is! Map<String, dynamic>) return value;
      final bytes = await _cipher.decrypt(
        _caixaSegredoDeJson(envelope),
        secretKey: await _chaveSecreta(),
      );
      return utf8.decode(bytes);
    } catch (_) {
      return value;
    }
  }

  Future<String?> descriptografarTextoOpcional(String? value) async {
    if (value == null) return null;
    return descriptografarTexto(value);
  }

  Future<Uint8List> criptografarBytes(List<int> value) async {
    if (value.isEmpty || ehBytesCriptografados(value)) {
      return Uint8List.fromList(value);
    }
    final box = await _cipher.encrypt(value, secretKey: await _chaveSecreta());
    final builder = BytesBuilder(copy: false)
      ..add(bytesPrefix)
      ..add([box.nonce.length])
      ..add(box.nonce)
      ..add([(box.mac.bytes.length >> 8) & 0xff, box.mac.bytes.length & 0xff])
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    return builder.takeBytes();
  }

  Future<Uint8List> descriptografarBytesSeNecessario(List<int> value) async {
    if (value.isEmpty || !ehBytesCriptografados(value)) {
      return Uint8List.fromList(value);
    }
    try {
      var offset = bytesPrefix.length;
      if (value.length <= offset) return Uint8List.fromList(value);
      final nonceLength = value[offset];
      offset += 1;
      if (value.length < offset + nonceLength + 2) {
        return Uint8List.fromList(value);
      }
      final nonce = value.sublist(offset, offset + nonceLength);
      offset += nonceLength;

      final macLength = (value[offset] << 8) | value[offset + 1];
      offset += 2;
      if (value.length < offset + macLength) return Uint8List.fromList(value);
      final mac = value.sublist(offset, offset + macLength);
      offset += macLength;

      final cipherText = value.sublist(offset);
      final bytes = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: await _chaveSecreta(),
      );
      return Uint8List.fromList(bytes);
    } catch (_) {
      return Uint8List.fromList(value);
    }
  }

  Future<SecretKey> _chaveSecreta() async {
    final cached = _cachedKey;
    if (cached != null) return cached;

    final stored = await _storage.read(key: _keyStorageKey);
    if (stored != null && stored.isNotEmpty) {
      final key = SecretKey(base64Decode(stored));
      _cachedKey = key;
      return key;
    }

    final keyBytes = Uint8List(32);
    final random = Random.secure();
    for (var index = 0; index < keyBytes.length; index += 1) {
      keyBytes[index] = random.nextInt(256);
    }
    await _storage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
    final key = SecretKey(keyBytes);
    _cachedKey = key;
    return key;
  }

  Map<String, Object> _caixaSegredoParaJson(SecretBox box) {
    return {
      'algorithm': 'AES-256-GCM',
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'cipherText': base64Encode(box.cipherText),
    };
  }

  SecretBox _caixaSegredoDeJson(Map<String, dynamic> json) {
    return SecretBox(
      base64Decode(json['cipherText'] as String),
      nonce: base64Decode(json['nonce'] as String),
      mac: Mac(base64Decode(json['mac'] as String)),
    );
  }

  String _base64UrlSemEspacamento(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Uint8List _base64UrlDecodificarSemEspacamento(String value) {
    final padding = (4 - value.length % 4) % 4;
    return base64Url.decode('$value${List.filled(padding, '=').join()}');
  }
}
