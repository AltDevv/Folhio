import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/service/api/folhio_api_gateway.dart';
import 'package:folhio/model/library/library_models.dart';
import 'package:folhio/repository/library/biblioteca_repository.dart';
import 'package:folhio/controller/library/biblioteca_view_model.dart';

void main() {
  test('LibraryViewModel carrega pastas, arquivos, tags e favoritos', () async {
    final repository = _SimuladoBibliotecaRepository(
      folders: [
        _pasta(id: 'folder-1', name: 'Provas', tags: 'matematica, provas'),
        _pasta(id: 'folder-2', name: 'Planos', tags: 'aulas'),
      ],
      files: [
        _arquivo(id: 'file-1', fileName: 'prova.pdf'),
        _arquivo(id: 'file-2', fileName: 'aula.png'),
      ],
      favoriteIds: {'file-2'},
    );
    final viewModel = BibliotecaViewModel(repository: repository);

    await viewModel.carregarConteudo(parentId: 'root', search: 'aula');

    expect(viewModel.loading, isFalse);
    expect(viewModel.message, isNull);
    expect(viewModel.folders.map((folder) => folder.id), [
      'folder-1',
      'folder-2',
    ]);
    expect(viewModel.files.map((file) => file.id), ['file-1', 'file-2']);
    expect(viewModel.favoriteFiles.map((file) => file.id), ['file-2']);
    expect(viewModel.favoriteFileIds, {'file-2'});
    expect(viewModel.availableFolderTags, ['aulas', 'matematica', 'provas']);
    expect(viewModel.folderTagsById['folder-1'], ['matematica', 'provas']);

    viewModel.dispose();
  });

  test(
    'LibraryViewModel atualiza favoritos sem recarregar toda a tela',
    () async {
      final repository = _SimuladoBibliotecaRepository();
      final viewModel = BibliotecaViewModel(repository: repository);
      final file = _arquivo(id: 'file-1', fileName: 'atividade.pdf');

      final favorite = await viewModel.alternarFavorito(file);

      expect(favorite, isTrue);
      expect(viewModel.favoriteFileIds, {'file-1'});
      expect(viewModel.favoriteFiles.map((item) => item.id), ['file-1']);

      final removed = await viewModel.alternarFavorito(file);

      expect(removed, isFalse);
      expect(viewModel.favoriteFileIds, isEmpty);
      expect(viewModel.favoriteFiles, isEmpty);

      viewModel.dispose();
    },
  );

  test('LibraryViewModel nao favorita item sem arquivo real', () async {
    final repository = _SimuladoBibliotecaRepository();
    final viewModel = BibliotecaViewModel(repository: repository);
    final example = _arquivo(
      id: 'example-1',
      fileName: 'modelo-exemplo.docx',
      storageKey: '',
      downloadUrl: '',
    );

    expect(viewModel.podeFavoritar(example), isFalse);
    expect(() => viewModel.alternarFavorito(example), throwsA(isA<Object>()));
    expect(repository.favoriteIds, isEmpty);

    viewModel.dispose();
  });

  test(
    'LibraryViewModel favorita premium mas bloqueia download sem plano',
    () async {
      final repository = _SimuladoBibliotecaRepository();
      final viewModel = BibliotecaViewModel(repository: repository);
      final premiumFile = _arquivo(
        id: 'premium-1',
        fileName: 'simulado-premium.pdf',
        requiresPaidPlan: true,
      );

      final favorite = await viewModel.alternarFavorito(premiumFile);

      expect(favorite, isTrue);
      expect(viewModel.favoriteFileIds, {'premium-1'});
      expect(viewModel.podeBaixar(premiumFile), isFalse);
      expect(() => viewModel.baixar(premiumFile), throwsA(isA<Object>()));
      expect(repository.downloaded, isEmpty);

      viewModel.dispose();
    },
  );

  test('LibraryViewModel cria pasta e recarrega conteudo', () async {
    final repository = _SimuladoBibliotecaRepository();
    final viewModel = BibliotecaViewModel(repository: repository);

    final folder = await viewModel.criarPasta(
      input: const EntradaPastaBiblioteca(name: 'Atividades', tags: 'aula'),
      parentId: null,
      search: '',
    );

    expect(folder.name, 'Atividades');
    expect(repository.createdFolderNames, ['Atividades']);
    expect(viewModel.folders.map((item) => item.name), ['Atividades']);

    viewModel.dispose();
  });

  test('LibraryViewModel renomeia e remove arquivo via repository', () async {
    final file = _arquivo(id: 'file-1', fileName: 'antigo.pdf');
    final repository = _SimuladoBibliotecaRepository(files: [file]);
    final viewModel = BibliotecaViewModel(repository: repository);

    await viewModel.renomearArquivo(
      file,
      fileName: 'novo.pdf',
      currentParentId: 'root',
      search: '',
    );

    expect(repository.files.single.fileName, 'novo.pdf');

    await viewModel.excluirArquivo(
      repository.files.single,
      currentParentId: 'root',
      search: '',
    );

    expect(repository.files, isEmpty);

    viewModel.dispose();
  });
}

FolhioPastaBiblioteca _pasta({
  required String id,
  required String name,
  String tags = '',
}) {
  return FolhioPastaBiblioteca(
    id: id,
    name: name,
    tags: tags,
    notes: '',
    links: '',
  );
}

