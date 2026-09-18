import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class MesclagemPdfViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  MesclagemPdfViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  final List<File> _files = [];
  int _selectedFile = 0;
  bool _processing = false;

  List<File> get files => List.unmodifiable(_files);

  int get selectedFile => _selectedFile;

  bool get processing => _processing;

  bool get hasFiles => _files.isNotEmpty;

  String get resultSummary => _files.isEmpty
      ? 'Nenhum PDF selecionado'
      : '${_files.length} PDFs serÃ£o unidos em ordem';

  void adicionarArquivos(List<File> files) {
    if (files.isEmpty) return;
    _files.addAll(files);
    _selectedFile = _files.length - 1;
    notifyListeners();
  }

  void selecionarArquivo(int index) {
    if (index < 0 || index >= _files.length || _selectedFile == index) return;
    _selectedFile = index;
    notifyListeners();
  }

  void reordenarArquivos(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _files.length) return;
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex--;
    if (targetIndex < 0 || targetIndex >= _files.length) return;
    final file = _files.removeAt(oldIndex);
    _files.insert(targetIndex, file);
    _selectedFile = targetIndex;
    notifyListeners();
  }

  Future<FolhioAcaoResponse> mesclarArquivos() async {
    if (_files.isEmpty) {
      throw const ArquivosAusentesMesclagemPdfException();
    }
    _processing = true;
    notifyListeners();
    try {
      return await _repository.mesclarPdfsLocais(_files);
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

class ArquivosAusentesMesclagemPdfException implements Exception {
  const ArquivosAusentesMesclagemPdfException();
}
