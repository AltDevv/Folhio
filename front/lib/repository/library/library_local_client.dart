part of '../../service/api/folhio_api_gateway.dart';

class _FolhioBibliotecaLocalClient {
  _FolhioBibliotecaLocalClient(this._owner);
  final FolhioApiGateway _owner;
  // ignore: unused_element
  Future<List<FolhioArquivoBiblioteca>> listarArquivosBiblioteca({
    String search = '',
    String folder = '',
    String? folderId,
    int limit = 20,
  }) async {
    return _arquivosLocaisBiblioteca(
      search: search,
      folderId: folderId,
      folder: folder,
      limit: limit,
    );
  }

  Future<List<FolhioPastaBiblioteca>> listarPastasBiblioteca({
    String? parentId,
    int limit = 80,
  }) async {
    final rows = await PersistenciaLocalRepository.instance.listarPastas(
      parentId: parentId,
      limit: limit,
    );
    return rows.map(_pastaLocalParaBiblioteca).toList();
  }

  Future<FolhioPastaBiblioteca> criarPastaBiblioteca({
    required String name,
    String? parentId,
    String tags = '',
    String notes = '',
    String links = '',
  }) {
    return _enviarPastaBiblioteca(
      method: 'POST',
      name: name,
      parentId: parentId,
      tags: tags,
      notes: notes,
      links: links,
    );
  }

  Future<FolhioPastaBiblioteca> atualizarPastaBiblioteca(
    String folderId, {
    required String name,
    String tags = '',
    String notes = '',
    String links = '',
  }) {
    return _enviarPastaBiblioteca(
      method: 'PUT',
      folderId: folderId,
      name: name,
      tags: tags,
      notes: notes,
      links: links,
    );
  }

  Future<FolhioPastaBiblioteca> _enviarPastaBiblioteca({
    required String method,
    String? folderId,
    required String name,
    String? parentId,
    String tags = '',
    String notes = '',
    String links = '',
  }) async {
    final local = PersistenciaLocalRepository.instance;
    final existing = method == 'PUT' && folderId != null
        ? await local.pastaPorId(folderId)
        : null;
    final folder = await local.salvarPasta(
      id: method == 'PUT' ? folderId : null,
      parentId: parentId ?? existing?.parentId,
      name: name,
      tags: tags,
      notes: notes,
      links: links,
    );
    return _pastaLocalParaBiblioteca(folder);
  }

  Future<void> excluirPastaBiblioteca(String folderId) async {
    await PersistenciaLocalRepository.instance.excluirPasta(folderId);
  }

  Future<FolhioArquivoBiblioteca> moverArquivoBiblioteca(
    String fileId, {
    String? folderId,
    String folder = 'Arquivos',
  }) async {
    final local = PersistenciaLocalRepository.instance;
    final cached = await local.arquivoPorId(fileId);
    if (cached != null) {
      await local.moverArquivoLocal(
        id: fileId,
        folderId: folderId == 'root' ? null : folderId,
        folderName: folder,
      );
      final updated = await local.arquivoPorId(fileId);
      if (updated != null) {
        return _arquivoLocalParaBiblioteca(updated);
      }
    }
    throw const FolhioExibicaoUsuarioException('Arquivo local não encontrado.');
  }

  Future<FolhioArquivoBiblioteca> renomearArquivoBiblioteca(
    String fileId, {
    required String fileName,
  }) async {
    final name = _nomeSeguroArquivoBiblioteca(fileName);
    if (name.isEmpty) {
      throw const FolhioExibicaoUsuarioException('Informe um nome para o arquivo.');
    }
    final local = PersistenciaLocalRepository.instance;
    final cached = await local.arquivoPorId(fileId);
    if (cached != null) {
      await local.renomearArquivoLocal(id: fileId, fileName: name);
      final updated = await local.arquivoPorId(fileId);
      if (updated != null) {
        return _arquivoLocalParaBiblioteca(updated);
      }
    }
    throw const FolhioExibicaoUsuarioException('Arquivo local não encontrado.');
  }

  Future<void> excluirArquivoBiblioteca(String fileId) async {
    final local = PersistenciaLocalRepository.instance;
    final cached = await local.arquivoPorId(fileId);
    if (cached == null) return;
    await local.excluirArquivoLocal(fileId);
    await definirFavoritoArquivoBiblioteca(fileId, false);
  }

