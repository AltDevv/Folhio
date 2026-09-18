part of '../../folhio_api_gateway.dart';

class _FolhioHttpApiClient {
  const _FolhioHttpApiClient(this._owner);

  final FolhioApiGateway _owner;

  Future<void> garantirConexaoInternet() async {
    // A propria requisicao para a API valida a conexao real usada pelo app.
    // Checar um dominio externo aqui gerava falso erro com ngrok/rede movel.
  }

  Future<void> adicionarCabecalhosPadrao(HttpClientRequest request) async {
    final headers = await _owner._resolveHeaders();
    for (final header in headers.entries) {
      request.headers.set(header.key, header.value);
    }
    if (FolhioApiGateway.proxyBypassHeaderName.isNotEmpty) {
      request.headers.set(
        FolhioApiGateway.proxyBypassHeaderName,
        FolhioApiGateway.proxyBypassHeaderValue,
      );
    }
  }

  void fechar() {
    _owner._httpClient.close(force: true);
  }
}
