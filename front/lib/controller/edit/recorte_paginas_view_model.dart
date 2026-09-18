import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class RecortePaginasViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  RecortePaginasViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  final Set<int> _selectedPages = {};
  File? _selectedFile;
  FolhioArquivoEnviado? _uploadedFile;
  int _pageCount = 8;
  bool _processing = false;

  Set<int> get selectedPages => Set.unmodifiable(_selectedPages);

  File? get selectedFile => _selectedFile;

  FolhioArquivoEnviado? get uploadedFile => _uploadedFile;

  int get pageCount => _pageCount;

  bool get processing => _processing;

  String get selectedLabel =>
      _selectedPages.map((page) => 'p.$page').join('  Â·  ');

  String? urlPreviaPagina(int page) {
    final uploaded = _uploadedFile;
    return uploaded == null
        ? null
        : _repository.urlPreviaPdf(uploaded.fileId, page: page);
  }

  Future<void> selecionarPdf(File file) async {
    _selectedFile = file;
    _processing = true;
    notifyListeners();
    try {
      final uploaded = await _repository.enviarPdf(file);
      final count = uploaded.pageCount ?? 8;
      _uploadedFile = uploaded;
      _pageCount = count;
      _selectedPages
        ..clear()
        ..addAll(List.generate(count, (index) => index + 1));
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  void alternarPagina(int page) {
    if (_selectedPages.contains(page)) {
      _selectedPages.remove(page);
    } else {
      _selectedPages.add(page);
    }
    notifyListeners();
  }

  void selecionarTodos() {
    _selectedPages
      ..clear()
      ..addAll(List.generate(_pageCount, (index) => index + 1));
    notifyListeners();
  }

  void limparSelecao() {
    _selectedPages.clear();
    notifyListeners();
  }

  Future<FolhioAcaoResponse> recortarPaginas() async {
    final uploaded = _uploadedFile;
    if (_selectedFile == null || uploaded == null) {
      throw const ArquivoAusenteRecortePaginasException();
    }
    _processing = true;
    notifyListeners();
    try {
      final pages = _selectedPages.toList()..sort();
      return await _repository.recortarPaginas(
        fileId: uploaded.fileId,
        fileName: uploaded.fileName,
        pagesToKeep: pages,
      );
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repository.fechar();
    super.dispose();
  }
}

class ArquivoAusenteRecortePaginasException implements Exception {
  const ArquivoAusenteRecortePaginasException();
}
