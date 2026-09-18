part of '../persistencia_local_repository.dart';

class _BibliotecaLocalStore {
  _BibliotecaLocalStore(this._owner);

  final PersistenciaLocalRepository _owner;

  Future<void> escreverArquivoLocalCriptografado(File file, List<int> bytes) async {
    await file.writeAsBytes(
      await _owner._encryption.criptografarBytes(bytes),
      flush: true,
    );
  }

  Future<Uint8List> lerArquivoLocalCriptografado(File file) async {
    return _owner._encryption.descriptografarBytesSeNecessario(await file.readAsBytes());
  }

  Future<void> salvarOuAtualizarMetadadosArquivo({
    required String id,
    required String fileName,
    required String mimeType,
    int? sizeBytes,
    String? localPath,
    String? remoteStorageKey,
    String? folderId,
    required String folderName,
    required String origin,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now();
    await _owner.db
        .into(_owner.db.localFiles)
        .insertOnConflictUpdate(
          LocalFilesCompanion.insert(
            id: id,
            fileName: await _owner._encryption.criptografarTexto(fileName),
            mimeType: Value(mimeType),
            sizeBytes: Value(sizeBytes),
            localPath: Value(
              await _owner._encryption.criptografarTextoOpcional(localPath),
            ),
            remoteStorageKey: Value(
              await _owner._encryption.criptografarTextoOpcional(remoteStorageKey),
            ),
            folderId: Value(folderId),
            folderName: Value(await _owner._encryption.criptografarTexto(folderName)),
            origin: Value(origin),
            pendingBackup: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(updatedAt ?? now),
          ),
        );
  }

  Future<LocalFile?> arquivoPorId(String id) async {
    final row = await (_owner.db.select(
      _owner.db.localFiles,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final file = await _owner._descriptografarArquivo(row);
    if (_owner._temTextoArquivoIlegivel(file)) {
      await (_owner.db.delete(
        _owner.db.localFiles,
      )..where((table) => table.id.equals(id))).go();
      return null;
    }
    return file;
  }

  Future<List<LocalFile>> arquivosRecentes({int limit = 20}) async {
    final rows = await _owner.db.arquivosRecentes(limit: limit);
    final files = await Future.wait(rows.map(_owner._descriptografarArquivo));
    final readable = <LocalFile>[];
    for (final file in files) {
      if (_owner._temTextoArquivoIlegivel(file)) {
        await (_owner.db.delete(
          _owner.db.localFiles,
        )..where((table) => table.id.equals(file.id))).go();
        continue;
      }
      readable.add(file);
    }
    return readable;
  }

  Future<void> excluirArquivoLocal(String id) async {
    final row = await arquivoPorId(id);
    final localPath = row?.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await (_owner.db.delete(
      _owner.db.localFiles,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> moverArquivoLocal({
    required String id,
    String? folderId,
    required String folderName,
  }) async {
    await (_owner.db.update(
      _owner.db.localFiles,
    )..where((table) => table.id.equals(id))).write(
      LocalFilesCompanion(
        folderId: Value(folderId),
        folderName: Value(await _owner._encryption.criptografarTexto(folderName)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> renomearArquivoLocal({
    required String id,
    required String fileName,
  }) async {
    await (_owner.db.update(
      _owner.db.localFiles,
    )..where((table) => table.id.equals(id))).write(
      LocalFilesCompanion(
        fileName: Value(await _owner._encryption.criptografarTexto(fileName)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LocalFolder>> listarPastas({
    String? parentId,
    int limit = 80,
  }) async {
    final normalizedParentId = parentId == 'root' ? null : parentId;
    final query = _owner.db.select(_owner.db.localFolders)
      ..where(
        (table) => normalizedParentId == null
            ? table.parentId.isNull()
            : table.parentId.equals(normalizedParentId),
      );
    final rows = await Future.wait(
      (await query.get()).map(_owner._descriptografarPasta),
    );
    final readable = <LocalFolder>[];
    for (final folder in rows) {
      if (_owner._temTextoPastaIlegivel(folder)) {
        await (_owner.db.delete(
          _owner.db.localFolders,
        )..where((table) => table.id.equals(folder.id))).go();
        continue;
      }
      readable.add(folder);
    }
    readable.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return readable.take(limit).toList();
  }

  Future<LocalFolder?> pastaPorId(String id) async {
    final row = await (_owner.db.select(
      _owner.db.localFolders,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final folder = await _owner._descriptografarPasta(row);
    if (_owner._temTextoPastaIlegivel(folder)) {
      await (_owner.db.delete(
        _owner.db.localFolders,
      )..where((table) => table.id.equals(id))).go();
      return null;
    }
    return folder;
  }

  Future<LocalFolder> salvarPasta({
    String? id,
    String? parentId,
    required String name,
    String tags = '',
    String notes = '',
    String links = '',
  }) async {
    final now = DateTime.now();
    final folderId = id ?? _owner._id('folder');
    final encryptedName = await _owner._encryption.criptografarTexto(name);
    await _owner.db
        .into(_owner.db.localFolders)
        .insertOnConflictUpdate(
          LocalFoldersCompanion.insert(
            id: folderId,
            parentId: Value(parentId == 'root' ? null : parentId),
            name: encryptedName,
            tags: Value(await _owner._encryption.criptografarTexto(tags)),
            notes: Value(await _owner._encryption.criptografarTexto(notes)),
            links: Value(await _owner._encryption.criptografarTexto(links)),
            updatedAt: Value(now),
          ),
        );
    await (_owner.db.update(
      _owner.db.localFiles,
    )..where((table) => table.folderId.equals(folderId))).write(
      LocalFilesCompanion(
        folderName: Value(encryptedName),
        updatedAt: Value(now),
      ),
    );
    final saved = (await pastaPorId(folderId))!;
    return saved;
  }

  Future<void> excluirPasta(String id) async {
    final folder = await pastaPorId(id);
    final parentId = folder?.parentId;
    final defaultFolderName = await _owner._encryption.criptografarTexto('Arquivos');
    await (_owner.db.update(
      _owner.db.localFiles,
    )..where((table) => table.folderId.equals(id))).write(
      LocalFilesCompanion(
        folderId: const Value(null),
        folderName: Value(defaultFolderName),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (_owner.db.update(
      _owner.db.localFolders,
    )..where((table) => table.parentId.equals(id))).write(
      LocalFoldersCompanion(
        parentId: Value(parentId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (_owner.db.delete(
      _owner.db.localFolders,
    )..where((table) => table.id.equals(id))).go();
  }
}
