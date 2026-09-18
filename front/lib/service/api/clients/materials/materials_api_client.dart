part of '../../folhio_api_gateway.dart';

class _FolhioMateriaisApiClient {
  final FolhioApiGateway _owner;

  const _FolhioMateriaisApiClient(this._owner);

  Future<FolhioCatalogoMateriais> catalogo({String discipline = ''}) async {
    await _owner._garantirConexaoInternet();
    final query = <String, String>{
      if (discipline.trim().isNotEmpty) 'discipline': discipline.trim(),
    };
    final uri = Uri.parse(
      '${_owner.baseUrl}${RotasApiFolhio.catalog}',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final decoded = await _obterJson(uri);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catálogo de materiais inválido.');
    }
    return FolhioCatalogoMateriais.deJson(decoded);
  }

  Future<List<FolhioModeloMaterial>> modelos({
    String materialType = '',
  }) async {
    await _owner._garantirConexaoInternet();
    final query = <String, String>{
      if (materialType.trim().isNotEmpty) 'materialType': materialType.trim(),
    };
    final uri = Uri.parse(
      '${_owner.baseUrl}${RotasApiFolhio.templates}',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final decoded = await _obterJson(uri);
    if (decoded is! List) {
      throw const FormatException('Lista de templates DOCX inválida.');
    }
    return decoded
        .whereType<Map>()
        .map((item) {
          return FolhioModeloMaterial.deJson(
            Map<String, dynamic>.from(item),
          );
        })
        .toList(growable: false);
  }

  Future<List<FolhioResumoMaterialGerado>> gerados({
    int limit = 50,
  }) async {
    await _owner._garantirConexaoInternet();
    final uri = Uri.parse(
      '${_owner.baseUrl}${RotasApiFolhio.generated}',
    ).replace(queryParameters: {'limit': limit.clamp(1, 100).toString()});
    final decoded = await _obterJson(uri);
    if (decoded is! List) {
      throw const FormatException('Histórico de materiais inválido.');
    }
    return decoded
        .whereType<Map>()
        .map((item) {
          return FolhioResumoMaterialGerado.deJson(
            Map<String, dynamic>.from(item),
          );
        })
        .toList(growable: false);
  }

  Future<FolhioMaterialGerado> montar(FolhioGeracaoMaterialRequest input) async {
    FolhioApiGateway.generatedFile.value = null;
    FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
      progress: 0.18,
      message: 'Montando material',
    );

    try {
      await _owner._garantirConexaoInternet();
      final uri = Uri.parse(
        '${_owner.baseUrl}${RotasApiFolhio.buildMaterial}',
      );
      final request = await _owner._httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 4));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      await _owner._adicionarCabecalhosAutenticacao(request);
      request.write(jsonEncode(input.toJson()));

      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.42,
        message: 'Buscando questões',
      );

      final response = await request.close().timeout(_owner.timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FolhioApiException(
          statusCode: response.statusCode,
          message: body.isEmpty ? 'Erro HTTP ${response.statusCode}' : body,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Resposta de geração inválida.');
      }

      final built = FolhioMaterialGerado.deJson(decoded);
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.78,
        message: 'Preparando DOCX',
      );
      await _owner.prepararArquivoSaida(built.outputFile);
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 1,
        message: 'Material pronto',
      );
      return built;
    } catch (error) {
      final message = FolhioApiGateway.humanizarErro(error);
      unawaited(
        _owner.registrarEventoCliente(
          FolhioEventoRegistroClienteRequest(
            level: 'ERRO',
            category: 'CLIENTE',
            event: 'material.geracao.erro',
            message: message,
            details: input.toJson(),
          ),
        ),
      );
      _owner._mostrarErroProgresso(message);
      throw FolhioExibicaoUsuarioException(message);
    }
  }

  Future<Object?> _obterJson(Uri uri) async {
    final request = await _owner._httpClient
        .getUrl(uri)
        .timeout(const Duration(seconds: 4));
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    await _owner._adicionarCabecalhosAutenticacao(request);
    final response = await request.close().timeout(_owner.timeout);
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FolhioApiException(
        statusCode: response.statusCode,
        message: body.isEmpty ? 'Erro HTTP ${response.statusCode}' : body,
      );
    }
    return jsonDecode(body);
  }
}
