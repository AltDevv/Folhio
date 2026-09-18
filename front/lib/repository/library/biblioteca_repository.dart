import 'dart:io';

import '../../service/api/folhio_api_gateway.dart';
import '../../model/library/library_models.dart';

abstract class BibliotecaRepository {
  Future<List<FolhioPastaBiblioteca>> listarPastas({
    required String parentId,
    int limit = 80,
  });

  Future<List<FolhioArquivoBiblioteca>> listarArquivos({
    String search = '',
    String? folderId,
    int limit = 100,
  });

  Future<Set<String>> identificadoresArquivosFavoritos();

  Future<bool> alternarFavorito(String fileId);

  Future<void> baixarArquivo(FolhioArquivoBiblioteca file);

  Future<FolhioArquivoGerado> prepararArquivo(FolhioArquivoBiblioteca file);

  Future<void> salvarArquivoLocalNaBiblioteca(
    File file, {
    String? fileName,
    String? folderId,
    required String folder,
  });

  Future<void> salvarArquivoGeradoNaBiblioteca(
    FolhioArquivoGerado file, {
    String? folderId,
    required String folder,
  });

  Future<FolhioPastaBiblioteca> criarPasta({
    required EntradaPastaBiblioteca input,
    String? parentId,
  });

  Future<FolhioPastaBiblioteca> atualizarPasta(
    String folderId, {
    required EntradaPastaBiblioteca input,
  });

  Future<void> excluirPasta(String folderId);

  Future<FolhioArquivoBiblioteca> moverArquivo(
    String fileId, {
    String? folderId,
    required String folder,
  });

  Future<FolhioArquivoBiblioteca> renomearArquivo(
    String fileId, {
    required String fileName,
  });

  Future<void> excluirArquivo(String fileId);

  void fechar();
}

class FolhioBibliotecaRepository implements BibliotecaRepository {
  final FolhioApiGateway api;
  final bool ownsApi;

  FolhioBibliotecaRepository({FolhioApiGateway? api})
    : api = api ?? FolhioApiGateway(),
      ownsApi = api == null;

  @override
  Future<List<FolhioPastaBiblioteca>> listarPastas({
    required String parentId,
    int limit = 80,
  }) {
    return api.listarPastasBiblioteca(parentId: parentId, limit: limit);
  }

  @override
  Future<List<FolhioArquivoBiblioteca>> listarArquivos({
    String search = '',
    String? folderId,
    int limit = 100,
  }) {
    return api.listarArquivosBiblioteca(
      search: search,
      folderId: folderId,
      limit: limit,
    );
  }

  @override
  Future<Set<String>> identificadoresArquivosFavoritos() {
    return api.identificadoresFavoritosBiblioteca();
  }

  @override
  Future<bool> alternarFavorito(String fileId) {
    return api.alternarFavoritoArquivoBiblioteca(fileId);
  }

  @override
  Future<void> baixarArquivo(FolhioArquivoBiblioteca file) {
    return api.baixarArquivoBiblioteca(file);
  }

  @override
  Future<FolhioArquivoGerado> prepararArquivo(FolhioArquivoBiblioteca file) {
    return api.baixarArquivoBiblioteca(file, showReadyOverlay: false);
  }

  @override
  Future<void> salvarArquivoLocalNaBiblioteca(
    File file, {
    String? fileName,
    String? folderId,
    required String folder,
  }) {
    return api.salvarArquivoLocalNaBiblioteca(
      file,
      fileName: fileName,
      folderId: folderId,
      folder: folder,
    );
  }

  @override
  Future<void> salvarArquivoGeradoNaBiblioteca(
    FolhioArquivoGerado file, {
    String? folderId,
    required String folder,
  }) {
    return api.salvarArquivoGeradoNaBiblioteca(
      file,
      folderId: folderId,
      folder: folder,
    );
  }

  @override
  Future<FolhioPastaBiblioteca> criarPasta({
    required EntradaPastaBiblioteca input,
    String? parentId,
  }) {
    return api.criarPastaBiblioteca(
      name: input.name,
      parentId: parentId,
      tags: input.tags,
      notes: input.notes,
      links: input.links,
    );
  }

  @override
  Future<FolhioPastaBiblioteca> atualizarPasta(
    String folderId, {
    required EntradaPastaBiblioteca input,
  }) {
    return api.atualizarPastaBiblioteca(
      folderId,
      name: input.name,
      tags: input.tags,
      notes: input.notes,
      links: input.links,
    );
  }

  @override
  Future<void> excluirPasta(String folderId) {
    return api.excluirPastaBiblioteca(folderId);
  }

  @override
  Future<FolhioArquivoBiblioteca> moverArquivo(
    String fileId, {
    String? folderId,
    required String folder,
  }) {
    return api.moverArquivoBiblioteca(fileId, folderId: folderId, folder: folder);
  }

  @override
  Future<FolhioArquivoBiblioteca> renomearArquivo(
    String fileId, {
    required String fileName,
  }) {
    return api.renomearArquivoBiblioteca(fileId, fileName: fileName);
  }

  @override
  Future<void> excluirArquivo(String fileId) {
    return api.excluirArquivoBiblioteca(fileId);
  }

  @override
  void fechar() {
    if (ownsApi) api.fechar();
  }
}
