import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class AssinaturaPdfViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  AssinaturaPdfViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  double _signatureX = 0.62;
  double _signatureY = 0.78;
  double _signatureWidth = 0.28;
  bool _applyToAllPages = false;
  File? _selectedFile;
  FolhioArquivoEnviado? _uploadedPdf;
  String? _pdfPreviewUrl;
  File? _signatureImage;
  bool _processing = false;

  double get signatureX => _signatureX;

  double get signatureY => _signatureY;

  double get signatureWidth => _signatureWidth;

  bool get applyToAllPages => _applyToAllPages;

  File? get selectedFile => _selectedFile;

  FolhioArquivoEnviado? get uploadedPdf => _uploadedPdf;

  String? get pdfPreviewUrl => _pdfPreviewUrl;

  File? get signatureImage => _signatureImage;

  bool get processing => _processing;

  Future<void> selecionarPdf(File file) async {
    _selectedFile = file;
    _uploadedPdf = null;
    _pdfPreviewUrl = null;
    _processing = true;
    notifyListeners();
    try {
      final uploaded = await _repository.enviarPdf(file);
      _uploadedPdf = uploaded;
      _pdfPreviewUrl = _repository.urlPreviaPdf(uploaded.fileId);
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  void selecionarImagemAssinatura(File file) {
    _signatureImage = file;
    _signatureX = 0.50;
    _signatureY = 0.72;
    notifyListeners();
  }

  void definirPosicaoAssinatura(double xRatio, double yRatio) {
    _signatureX = xRatio;
    _signatureY = yRatio;
    notifyListeners();
  }

  void definirPercentualLarguraAssinatura(int percent) {
    final next = percent.clamp(8, 60) / 100;
    if (next == _signatureWidth) return;
    _signatureWidth = next;
    notifyListeners();
  }

  void definirAplicacaoEmTodasPaginas(bool value) {
    if (value == _applyToAllPages) return;
    _applyToAllPages = value;
    notifyListeners();
  }

  Future<FolhioAcaoResponse> adicionarAssinatura() async {
    final file = _selectedFile;
    if (file == null) {
      throw const ArquivoAusenteAssinaturaPdfException();
    }
    if (_signatureImage == null) {
      throw const ImagemAusenteAssinaturaPdfException();
    }

    _processing = true;
    notifyListeners();
    try {
      return await _repository.adicionarAssinaturaAoPdfLocal(
        file: file,
        uploadedPdf: _uploadedPdf,
        signatureImage: _signatureImage,
        signerName: '',
        role: '',
        dateText: '',
        position: 'custom',
        xRatio: _signatureX,
        yRatio: _signatureY,
        widthRatio: _signatureWidth,
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

class ArquivoAusenteAssinaturaPdfException implements Exception {
  const ArquivoAusenteAssinaturaPdfException();
}

class ImagemAusenteAssinaturaPdfException implements Exception {
  const ImagemAusenteAssinaturaPdfException();
}
