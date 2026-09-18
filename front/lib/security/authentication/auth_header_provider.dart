part of 'autenticacao_controller.dart';

class _FolhioCabecalhosAutenticacaoProvider {
  const _FolhioCabecalhosAutenticacaoProvider(this._repository);

  static final RegExp _safeClientId = RegExp(r'^[A-Za-z0-9._:-]{12,120}$');

  final PersistenciaLocalRepository _repository;

  Future<Map<String, String>> cabecalhos({
    required bool includeAuth,
    String? accessToken,
  }) async {
    if (AutenticacaoController._apiKey.isEmpty) {
      throw const FolhioAutenticacaoException(
        'Este app foi gerado sem a configuração de acesso. Gere uma nova versão e tente novamente.',
      );
    }
    return {
      AutenticacaoController._apiKeyHeader: AutenticacaoController._apiKey,
      AutenticacaoController._clientIdHeader: await identificadorCliente(),
      AutenticacaoController._appVersionHeader: AutenticacaoController._appVersion,
      AutenticacaoController._deviceHeader: nomeDispositivo(),
      HttpHeaders.userAgentHeader:
          'Folhio/${AutenticacaoController._appVersion} (${nomeDispositivo()})',
      if (AmbienteFolhioConfig.apiProxyBypassHeader.isNotEmpty)
        AmbienteFolhioConfig.apiProxyBypassHeader:
            AmbienteFolhioConfig.apiProxyBypassValue,
      if (includeAuth && accessToken != null)
        AutenticacaoController._authHeader: 'Bearer $accessToken',
    };
  }

  Future<String> identificadorCliente() async {
    final existing = await _repository.configuracao(
      AutenticacaoController._clientIdSettingKey,
    );
    if (existing != null && _safeClientId.hasMatch(existing)) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    final clientId = 'client-${base64UrlEncode(bytes).replaceAll('=', '')}';
    await _repository.definirConfiguracao(
      AutenticacaoController._clientIdSettingKey,
      clientId,
    );
    return clientId;
  }

  String identificadorRequisicao(String path) {
    final action = path
        .split('/')
        .where((part) => part.isNotEmpty && part != 'api' && part != 'folhio')
        .join('-');
    return 'auth-${action.isEmpty ? 'request' : action}-'
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  }

  String nomeDispositivo() {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