FolhioArquivoBiblioteca _arquivo({
  required String id,
  required String fileName,
  String? storageKey,
  String? downloadUrl,
  bool requiresPaidPlan = false,
}) {
  return FolhioArquivoBiblioteca(
    id: id,
    folder: 'Meus materiais',
    fileName: fileName,
    mimeType: 'application/octet-stream',
    storageKey: storageKey ?? id,
    downloadUrl: downloadUrl ?? 'https://example.com/$id',
    origin: 'test',
    requiresPaidPlan: requiresPaidPlan,
  );
}

class _SimuladoBibliotecaRepository implements BibliotecaRepository {
  _SimuladoBibliotecaRepository({
    List<FolhioPastaBiblioteca>? folders,
    List<FolhioArquivoBiblioteca>? files,
    Set<String>? favoriteIds,
  }) : folders = [...?folders],
       files = [...?files],
       favoriteIds = {...?favoriteIds};

  final List<FolhioPastaBiblioteca> folders;
  final List<FolhioArquivoBiblioteca> files;
  final Set<String> favoriteIds;
  final downloaded = <String>[];
  final createdFolderNames = <String>[];

  @override
  Future<List<FolhioPastaBiblioteca>> listarPastas({
    required String parentId,
    int limit = 80,
  }) async {
    return folders.take(limit).toList();
  }

  @override
  Future<List<FolhioArquivoBiblioteca>> listarArquivos({
    String search = '',
    String? folderId,
    int limit = 100,
  }) async {
    return files.take(limit).toList();
  }

  @override
  Future<Set<String>> identificadoresArquivosFavoritos() async => favoriteIds;

  @override
  Future<bool> alternarFavorito(String fileId) async {
    if (favoriteIds.contains(fileId)) {
      favoriteIds.remove(fileId);
      return false;
    }
    favoriteIds.add(fileId);
    return true;
  }

  @override
  Future<void> baixarArquivo(FolhioArquivoBiblioteca file) async {
    downloaded.add(file.id);
  }

  @override
  Future<FolhioArquivoGerado> prepararArquivo(FolhioArquivoBiblioteca file) async {
    downloaded.add(file.id);
    return FolhioArquivoGerado(
      fileName: file.fileName,
      mimeType: file.mimeType,
      bytes: Uint8List(0),
      localPath: file.downloadUrl,
    );
  }

  @override
  Future<void> salvarArquivoLocalNaBiblioteca(
    File file, {
    String? fileName,
    String? folderId,
    required String folder,
  }) async {
    files.add(
      _arquivo(id: 'local-${files.length + 1}', fileName: fileName ?? file.path),
    );
  }

  @override
  Future<void> salvarArquivoGeradoNaBiblioteca(
    FolhioArquivoGerado file, {
    String? folderId,
    required String folder,
  }) async {
    files.add(
      _arquivo(id: 'generated-${files.length + 1}', fileName: file.fileName),
    );
  }

  @override
  Future<FolhioPastaBiblioteca> criarPasta({
    required EntradaPastaBiblioteca input,
    String? parentId,
  }) async {
    createdFolderNames.add(input.name);
    final folder = _pasta(
      id: 'folder-${folders.length + 1}',
      name: input.name,
      tags: input.tags,
    );
    folders.add(folder);
    return folder;
  }

  @override
  Future<FolhioPastaBiblioteca> atualizarPasta(
    String folderId, {
    required EntradaPastaBiblioteca input,
  }) async {
    final index = folders.indexWhere((folder) => folder.id == folderId);
    final updated = _pasta(id: folderId, name: input.name, tags: input.tags);
    if (index == -1) {
      folders.add(updated);
    } else {
      folders[index] = updated;
    }
    return updated;
  }

  @override
  Future<void> excluirPasta(String folderId) async {
    folders.removeWhere((folder) => folder.id == folderId);
  }

  @override
  Future<FolhioArquivoBiblioteca> moverArquivo(
    String fileId, {
    String? folderId,
    required String folder,
  }) async {
    final index = files.indexWhere((file) => file.id == fileId);
    final current = files[index];
    final moved = FolhioArquivoBiblioteca(
      id: current.id,
      folderId: folderId,
      folder: folder,
      fileName: current.fileName,
      mimeType: current.mimeType,
      sizeBytes: current.sizeBytes,
      storageKey: current.storageKey,
      downloadUrl: current.downloadUrl,
      origin: current.origin,
      updatedAt: current.updatedAt,
    );
    files[index] = moved;
    return moved;
  }

  @override
  Future<FolhioArquivoBiblioteca> renomearArquivo(
    String fileId, {
    required String fileName,
  }) async {
    final index = files.indexWhere((file) => file.id == fileId);
    final current = files[index];
    final renamed = FolhioArquivoBiblioteca(
      id: current.id,
      folderId: current.folderId,
      folder: current.folder,
      fileName: fileName,
      mimeType: current.mimeType,
      sizeBytes: current.sizeBytes,
      storageKey: current.storageKey,
      downloadUrl: current.downloadUrl,
      origin: current.origin,
      updatedAt: current.updatedAt,
    );
    files[index] = renamed;
    return renamed;
  }

  @override
  Future<void> excluirArquivo(String fileId) async {
    files.removeWhere((file) => file.id == fileId);
  }

  @override
  void fechar() {}
}
