import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../service/api/folhio_api_gateway.dart';
import '../../model/library/library_models.dart';
import '../../repository/library/biblioteca_repository.dart';

class BibliotecaViewModel extends ChangeNotifier {
  final BibliotecaRepository _repository;

  BibliotecaViewModel({BibliotecaRepository? repository})
    : _repository = repository ?? FolhioBibliotecaRepository();

  BibliotecaState _state = const BibliotecaState();

  BibliotecaState get state => _state;

  List<FolhioPastaBiblioteca> get folders => _state.folders;

  List<FolhioArquivoBiblioteca> get files => _state.files;

  List<FolhioArquivoBiblioteca> get favoriteFiles => _state.favoriteFiles;

  Set<String> get favoriteFileIds => _state.favoriteFileIds;

  List<String> get availableFolderTags => _state.availableFolderTags;

  Map<String, List<String>> get folderTagsById => _state.folderTagsById;

  bool get loading => _state.loading;

  String? get message => _state.message;

  bool podeFavoritar(FolhioArquivoBiblioteca file) {
    return _ehArquivoRealBiblioteca(file);
  }

  bool podeBaixar(FolhioArquivoBiblioteca file) {
    return _ehArquivoRealBiblioteca(file) &&
        (!file.requiresPaidPlan || _hasPaidPlanAccess);
  }

  Future<void> carregarConteudo({
    required String parentId,
    required String search,
  }) async {
    _state = _state.copiarCom(loading: true, clearMessage: true);
    notifyListeners();
    try {
      final snapshot = await _carregarRetrato(parentId: parentId, search: search);
      _state = _state.copiarCom(
        folders: snapshot.folders,
        files: snapshot.files,
        favoriteFiles: snapshot.favoriteFiles,
        favoriteFileIds: snapshot.favoriteFileIds,
        availableFolderTags: snapshot.availableFolderTags,
        folderTagsById: snapshot.folderTagsById,
        loading: false,
        clearMessage: true,
      );
      notifyListeners();
    } catch (error) {
      _state = _state.copiarCom(
        loading: false,
        message: mensagemCarregamentoBiblioteca(error),
      );
      notifyListeners();
    }
  }

  Future<void> baixar(FolhioArquivoBiblioteca file) async {
    if (!_ehArquivoRealBiblioteca(file)) {
      throw const FolhioExibicaoUsuarioException(
        'Esse material ainda não tem arquivo para baixar.',
      );
    }
    if (file.requiresPaidPlan && !_hasPaidPlanAccess) {
      throw const FolhioExibicaoUsuarioException(
        'Esse material faz parte dos planos pagos.',
      );
    }
    await _repository.baixarArquivo(file);
  }

  Future<FolhioArquivoGerado> prepararArquivo(FolhioArquivoBiblioteca file) async {
    if (!_ehArquivoRealBiblioteca(file)) {
      throw const FolhioExibicaoUsuarioException(
        'Esse material ainda não tem arquivo para baixar.',
      );
    }
    if (file.requiresPaidPlan && !_hasPaidPlanAccess) {
      throw const FolhioExibicaoUsuarioException(
        'Esse material faz parte dos planos pagos.',
      );
    }
    return _repository.prepararArquivo(file);
  }

  Future<void> salvarArquivoLocal(
    File file, {
    String? fileName,
    String? folderId,
    required String folder,
    required String search,
  }) async {
    await _repository.salvarArquivoLocalNaBiblioteca(
      file,
      fileName: fileName,
      folderId: folderId,
      folder: folder,
    );
    await carregarConteudo(parentId: folderId ?? 'root', search: search);
  }

  Future<void> salvarArquivoGerado(
    FolhioArquivoGerado file, {
    String? folderId,
    required String folder,
    required String search,
  }) async {
    await _repository.salvarArquivoGeradoNaBiblioteca(
      file,
      folderId: folderId,
      folder: folder,
    );
    await carregarConteudo(parentId: folderId ?? 'root', search: search);
  }

  Future<FolhioPastaBiblioteca> criarPasta({
    required EntradaPastaBiblioteca input,
    String? parentId,
    required String search,
  }) async {
    final folder = await _repository.criarPasta(
      input: input,
      parentId: parentId,
    );
    await carregarConteudo(parentId: parentId ?? 'root', search: search);
    return folder;
  }

  Future<void> atualizarPasta(
    FolhioPastaBiblioteca folder, {
    required EntradaPastaBiblioteca input,
    required String currentParentId,
    required String search,
  }) async {
    await _repository.atualizarPasta(folder.id, input: input);
    await carregarConteudo(parentId: currentParentId, search: search);
  }

  Future<void> excluirPasta(
    FolhioPastaBiblioteca folder, {
    required String currentParentId,
    required String search,
  }) async {
    await _repository.excluirPasta(folder.id);
    await carregarConteudo(parentId: currentParentId, search: search);
  }