  Future<Set<String>> identificadoresFavoritosBiblioteca() async {
    final raw = await PersistenciaLocalRepository.instance.configuracao(
      FolhioApiGateway.favoriteFileIdsSettingKey,
    );
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString())
            .where((id) => id.isNotEmpty)
            .toSet();
      }
    } catch (_) {
      // Ignore invalid local settings and start with an empty favorite list.
    }
    return <String>{};
  }

  Future<bool> definirFavoritoArquivoBiblioteca(String fileId, bool favorite) async {
    final ids = await identificadoresFavoritosBiblioteca();
    if (favorite) {
      ids.add(fileId);
    } else {
      ids.remove(fileId);
    }
    await PersistenciaLocalRepository.instance.definirConfiguracao(
      FolhioApiGateway.favoriteFileIdsSettingKey,
      jsonEncode(ids.toList()..sort()),
    );
    return favorite;
  }

  Future<bool> alternarFavoritoArquivoBiblioteca(String fileId) async {
    final ids = await identificadoresFavoritosBiblioteca();
    final favorite = !ids.contains(fileId);
    return definirFavoritoArquivoBiblioteca(fileId, favorite);
  }

  Future<FolhioArquivoBiblioteca> salvarArquivoGeradoNaBiblioteca(
    FolhioArquivoGerado generatedFile, {
    String folder = 'Conversões',
    String? folderId,
    String conflictStrategy = 'reject',
  }) async {
    final local = PersistenciaLocalRepository.instance;
    final now = DateTime.now();
    final id = 'file-${now.microsecondsSinceEpoch}';
    _garantirPermitidoEnvioTamanho(generatedFile.bytes.length);
    final fileName = _nomeArquivoComExtensaoDetectada(
      generatedFile.fileName.trim().isEmpty
          ? 'folhio-resultado'
          : generatedFile.fileName.trim(),
      generatedFile.bytes,
    );
    final detectedMimeType = _tipoConteudoPorNomeArquivo(fileName);
    final mimeType =
        detectedMimeType == 'application/octet-stream' &&
            generatedFile.mimeType.trim().isNotEmpty
        ? generatedFile.mimeType
        : detectedMimeType;
    final documents = await getApplicationDocumentsDirectory();
    final libraryDir = Directory('${documents.path}/folhio-library');
    await libraryDir.create(recursive: true);

    final localFile = File(
      '${libraryDir.path}/$id${_extensaoArquivoLocal(fileName)}',
    );
    await local.escreverArquivoLocalCriptografado(localFile, generatedFile.bytes);

    await local.salvarOuAtualizarMetadadosArquivo(
      id: id,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: generatedFile.bytes.length,
      localPath: localFile.path,
      remoteStorageKey: null,
      folderId: folderId,
      folderName: folder,
      origin: 'local_device',
      updatedAt: now,
    );

    return FolhioArquivoBiblioteca(
      id: id,
      folderId: folderId,
      folder: folder,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: generatedFile.bytes.length,
      storageKey: '',
      downloadUrl: '',
      origin: 'local_device',
      updatedAt: now,
    );
  }

  Future<FolhioArquivoBiblioteca> salvarArquivoLocalNaBiblioteca(
    File sourceFile, {
    String? fileName,
    String folder = 'Importados',
    String? folderId,
  }) async {
    _garantirPermitidoEnvioTamanho(await sourceFile.length());
    final bytes = await sourceFile.readAsBytes();
    final resolvedName = (fileName == null || fileName.trim().isEmpty)
        ? (sourceFile.uri.pathSegments.isEmpty
              ? 'arquivo'
              : sourceFile.uri.pathSegments.last)
        : fileName.trim();
    final detectedName = _nomeArquivoComExtensaoDetectada(resolvedName, bytes);
    final generated = FolhioArquivoGerado(
      fileName: detectedName,
      mimeType: _tipoConteudoPorNomeArquivo(detectedName),
      bytes: bytes,
    );
    return salvarArquivoGeradoNaBiblioteca(
      generated,
      folder: folder,
      folderId: folderId,
    );
  }

  Future<FolhioArquivoGerado> baixarArquivoBiblioteca(
    FolhioArquivoBiblioteca file, {
    bool showReadyOverlay = true,
  }) async {
    if (showReadyOverlay) {
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 0.50,
        message: 'Baixando arquivo',
      );
    }
    if (file.storageKey.isEmpty && file.downloadUrl.isNotEmpty) {
      final localFile = File(file.downloadUrl);
      if (await localFile.exists()) {
        final bytes = await PersistenciaLocalRepository.instance
            .lerArquivoLocalCriptografado(localFile);
        final localPath = await _FolhioArquivoGeradoIo.armazenarArquivoGerado(
          fileName: file.fileName,
          bytes: bytes,
        );
        final readyFile = FolhioArquivoGerado(
          fileName: file.fileName,
          mimeType: file.mimeType,
          bytes: bytes,
          localPath: localPath,
        );
        _concluirPreparacaoArquivoBiblioteca(readyFile, showReadyOverlay);
        return readyFile;
      }
      throw const FolhioExibicaoUsuarioException(
        'Esse arquivo não está mais disponível neste aparelho.',
      );
    }

    final uri = _owner._uriDownloadBiblioteca(file);
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

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final localPath = await _FolhioArquivoGeradoIo.armazenarArquivoGerado(
      fileName: file.fileName,
      bytes: bytes,
    );
    final readyFile = FolhioArquivoGerado(
      fileName: file.fileName,
      mimeType: file.mimeType,
      bytes: bytes,
      storageKey: file.storageKey,
      downloadUrl: file.downloadUrl,
      localPath: localPath,
    );
    _concluirPreparacaoArquivoBiblioteca(readyFile, showReadyOverlay);
    return readyFile;
  }

  void _concluirPreparacaoArquivoBiblioteca(
    FolhioArquivoGerado readyFile,
    bool showReadyOverlay,
  ) {
    if (showReadyOverlay) {
      FolhioApiGateway.generatedFile.value = readyFile;
      FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
        progress: 1,
        message: 'Arquivo pronto',
      );
    } else {
      FolhioApiGateway.progress.value = null;
    }
  }

  Future<List<FolhioArquivoBiblioteca>> listarArquivosLocaisRecentes({int limit = 4}) {
    return _arquivosLocaisBiblioteca(
      search: '',
      folder: '',
      folderId: null,
      limit: limit,
    );
  }
}
