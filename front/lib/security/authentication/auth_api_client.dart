part of 'autenticacao_controller.dart';

typedef _AuthHeaderResolver = Future<Map<String, String>> Function(String path);

class _FolhioAutenticacaoApiClient {
  const _FolhioAutenticacaoApiClient(
    this._baseUrl,
    this._headerProvider,
    this._headerResolver,
  );

  final String _baseUrl;
  final _FolhioCabecalhosAutenticacaoProvider _headerProvider;
  final _AuthHeaderResolver _headerResolver;

  Future<Map<String, dynamic>> cadastrar({
    required String name,
    required String email,
    required String password,
  }) {
    return _enviarPost(RotasApiFolhio.register, {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> entrar({
    required String email,
    required String password,
  }) {
    return _enviarPost(RotasApiFolhio.login, {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> entrarComTokenGoogle(String idToken) {
    return _enviarPost(RotasApiFolhio.google, {'idToken': idToken});
  }

  Future<Map<String, dynamic>> renovar(String refreshToken) {
    return _enviarPost(RotasApiFolhio.refresh, {'refreshToken': refreshToken});
  }

  Future<void> sair(String refreshToken) async {
    await _enviarPost(RotasApiFolhio.logout, {'refreshToken': refreshToken});
  }

  Future<Map<String, dynamic>> obter(String path) {
    return _enviar('GET', path, null);
  }

  Future<Map<String, dynamic>> atualizarParcialmente(
    String path,
    Map<String, Object?> body,
  ) {
    return _enviar('PATCH', path, body);
  }

  Future<Map<String, dynamic>> excluir(String path, Map<String, Object?> body) {
    return _enviar('DELETE', path, body);
  }

  Future<Map<String, dynamic>> _enviarPost(
    String path,
    Map<String, Object?> body,
  ) {
    return _enviar('POST', path, body);
  }

  Future<Map<String, dynamic>> _enviar(
    String method,
    String path,
    Map<String, Object?>? body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final tempo = Stopwatch()..start();
    final requestId = _headerProvider.identificadorRequisicao(path);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 5));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(AutenticacaoController._requestIdHeader, requestId);
      final headers = await _headerResolver(path);
      for (final header in headers.entries) {
        request.headers.set(header.key, header.value);
      }
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        ObservabilidadeService.registrar(
          'app.autenticacao.recusada',
          'O servidor recusou a operacao de autenticacao.',
          nivel: 'AVISO',
          requestId: requestId,
          detalhes: {
            'operacao': path,
            'statusHttp': response.statusCode,
            'duracaoMs': tempo.elapsedMilliseconds,
          },
        );
        throw FolhioAutenticacaoException(
          ErroHttpHandler.mensagem(response.statusCode, text),
        );
      }
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      ObservabilidadeService.registrar(
        'app.autenticacao.concluida',
        'O aplicativo recebeu a resposta da autenticacao.',
        requestId: requestId,
        detalhes: {'operacao': path, 'duracaoMs': tempo.elapsedMilliseconds},
      );
      return decoded;
    } on FolhioAutenticacaoException {
      rethrow;
    } on TimeoutException {
      throw const FolhioAutenticacaoException(
        'O servidor demorou demais para responder. Tente novamente.',
      );
    } on FormatException {
      throw const FolhioAutenticacaoException(
        'O servidor enviou uma resposta inválida. Tente novamente.',
      );
    } on HandshakeException {
      throw const FolhioAutenticacaoException(
        'Não foi possível estabelecer uma conexão segura.',
      );
    } catch (_) {
      throw const FolhioAutenticacaoException(
        'Não foi possível conectar. Verifique sua internet.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
