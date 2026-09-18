part of '../service/api/folhio_api_gateway.dart';

Future<List<FolhioArquivoBiblioteca>> _arquivosLocaisBiblioteca({
  required String search,
  required String folder,
  required String? folderId,
  required int limit,
}) async {
  final local = PersistenciaLocalRepository.instance;
  final rows = await local.arquivosRecentes(limit: limit * 4);
  final normalizedSearch = search.trim().toLowerCase();
  final result = <FolhioArquivoBiblioteca>[];

  for (final row in rows) {
    if (row.origin != 'local_device' && row.origin != 'cloud') {
      continue;
    }
    if (normalizedSearch.isNotEmpty &&
        !row.fileName.toLowerCase().contains(normalizedSearch)) {
      continue;
    }
    if (folderId != null &&
        folderId.isNotEmpty &&
        folderId != 'root' &&
        row.folderId != folderId) {
      continue;
    }
    if (folderId == 'root' && row.folderId != null) {
      continue;
    }
    if (folder.trim().isNotEmpty && row.folderName != folder) {
      continue;
    }

    final localPath = row.localPath;
    final remoteStorageKey = row.remoteStorageKey?.trim() ?? '';
    if ((localPath == null ||
            localPath.isEmpty ||
            !await File(localPath).exists()) &&
        remoteStorageKey.isEmpty) {
      result.add(_arquivoLocalParaBiblioteca(row));
      if (result.length >= limit) break;
      continue;
    }

    result.add(_arquivoLocalParaBiblioteca(row));
    if (result.length >= limit) break;
  }

  return result;
}

FolhioArquivoBiblioteca _arquivoLocalParaBiblioteca(LocalFile row) {
  return FolhioArquivoBiblioteca(
    id: row.id,
    folderId: row.folderId,
    folder: row.folderName,
    fileName: row.fileName,
    mimeType: row.mimeType,
    sizeBytes: row.sizeBytes,
    storageKey: row.remoteStorageKey ?? '',
    downloadUrl: row.localPath ?? '',
    origin: row.origin,
    updatedAt: row.updatedAt,
  );
}

FolhioPastaBiblioteca _pastaLocalParaBiblioteca(LocalFolder row) {
  return FolhioPastaBiblioteca(
    id: row.id,
    parentId: row.parentId,
    name: row.name,
    tags: row.tags,
    notes: row.notes,
    links: row.links,
    updatedAt: row.updatedAt,
  );
}
