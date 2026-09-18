part of '../../folhio_api_gateway.dart';

extension _FolhioProgressoApiClient on FolhioApiGateway {
  _ConexaoProgressoTempoReal _iniciarProgressoTempoReal(String requestId) {
    return _ConexaoProgressoTempoReal(
      requestId: requestId,
      uri: _uriWebSocketProgresso(requestId),
      headers: FolhioApiGateway.apiHeaders,
    );
  }

  Uri _uriWebSocketProgresso(String requestId) {
    final base = Uri.parse(baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: scheme,
      pathSegments: [
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        'ws',
        'progress',
        requestId,
      ],
      queryParameters: const {},
    );
  }

  void _mostrarErroProgresso(String message) {
    FolhioApiGateway.generatedFile.value = null;
    FolhioApiGateway.progress.value = FolhioProgressoOperacao(
      progress: FolhioApiGateway.progress.value?.progress ?? 0,
      message: message,
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      FolhioApiGateway.progress.value = null;
    });
  }

  void _limparProgressoEnvioDepois() {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      final current = FolhioApiGateway.progress.value;
      if (current != null &&
          current.progress <= 0.30 &&
          current.message == 'Arquivo enviado' &&
          FolhioApiGateway.generatedFile.value == null) {
        FolhioApiGateway.progress.value = null;
      }
    });
  }
}
