import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../repository/edit/fluxo_edicao_repository.dart';

class EdicaoVisualViewModel extends ChangeNotifier {
  final FluxoEdicaoRepository _repository;

  EdicaoVisualViewModel({FluxoEdicaoRepository? repository})
    : _repository = repository ?? FolhioFluxoEdicaoRepository();

  bool _processing = false;

  bool get processing => _processing;

  Future<FolhioArquivoEnviado> enviarArquivoCamada(File file) {
    return _repository.enviarArquivo(file, keepProgress: true);
  }

  Future<FolhioAcaoResponse> exportarImagemVisual({
    required File file,
    required int quarterTurns,
    required double rotationDegrees,
    required bool mirrored,
    required int brightness,
    required int contrast,
    required bool removeBackground,
    required String cropShape,
    required List<Map<String, dynamic>> textLayers,
    required List<Map<String, dynamic>> imageLayers,
    required Map<String, dynamic>? crop,
    required List<Map<String, dynamic>> marks,
  }) {
    return _executar(
      () => _repository.exportarImagemVisual(
        file: file,
        quarterTurns: quarterTurns,
        rotationDegrees: rotationDegrees,
        mirrored: mirrored,
        brightness: brightness,
        contrast: contrast,
        removeBackground: removeBackground,
        cropShape: cropShape,
        textLayers: textLayers,
        imageLayers: imageLayers,
        crop: crop,
        marks: marks,
      ),
    );
  }

  Future<FolhioAcaoResponse> exportarDocumentoEditavel({
    required File file,
    required String sourceMimeType,
    required String outputFormat,
    required List<Map<String, dynamic>> textLayers,
    required List<Map<String, dynamic>> imageLayers,
    required List<Map<String, dynamic>> marks,
  }) {
    return _executar(
      () => _repository.exportarDocumentoEditavel(
        file: file,
        sourceMimeType: sourceMimeType,
        outputFormat: outputFormat,
        textLayers: textLayers,
        imageLayers: imageLayers,
        marks: marks,
      ),
    );
  }

  Future<DocumentoEditavelVisual> converterPdfParaWordEditavel(File file) {
    return _executar(() => _repository.converterPdfParaWordEditavel(file));
  }

  Future<T> _executar<T>(Future<T> Function() action) async {
    _processing = true;
    notifyListeners();
    try {
      return await action();
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
