import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class NumeracaoPaginasViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  NumeracaoPaginasViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  static const positions = [
    'bottom_center',
    'bottom_right',
    'bottom_left',
    'top_center',
    'top_right',
    'top_left',
  ];

  static const formats = ['plain', 'fraction', 'page_prefix'];

  File? _selectedFile;
  int _positionIndex = 1;
  int _startPage = 1;
  int _firstNumber = 1;
  int _formatIndex = 0;
  int _pageCount = 1;
  bool _processing = false;

  File? get selectedFile => _selectedFile;

  int get positionIndex => _positionIndex;

  int get startPage => _startPage;

  int get firstNumber => _firstNumber;

  int get formatIndex => _formatIndex;

  int get pageCount => _pageCount;

  bool get processing => _processing;

  String get selectedPosition => positions[_positionIndex];

  String get selectedFormat => formats[_formatIndex];

  Future<void> selecionarPdf(File file) async {
    _selectedFile = file;
    _processing = true;
    notifyListeners();
    try {
      final uploaded = await _repository.enviarPdf(file);
      final count = uploaded.pageCount ?? 1;
      _pageCount = count < 1 ? 1 : count;
      _startPage = _startPage.clamp(1, _pageCount).toInt();
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  void definirIndicePosicao(int index) {
    if (index < 0 || index >= positions.length || index == _positionIndex) {
      return;
    }
    _positionIndex = index;
    notifyListeners();
  }

  void definirPaginaInicial(int value) {
    final next = value.clamp(1, _pageCount).toInt();
    if (next == _startPage) return;
    _startPage = next;
    notifyListeners();
  }

  void definirNumeroInicial(int value) {
    final next = value.clamp(1, 999).toInt();
    if (next == _firstNumber) return;
    _firstNumber = next;
    notifyListeners();
  }

  void definirIndiceFormato(int index) {
    if (index < 0 || index >= formats.length || index == _formatIndex) {
      return;
    }
    _formatIndex = index;
    notifyListeners();
  }

  Future<FolhioAcaoResponse> numerarPaginas({File? fallbackFile}) async {
    final file = _selectedFile ?? fallbackFile;
    if (file == null) {
      throw const ArquivoAusenteNumeracaoPaginasException();
    }
    _selectedFile = file;
    _processing = true;
    notifyListeners();
    try {
      return await _repository.numerarPaginasPdfLocal(
        file: file,
        position: selectedPosition,
        startAtPage: _startPage,
        firstNumber: _firstNumber,
        format: selectedFormat,
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

class ArquivoAusenteNumeracaoPaginasException implements Exception {
  const ArquivoAusenteNumeracaoPaginasException();
}
