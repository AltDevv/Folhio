part of '../../folhio_api_gateway.dart';

class _FolhioArquivoApiClient {
  final FolhioApiGateway _owner;

  const _FolhioArquivoApiClient(this._owner);

  Future<FolhioArquivoEnviado> enviarArquivo(
    File file, {
    String? fileName,
    bool keepProgress = false,
    bool persistent = false,
    bool showProgressError = true,
  }) async {
    final requestId = criarIdRequisicao('upload');
    _ConexaoProgressoTempoReal? realtime;
    try {
      await _owner._garantirConexaoInternet();
      FolhioApiGateway.generatedFile.value = null;
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.01,
        message: 'Preparando arquivo',
      );
      final fileSize = await file.length().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw const FolhioExibicaoUsuarioException(
          'Não foi possível acessar esse arquivo. Escolha outro arquivo ou outra pasta.',
        ),
      );
      _garantirPermitidoEnvioTamanho(fileSize);
      final uri = Uri.parse(
        '${_owner.baseUrl}${RotasApiFolhio.upload}${persistent ? '?persistent=true' : ''}',
      );
      final boundary =
          'folhio-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}';
      final rawUploadFileName = (fileName == null || fileName.trim().isEmpty)
          ? (file.uri.pathSegments.isEmpty
                ? 'arquivo'
                : file.uri.pathSegments.last)
          : fileName.trim();
      final uploadFileName =
          await _nomeArquivoComExtensaoDetectadaDoArquivo(
            rawUploadFileName,
            file,
          ).timeout(
            const Duration(seconds: 4),
            onTimeout: () => _nomeSeguroArquivoBiblioteca(rawUploadFileName).isEmpty
                ? 'arquivo'
                : _nomeSeguroArquivoBiblioteca(rawUploadFileName),
          );
      await _validarSegurancaArquivoEnvio(file, uploadFileName, fileSize);
      final contentType = _tipoConteudoPorNomeArquivo(uploadFileName);
      final request = await _owner._httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 12));

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(FolhioApiGateway.requestIdHeader, requestId);
      await _owner._adicionarCabecalhosAutenticacao(request);

      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="file"; filename="$uploadFileName"\r\n',
      );
      request.write('Content-Type: $contentType\r\n\r\n');

      var sentBytes = 0;
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.01,
        message: 'Enviando arquivo',
      );

      final uploadStream = file.openRead().timeout(
        const Duration(seconds: 20),
        onTimeout: (sink) {
          sink.addError(
            TimeoutException(
              'Não foi possível ler esse arquivo. Escolha outro arquivo ou tente novamente.',
            ),
          );
        },
      );
      await for (final chunk in uploadStream) {
        request.add(chunk);
        sentBytes += chunk.length;
        final percent = (sentBytes * 100 / max(fileSize, 1)).clamp(0, 100);
        final uploadProgress = fileSize == 0
            ? 0.25
            : (sentBytes / fileSize) * 0.25;
        FolhioApiGateway.progress.value = FolhioProgressoOperacao(
          progress: uploadProgress.clamp(0.01, 0.25).toDouble(),
          message: 'Enviando arquivo ${percent.toStringAsFixed(0)}%',
        );
      }

      request.write('\r\n--$boundary--\r\n');
      realtime = _owner._iniciarProgressoTempoReal(requestId);

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
        throw const FormatException('Resposta de upload não é um objeto JSON.');
      }

      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.28,
        message: 'Arquivo enviado',
      );
      if (!keepProgress) {
        _owner._limparProgressoEnvioDepois();
      }
      return FolhioArquivoEnviado.deJson(decoded);
    } catch (error) {
      final message = FolhioApiGateway.humanizarErro(error);
      unawaited(
        _owner.registrarEventoCliente(
          FolhioEventoRegistroClienteRequest(
            level: 'ERRO',
            category: 'CLIENTE',
            event: 'arquivo.upload.erro',
            message: message,
            details: {
              'fileName': file.uri.pathSegments.isEmpty
                  ? file.path
                  : file.uri.pathSegments.last,
            },
          ),
        ),
      );
      if (showProgressError) {
        _owner._mostrarErroProgresso(message);
      } else {
        FolhioApiGateway.progress.value = null;
      }
      throw FolhioExibicaoUsuarioException(message);
    } finally {
      if (realtime != null) {
        unawaited(realtime.cancelar());
      }
    }
  }

  Future<FolhioArquivoEnviado> enviarBytes(
    List<int> bytes, {
    required String fileName,
    bool keepProgress = false,
    bool persistent = false,
    bool showProgressError = true,
  }) async {
    var resolvedFileName = fileName;
    final requestId = criarIdRequisicao('upload-bytes');
    _ConexaoProgressoTempoReal? realtime;
    try {
      _garantirPermitidoEnvioTamanho(bytes.length);
      resolvedFileName = _nomeArquivoComExtensaoDetectada(fileName, bytes);
      await _owner._garantirConexaoInternet();
      FolhioApiGateway.generatedFile.value = null;
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.01,
        message: 'Preparando arquivo',
      );
      final uri = Uri.parse(
        '${_owner.baseUrl}${RotasApiFolhio.upload}${persistent ? '?persistent=true' : ''}',
      );
      final boundary =
          'folhio-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}';
      final request = await _owner._httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 12));
      final contentType = _tipoConteudoPorNomeArquivo(resolvedFileName);

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(FolhioApiGateway.requestIdHeader, requestId);
      await _owner._adicionarCabecalhosAutenticacao(request);

      request.add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="$resolvedFileName"\r\n'
          'Content-Type: $contentType\r\n\r\n',
        ),
      );
      request.add(bytes);
      request.add(utf8.encode('\r\n--$boundary--\r\n'));

      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.25,
        message: 'Enviando arquivo',
      );
      realtime = _owner._iniciarProgressoTempoReal(requestId);

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
        throw const FormatException('Resposta de upload não é um objeto JSON.');
      }

      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.28,
        message: 'Arquivo enviado',
      );
      if (!keepProgress) {
        _owner._limparProgressoEnvioDepois();
      }
      return FolhioArquivoEnviado.deJson(decoded);
    } catch (error) {
      final message = FolhioApiGateway.humanizarErro(error);
      unawaited(
        _owner.registrarEventoCliente(
          FolhioEventoRegistroClienteRequest(
            level: 'ERRO',
            category: 'CLIENTE',
            event: 'arquivo.upload.erro',
            message: message,
            details: {'fileName': resolvedFileName},
          ),
        ),
      );
      if (showProgressError) {
        _owner._mostrarErroProgresso(message);
      } else {
        FolhioApiGateway.progress.value = null;
      }
      throw FolhioExibicaoUsuarioException(message);
    } finally {
      if (realtime != null) {
        unawaited(realtime.cancelar());
      }
    }
  }

  Future<File> baixarArquivo({
    required String fileId,
    required String savePath,
  }) async {
    await _owner._garantirConexaoInternet();
    final uri = Uri.parse(
      '${_owner.baseUrl}${RotasApiFolhio.baixar(fileId)}',
    );
    final request = await _owner._httpClient
        .getUrl(uri)
        .timeout(const Duration(seconds: 4));
    await _owner._adicionarCabecalhosAutenticacao(request);
    final response = await request.close().timeout(_owner.timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.transform(utf8.decoder).join();
      throw FolhioApiException(
        statusCode: response.statusCode,
        message: body.isEmpty ? 'Erro HTTP ${response.statusCode}' : body,
      );
    }

    final output = File(savePath);
    await output.parent.create(recursive: true);
    final sink = output.openWrite();
    await response.pipe(sink);
    return output;
  }

  String urlPreviaPdf(String fileId, {int page = 1}) {
    return '${_owner.baseUrl}${RotasApiFolhio.visualizar(fileId, page)}';
  }
}
