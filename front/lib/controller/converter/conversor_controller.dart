import 'dart:io';

import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';

class ConversorController {
  final FolhioApiGateway api;

  ConversorController(this.api);

  Future<FolhioAcaoResponse> converterDocumento({
    required String sourceFileId,
    required String sourceFileName,
    required String sourceMimeType,
    required String targetFormat,
    required String orientation,
  }) {
    final legacyName = _nomeConversaoLegado(sourceMimeType, targetFormat);

    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('converter'),
        category: 'converter',
        type: 'convert_document',
        title: 'Converter arquivo',
        description: 'Converte um arquivo enviado pelo app para outro formato.',
        legacyOperationName: legacyName,
        payload: {
          'sourceFile': {
            'id': sourceFileId,
            'name': sourceFileName,
            'mimeType': sourceMimeType,
          },
          'target': {'format': targetFormat, 'orientation': orientation},
          'options': {'preserveLayout': true, 'offlineAllowed': false},
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> converterDocumentoLocal({
    required File file,
    required String sourceMimeType,
    required String targetFormat,
    required String orientation,
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);

    return converterDocumento(
      sourceFileId: uploaded.fileId,
      sourceFileName: uploaded.fileName,
      sourceMimeType: sourceMimeType,
      targetFormat: targetFormat,
      orientation: orientation,
    );
  }

  String _nomeConversaoLegado(String mimeType, String targetFormat) {
    final target = targetFormat.toLowerCase();

    if (mimeType.contains('pdf') && target == 'docx') return 'PDF em Word';
    if (mimeType.contains('pdf') && target == 'png') return 'PDF em PNG';
    if (mimeType.contains('pdf') && target == 'xlsx') return 'PDF em Excel';
    if (mimeType.contains('pdf') && target == 'jpg') return 'PDF em JPG';
    if (mimeType.contains('word') && target == 'pdf') return 'Word em PDF';
    if (mimeType.contains('excel') && target == 'pdf') return 'Excel em PDF';
    if (mimeType.contains('presentation') && target == 'pdf') {
      return 'PPT em PDF';
    }
    if (mimeType.contains('jpeg') && target == 'pdf') return 'JPG em PDF';
    if (mimeType.contains('png') && target == 'pdf') return 'PNG em PDF';
    if (mimeType.contains('jpeg') && target == 'docx') return 'JPG em Word';
    if (mimeType.contains('png') && target == 'docx') return 'PNG em Word';

    return 'ConversÃ£o personalizada';
  }
}
