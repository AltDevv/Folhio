part of 'autenticacao_controller.dart';

class _FolhioSessaoAutenticacaoSnapshot {
  final FolhioUsuario? user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpiresAt;

  const _FolhioSessaoAutenticacaoSnapshot({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  bool get isSignedIn => user != null && accessToken != null;
}

class _FolhioSessaoAutenticacaoStore {
  const _FolhioSessaoAutenticacaoStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<_FolhioSessaoAutenticacaoSnapshot> ler() async {
    final accessToken = await _storage.read(key: 'auth.accessToken');
    final refreshToken = await _storage.read(key: 'auth.refreshToken');
    final expiresAt = DateTime.tryParse(
      await _storage.read(key: 'auth.accessTokenExpiresAt') ?? '',
    );
    final userJson = await _storage.read(key: 'auth.user');
    final user = userJson == null
        ? null
        : FolhioUsuario.deJson(jsonDecode(userJson) as Map<String, dynamic>);

    return _FolhioSessaoAutenticacaoSnapshot(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: expiresAt,
    );
  }

  Future<void> salvar({
    required FolhioUsuario user,
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
  }) async {
    await _storage.write(key: 'auth.accessToken', value: accessToken);
    await _storage.write(key: 'auth.refreshToken', value: refreshToken);
    await _storage.write(
      key: 'auth.accessTokenExpiresAt',
      value: accessTokenExpiresAt.toIso8601String(),
    );
    await salvarUsuario(user);
  }

  Future<void> salvarUsuario(FolhioUsuario user) {
    return _storage.write(key: 'auth.user', value: jsonEncode(user.toJson()));
  }

  Future<void> limpar() async {
    await _storage.delete(key: 'auth.accessToken');
    await _storage.delete(key: 'auth.refreshToken');
    await _storage.delete(key: 'auth.accessTokenExpiresAt');
    await _storage.delete(key: 'auth.user');
  }
}
