part of 'autenticacao_controller.dart';

class _FolhioDoisFatoresApiClient {
  const _FolhioDoisFatoresApiClient(this._authApi);

  final _FolhioAutenticacaoApiClient _authApi;

  Future<Map<String, dynamic>> verificar({
    required String token,
    required String code,
  }) {
    return _authApi._enviarPost(RotasApiFolhio.verifyTwoFactor, {
      'twoFactorToken': token,
      'code': code,
    });
  }

  Future<FolhioConfiguracoesDoisFatores> configuracoes() async {
    final data = await _authApi.obter(RotasApiFolhio.twoFactor);
    return FolhioConfiguracoesDoisFatores.deJson(data);
  }

  Future<FolhioConfiguracoesDoisFatores> atualizar({
    required bool enabled,
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    final data = await _authApi.atualizarParcialmente(RotasApiFolhio.twoFactor, {
      'enabled': enabled,
      'method': 'email',
      'currentPassword': currentPassword,
      'twoFactorToken': twoFactorToken,
      'twoFactorCode': twoFactorCode,
    });
    return FolhioConfiguracoesDoisFatores.deJson(data);
  }
}
