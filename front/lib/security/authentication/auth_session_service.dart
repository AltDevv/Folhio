part of 'autenticacao_controller.dart';

class _FolhioSessaoAutenticacaoService {
  const _FolhioSessaoAutenticacaoService(this._store);

  final _FolhioSessaoAutenticacaoStore _store;

  Future<_FolhioSessaoAutenticacaoSnapshot> salvarRespostaAutenticacao(
    Map<String, dynamic> data,
  ) async {
    final user = FolhioUsuario.deJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw const FolhioAutenticacaoException('Resposta de login incompleta.');
    }

    final expiresInSeconds = data['expiresInSeconds'] is num
        ? (data['expiresInSeconds'] as num).toInt()
        : 1200;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));

    await _store.salvar(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: expiresAt,
    );
    await atualizarPerfilUsuario(user);
    await sincronizarAposEntrada();

    return _FolhioSessaoAutenticacaoSnapshot(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: expiresAt,
    );
  }

  Future<void> atualizarPerfilUsuario(FolhioUsuario user) async {
    await _store.salvarUsuario(user);
    await PersistenciaLocalRepository.instance.definirConfiguracao('profile.name', user.name);
  }

  Future<void> limparSessaoLocal() async {
    await _store.limpar();
  }

  Future<void> sincronizarAposEntrada() async {
    return;
  }

  bool ehErroConexao(Object error) {
    return error is FolhioAutenticacaoException &&
        error.message.contains('Não foi possível conectar');
  }
}
