import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class CabecalhoPdfViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  CabecalhoPdfViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  File? _selectedFile;
  bool _showStudentLine = true;
  bool _showGradeLine = false;
  bool _applyToAllPages = false;
  bool _processing = false;

  File? get selectedFile => _selectedFile;

  bool get showStudentLine => _showStudentLine;

  bool get showGradeLine => _showGradeLine;

  bool get applyToAllPages => _applyToAllPages;

  bool get processing => _processing;

  void selecionarArquivo(File file) {
    _selectedFile = file;
    notifyListeners();
  }

  void definirExibicaoLinhaAluno(bool value) {
    if (value == _showStudentLine) return;
    _showStudentLine = value;
    notifyListeners();
  }

  void definirExibicaoLinhaNota(bool value) {
    if (value == _showGradeLine) return;
    _showGradeLine = value;
    notifyListeners();
  }

  void definirAplicacaoEmTodasPaginas(bool value) {
    if (value == _applyToAllPages) return;
    _applyToAllPages = value;
    notifyListeners();
  }

  Future<FolhioAcaoResponse> adicionarCabecalho({
    File? fallbackFile,
    required String schoolName,
    required String subject,
    required String className,
    required String teacherName,
    required String dateText,
  }) async {
    final file = _selectedFile ?? fallbackFile;
    if (file == null) {
      throw const ArquivoAusenteCabecalhoPdfException();
    }

    _selectedFile = file;
    _processing = true;
    notifyListeners();
    try {
      return await _repository.adicionarIdentificacaoAtividadeAoPdfLocal(
        file: file,
        schoolName: schoolName.trim(),
        subject: subject.trim(),
        className: className.trim(),
        teacherName: teacherName.trim(),
        dateMode: dateText.trim().isEmpty ? 'blank' : 'custom',
        dateText: dateText.trim(),
        showStudentNameLine: _showStudentLine,
        showGradeLine: _showGradeLine,
        applyToAllPages: _applyToAllPages,
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

class ArquivoAusenteCabecalhoPdfException implements Exception {
  const ArquivoAusenteCabecalhoPdfException();
}
