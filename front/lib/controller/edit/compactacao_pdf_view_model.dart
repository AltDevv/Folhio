import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class CompactacaoPdfViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  CompactacaoPdfViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  static const levels = ['light', 'medium', 'strong'];
  static const estimatedSizes = ['~25% menor', '~50% menor', '~70% menor'];
  static const reductionLabels = ['-25%', '-50%', '-70%'];
  static const compressionDetails = [
    'Mais qualidade',
    'Equilibrado',
    'Menor arquivo',
  ];

  File? _selectedFile;
  int _compressionIndex = 1;
  bool _processing = false;

  File? get selectedFile => _selectedFile;

  int get compressionIndex => _compressionIndex;

  bool get processing => _processing;

  String get selectedLevel => levels[_compressionIndex];

  String get estimatedSize => estimatedSizes[_compressionIndex];

  String get reductionLabel => reductionLabels[_compressionIndex];

  void selecionarArquivo(File file) {
    _selectedFile = file;
    notifyListeners();
  }

  void definirIndiceCompactacao(int index) {
    if (index < 0 || index >= levels.length || index == _compressionIndex) {
      return;
    }
    _compressionIndex = index;
    notifyListeners();
  }

  Future<FolhioAcaoResponse> compactar({File? fallbackFile}) async {
    final file = _selectedFile ?? fallbackFile;
    if (file == null) {
      throw const ArquivoAusenteCompactacaoPdfException();
    }
    _selectedFile = file;
    _processing = true;
    notifyListeners();
    try {
      return await _repository.compactarPdfLocal(
        file: file,
        compressionLevel: selectedLevel,
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

class ArquivoAusenteCompactacaoPdfException implements Exception {
  const ArquivoAusenteCompactacaoPdfException();
}
