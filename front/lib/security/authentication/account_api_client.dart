part of 'autenticacao_controller.dart';

class _FolhioContaApiClient {
  const _FolhioContaApiClient(this._authApi);

  final _FolhioAutenticacaoApiClient _authApi;

  Future<FolhioUsuario> atualizarNomeExibicao(String name) async {
    final data = await _authApi.atualizarParcialmente(RotasApiFolhio.profile, {'name': name});
    return FolhioUsuario.deJson(data);
  }

  Future<void> esqueciSenha(String email) {
    return _authApi
        ._enviarPost(RotasApiFolhio.forgotPassword, {'email': email})
        .then((_) {});
  }

  Future<void> redefinirSenha({
    required String token,
    required String newPassword,
  }) {
    return _authApi
        ._enviarPost(RotasApiFolhio.resetPassword, {
          'token': token,
          'newPassword': newPassword,
        })
        .then((_) {});
  }

  Future<FolhioResultadoAtualizacaoConta> atualizarConta({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    final data = await _authApi.atualizarParcialmente(RotasApiFolhio.account, {
      'name': name,
      'email': email,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'twoFactorToken': twoFactorToken,
      'twoFactorCode': twoFactorCode,
    });
    return FolhioResultadoAtualizacaoConta.deJson(data);
  }

  Future<FolhioResultadoAtualizacaoConta> excluirConta({
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    final data = await _authApi.excluir(RotasApiFolhio.account, {
      'currentPassword': currentPassword,
      'twoFactorToken': twoFactorToken,
      'twoFactorCode': twoFactorCode,
    });
    return FolhioResultadoAtualizacaoConta.deJson(data);
  }
}