  Future<void> moverArquivo(
    FolhioArquivoBiblioteca file, {
    String? folderId,
    required String folder,
    required String currentParentId,
    required String search,
  }) async {
    await _repository.moverArquivo(file.id, folderId: folderId, folder: folder);
    await carregarConteudo(parentId: currentParentId, search: search);
  }

  Future<void> renomearArquivo(
    FolhioArquivoBiblioteca file, {
    required String fileName,
    required String currentParentId,
    required String search,
  }) async {
    await _repository.renomearArquivo(file.id, fileName: fileName);
    await carregarConteudo(parentId: currentParentId, search: search);
  }

  Future<void> excluirArquivo(
    FolhioArquivoBiblioteca file, {
    required String currentParentId,
    required String search,
  }) async {
    await _repository.excluirArquivo(file.id);
    await carregarConteudo(parentId: currentParentId, search: search);
  }

  Future<bool> alternarFavorito(FolhioArquivoBiblioteca file) async {
    if (!podeFavoritar(file)) {
      throw const FolhioExibicaoUsuarioException(
        'Só materiais salvos na Biblioteca podem ser favoritados.',
      );
    }
    final favorite = await _repository.alternarFavorito(file.id);
    final ids = Set<String>.from(_state.favoriteFileIds);
    var favoriteFiles = _state.favoriteFiles;
    if (favorite) {
      ids.add(file.id);
      if (!favoriteFiles.any((item) => item.id == file.id)) {
        favoriteFiles = [file, ...favoriteFiles];
      }
    } else {
      ids.remove(file.id);
      favoriteFiles = favoriteFiles
          .where((item) => item.id != file.id)
          .toList();
    }
    _state = _state.copiarCom(
      favoriteFileIds: ids,
      favoriteFiles: favoriteFiles,
    );
    notifyListeners();
    return favorite;
  }

  bool get _hasPaidPlanAccess {
    // Futuro ponto de integração com assinatura do usuário.
    return false;
  }

  bool _ehArquivoRealBiblioteca(FolhioArquivoBiblioteca file) {
    return file.id.trim().isNotEmpty &&
        (file.storageKey.trim().isNotEmpty ||
            file.downloadUrl.trim().isNotEmpty);
  }

  Future<List<OpcaoDestinoPastaBiblioteca>> arvorePastas() async {
    final result = <OpcaoDestinoPastaBiblioteca>[];

    Future<void> carregarNivel(String? parentId, String prefix) async {
      final children = await _repository.listarPastas(
        parentId: parentId ?? 'root',
        limit: 200,
      );
      for (final folder in children) {
        final label = prefix.isEmpty ? folder.name : '$prefix / ${folder.name}';
        result.add(OpcaoDestinoPastaBiblioteca(folder: folder, label: label));
        await carregarNivel(folder.id, label);
      }
    }

    await carregarNivel(null, '');
    return result;
  }

  Future<RetratoConteudoBiblioteca> _carregarRetrato({
    required String parentId,
    required String search,
  }) async {
    final favoriteIds = await _repository.identificadoresArquivosFavoritos();
    final folders = await _repository.listarPastas(parentId: parentId);
    final files = await _repository.listarArquivos(
      search: search,
      folderId: parentId,
      limit: 100,
    );
    final favoriteFiles = favoriteIds.isEmpty
        ? const <FolhioArquivoBiblioteca>[]
        : (await _repository.listarArquivos(
            limit: 200,
          )).where((file) => favoriteIds.contains(file.id)).toList();
    final tagIndex = indiceEtiquetasPastas(folders);
    return RetratoConteudoBiblioteca(
      folders: folders,
      files: files,
      favoriteFiles: favoriteFiles,
      favoriteFileIds: favoriteIds,
      availableFolderTags: tagIndex.tags,
      folderTagsById: tagIndex.byFolderId,
    );
  }

  @override
  void dispose() {
    _repository.fechar();
    super.dispose();
  }
}

class IndiceEtiquetasPastas {
  final List<String> tags;
  final Map<String, List<String>> byFolderId;

  const IndiceEtiquetasPastas({required this.tags, required this.byFolderId});
}

IndiceEtiquetasPastas indiceEtiquetasPastas(List<FolhioPastaBiblioteca> folders) {
  final tags = <String>{};
  final byFolderId = <String, List<String>>{};
  for (final folder in folders) {
    final parsed = interpretarEtiquetasPasta(folder.tags);
    byFolderId[folder.id] = parsed;
    tags.addAll(parsed);
  }
  final sortedTags = tags.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return IndiceEtiquetasPastas(tags: sortedTags, byFolderId: byFolderId);
}

List<String> interpretarEtiquetasPasta(String raw) {
  return raw
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}

String mensagemCarregamentoBiblioteca(Object error) {
  if (error is FolhioExibicaoUsuarioException) return error.message;
  if (error is FolhioSemInternetException) {
    return 'Sem internet agora. Mostrando o que esta salvo neste aparelho.';
  }
  if (error is FolhioConfiguracaoException) return error.message;
  return 'Nao foi possivel carregar sua biblioteca.';
}
