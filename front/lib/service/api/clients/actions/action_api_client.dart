part of '../../folhio_api_gateway.dart';

class _FolhioAcaoApiClient {
  final FolhioApiGateway _owner;

  const _FolhioAcaoApiClient(this._owner);

  Future<FolhioAcaoResponse> enviar(FolhioAcaoRequest action) async {
    final tempo = Stopwatch()..start();
    FolhioApiGateway.generatedFile.value = null;
    FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
      progress: 0.30,
      message: 'Enviando pedido',
    );
    final realtime = _owner._iniciarProgressoTempoReal(action.requestId);

    try {
      await _owner._garantirConexaoInternet();
      final request = await _owner._httpClient
          .postUrl(_owner.endpoint)
          .timeout(const Duration(seconds: 12));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      await _owner._adicionarCabecalhosAutenticacao(request);
      request.headers.set(FolhioApiGateway.requestIdHeader, action.requestId);
      request.write(action.codificar());

      final response = await request.close().timeout(_owner.timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FolhioApiException(
          statusCode: response.statusCode,
          message: responseBody.isEmpty
              ? 'Erro HTTP ${response.statusCode}'
              : responseBody,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Resposta do backend não é um objeto JSON.',
        );
      }

      final actionResponse = FolhioAcaoResponse.deJson(decoded);
      if (!actionResponse.success) {
        throw FolhioApiException(
          statusCode: response.statusCode,
          message: responseBody,
        );
      }
      await realtime.cancelar();
      await _owner.prepararArquivoSaida(actionResponse.outputFile);

      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 1,
        message: 'Arquivo pronto',
      );
      unawaited(
        _owner.registrarEventoCliente(
          FolhioEventoRegistroClienteRequest(
            level: 'INFO',
            category: 'CLIENTE',
            event: 'acao.pronta_no_app',
            message:
                'O aplicativo preparou o resultado para salvar ou compartilhar.',
            requestId: action.requestId,
            details: {
              'title': action.title,
              'duracaoMs': tempo.elapsedMilliseconds,
            },
          ),
        ),
      );
      return actionResponse;
    } catch (error) {
      final message = FolhioApiGateway.humanizarErro(error);
      unawaited(
        _owner.registrarEventoCliente(
          FolhioEventoRegistroClienteRequest(
            level: 'ERRO',
            category: 'CLIENTE',
            event: 'acao.erro',
            message: message,
            requestId: action.requestId,
            details: {
              'duracaoMs': tempo.elapsedMilliseconds,
              'title': action.title,
              'category': action.category,
              'type': action.type,
            },
          ),
        ),
      );
      _owner._mostrarErroProgresso(message);
      throw FolhioExibicaoUsuarioException(message);
    } finally {
      unawaited(realtime.cancelar());
    }
  }
}
