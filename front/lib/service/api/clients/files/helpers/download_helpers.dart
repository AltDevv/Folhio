part of '../../../folhio_api_gateway.dart';

extension _FolhioAuxiliaresDownload on FolhioApiGateway {
  Future<Uint8List> _baixarBytesSaida(FolhioArquivoSaida outputFile) async {
    final localPath = await _baixarArquivoSaida(
      outputFile,
      fileName: outputFile.fileName.trim().isEmpty
          ? 'folhio-resultado'
          : outputFile.fileName,
    );
    return File(localPath).readAsBytes();
  }

  Future<String> _baixarArquivoSaida(
    FolhioArquivoSaida outputFile, {
    required String fileName,
  }) async {
    await _garantirConexaoInternet();
    final uri = _uriDownloadSaida(outputFile);
    final request = await _httpClient
        .getUrl(uri)
        .timeout(const Duration(seconds: 12));
    await _adicionarCabecalhosAutenticacao(request);
    final response = await request.close().timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.transform(utf8.decoder).join();
      throw FolhioApiException(
        statusCode: response.statusCode,
        message: body.isEmpty ? 'Erro HTTP ${response.statusCode}' : body,
      );
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = _FolhioArquivoGeradoIo.nomeTemporarioSeguro(fileName);
    final target = File('${tempDir.path}/$safeName');
    final partial = File('${target.path}.part');
    await partial.parent.create(recursive: true);
    if (await partial.exists()) {
      await partial.delete();
    }

    final total = response.contentLength;
    var received = 0;
    final sink = partial.openWrite();
    try {
      final stream = response.timeout(
        const Duration(minutes: 2),
        onTimeout: (sink) {
          sink.addError(
            TimeoutException(
              'O download demorou demais. Tente novamente em instantes.',
            ),
          );
        },
      );
      await for (final chunk in stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final fraction = (received / total).clamp(0, 1).toDouble();
          FolhioApiGateway.progress.value = FolhioProgressoOperacao(
            progress: 0.88 + (fraction * 0.1),
            message: 'Baixando arquivo ${(fraction * 100).round()}%',
          );
        } else {
          FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
            progress: 0.92,
            message: 'Baixando arquivo',
          );
        }
      }
      await sink.flush();
      await sink.close();

      if (await target.exists()) {
        await target.delete();
      }
      final ready = await partial.rename(target.path);
      return ready.path;
    } catch (_) {
      try {
        await sink.close();
      } catch (_) {
        // Ignore close errors after a failed download.
      }
      try {
        if (await partial.exists()) {
          await partial.delete();
        }
      } catch (_) {
        // Ignore cleanup errors; the original failure is more useful.
      }
      rethrow;
    }
  }

  Uri _uriDownloadSaida(FolhioArquivoSaida outputFile) {
    final downloadUrl = outputFile.downloadUrl;
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      final parsed = Uri.parse(downloadUrl);
      if (parsed.hasScheme) {
        return parsed;
      }
      return Uri.parse('$baseUrl$downloadUrl');
    }

    final storageKey = outputFile.storageKey;
    if (storageKey == null || storageKey.isEmpty) {
      throw const FormatException(
        'Resposta do backend não trouxe link para download.',
      );
    }
    return Uri.parse('$baseUrl${RotasApiFolhio.baixar(storageKey)}');
  }

  Uri _uriDownloadBiblioteca(FolhioArquivoBiblioteca file) {
    final downloadUrl = file.downloadUrl.trim();
    if (downloadUrl.isNotEmpty) {
      final parsed = Uri.parse(downloadUrl);
      if (parsed.hasScheme) return parsed;
      return Uri.parse('$baseUrl$downloadUrl');
    }

    if (file.storageKey.isEmpty) {
      throw const FormatException(
        'Esse material não tem arquivo local nem link de download.',
      );
    }
    return Uri.parse('$baseUrl${RotasApiFolhio.baixar(file.storageKey)}');
  }
}
