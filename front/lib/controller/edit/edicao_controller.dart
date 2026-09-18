import 'dart:io';

import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';

class EdicaoController {
  final FolhioApiGateway api;

  EdicaoController(this.api);

  Future<FolhioAcaoResponse> aplicarLayoutPdf({
    required String fileId,
    required String fileName,
    required int pagesPerSheet,
    required bool landscape,
    required int pageMargin,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-layout'),
        category: 'edit',
        type: 'pdf_layout',
        title: 'PÃ¡ginas por folha',
        description: 'Reorganiza pÃ¡ginas de um PDF para economizar impressao.',
        legacyOperationName: 'PDF $pagesPerSheet por folha',
        payload: {
          'file': {
            'id': fileId,
            'name': fileName,
            'mimeType': 'application/pdf',
          },
          'layout': {
            'pagesPerSheet': pagesPerSheet,
            'orientation': landscape ? 'landscape' : 'portrait',
            'pageMargin': pageMargin,
          },
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> aplicarLayoutPdfLocal({
    required File file,
    required int pagesPerSheet,
    required bool landscape,
    required int pageMargin,
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    return aplicarLayoutPdf(
      fileId: uploaded.fileId,
      fileName: uploaded.fileName,
      pagesPerSheet: pagesPerSheet,
      landscape: landscape,
      pageMargin: pageMargin,
    );
  }

  Future<FolhioAcaoResponse> criarPosterPdf({
    required String fileId,
    required String fileName,
    required String mimeType,
    required int sheetsWide,
    required int sheetsTall,
    required int pageMargin,
  }) {
    final totalSheets = sheetsWide * sheetsTall;
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-poster'),
        category: 'edit',
        type: 'pdf_poster',
        title: 'PDF em pôster',
        description:
            'Divide um PDF ou imagem em folhas A4 para impressão grande.',
        legacyOperationName: 'PDF pôster $totalSheets partes',
        payload: {
          'file': {'id': fileId, 'name': fileName, 'mimeType': mimeType},
          'poster': {
            'sheetsWide': sheetsWide,
            'sheetsTall': sheetsTall,
            'pageMargin': pageMargin,
          },
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> criarPosterPdfLocal({
    required File file,
    required int sheetsWide,
    required int sheetsTall,
    required int pageMargin,
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    return criarPosterPdf(
      fileId: uploaded.fileId,
      fileName: uploaded.fileName,
      mimeType: uploaded.mimeType,
      sheetsWide: sheetsWide,
      sheetsTall: sheetsTall,
      pageMargin: pageMargin,
    );
  }

  Future<FolhioAcaoResponse> recortarPaginas({
    required String fileId,
    required String fileName,
    required List<int> pagesToKeep,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-cut'),
        category: 'edit',
        type: 'cut_pages',
        title: 'Recortar pÃ¡ginas',
        description:
            'Cria um novo PDF mantendo somente as pÃ¡ginas escolhidas.',
        legacyOperationName: 'Extrair pÃ¡ginas de PDFs',
        payload: {
          'file': {
            'id': fileId,
            'name': fileName,
            'mimeType': 'application/pdf',
          },
          'pagesToKeep': pagesToKeep,
          'preserveOrder': true,
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> mesclarPdfs({
    required List<Map<String, dynamic>> files,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-merge'),
        category: 'edit',
        type: 'merge_pdfs',
        title: 'Mesclar PDFs',
        description: 'Une varios PDFs em um unico arquivo final.',
        legacyOperationName: 'Mesclar PDFs',
        payload: {'files': files, 'orderField': 'position'},
      ),
    );
  }

  Future<FolhioAcaoResponse> mesclarPdfsLocais({
    required List<File> files,
  }) async {
    final uploadedFiles = <Map<String, dynamic>>[];
    for (final (index, file) in files.indexed) {
      final uploaded = await api.enviarArquivo(file, keepProgress: true);
      uploadedFiles.add({
        'id': uploaded.fileId,
        'name': uploaded.fileName,
        'mimeType': uploaded.mimeType,
        'position': index,
      });
    }
    return mesclarPdfs(files: uploadedFiles);
  }

  Future<FolhioAcaoResponse> compactarPdf({
    required String fileId,
    required String fileName,
    required String compressionLevel,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-compress'),
        category: 'edit',
        type: 'compress_pdf',
        title: 'Comprimir PDF',
        description: 'Reduz o tamanho do PDF conforme o nivel escolhido.',
        payload: {
          'file': {
            'id': fileId,
            'name': fileName,
            'mimeType': 'application/pdf',
          },
          'compression': {
            'level': compressionLevel,
            'allowedLevels': ['light', 'medium', 'strong'],
          },
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> compactarPdfLocal({
    required File file,
    required String compressionLevel,
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    return compactarPdf(
      fileId: uploaded.fileId,
      fileName: uploaded.fileName,
      compressionLevel: compressionLevel,
    );
  }

  Future<FolhioAcaoResponse> adicionarIdentificacaoAtividadeAoPdfLocal({
    required File file,
    required String schoolName,
    required String subject,
    required String className,
    required String teacherName,
    required String dateMode,
    required String dateText,
    required bool showStudentNameLine,
    required bool showGradeLine,
    required bool applyToAllPages,
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-identification'),
        category: 'edit',
        type: 'add_header',
        title: 'IdentificaÃ§Ã£o da atividade',
        description: 'Aplica dados escolares no PDF da atividade.',
        payload: {
          'file': {'id': uploaded.fileId, 'name': uploaded.fileName},
          'header': {
            'schoolName': schoolName,
            'subject': subject,
            'className': className,
            'teacherName': teacherName,
            'dateMode': dateMode,
            'dateText': dateText,
            'showStudentNameLine': showStudentNameLine,
            'showGradeLine': showGradeLine,
            'applyToAllPages': applyToAllPages,
          },
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> numerarPaginas({
    required String fileId,
    required String fileName,
    required String position,
    required int startAtPage,
    required int firstNumber,
    required String format,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-number'),
        category: 'edit',
        type: 'number_pages',
        title: 'Numerar pÃ¡ginas',
        description: 'Adiciona numeraÃ§Ã£o as pÃ¡ginas do documento.',
        payload: {
          'file': {'id': fileId, 'name': fileName},
          'numbering': {
            'position': position,
            'startAtPage': startAtPage,
            'firstNumber': firstNumber,
            'format': format,
          },
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> numerarPaginasPdfLocal({
    required File file,
    required String position,
    required int startAtPage,
    required int firstNumber,
    required String format,
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    return numerarPaginas(
      fileId: uploaded.fileId,
      fileName: uploaded.fileName,
      position: position,
      startAtPage: startAtPage,
      firstNumber: firstNumber,
      format: format,
    );
  }

  Future<FolhioAcaoResponse> adicionarAssinaturaAoPdfLocal({
    required File file,
    FolhioArquivoEnviado? uploadedPdf,
    required File? signatureImage,
    required String signerName,
    required String role,
    required String dateText,
    required String position,
    required double xRatio,
    required double yRatio,
    required double widthRatio,
    required bool applyToAllPages,
  }) async {
    final uploaded =
        uploadedPdf ?? await api.enviarArquivo(file, keepProgress: true);
    final uploadedSignature = signatureImage == null
        ? null
        : await api.enviarArquivo(signatureImage, keepProgress: true);
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-signature'),
        category: 'edit',
        type: 'add_signature',
        title: 'Adicionar assinatura',
        description: 'Adiciona uma imagem de assinatura ao PDF.',
        payload: {
          'file': {'id': uploaded.fileId, 'name': uploaded.fileName},
          'signature': {
            if (uploadedSignature != null)
              'image': {
                'id': uploadedSignature.fileId,
                'name': uploadedSignature.fileName,
                'mimeType': uploadedSignature.mimeType,
              },
            'signerName': signerName,
            'role': role,
            'dateText': dateText,
            'position': position,
            'xRatio': xRatio,
            'yRatio': yRatio,
            'widthRatio': widthRatio,
            'applyToAllPages': applyToAllPages,
          },
        },
      ),
    );
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
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    final cropPayload = crop == null
        ? <String, dynamic>{}
        : <String, dynamic>{'crop': crop};
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-visual-image'),
        category: 'edit',
        type: 'visual_image_edit',
        title: 'EdiÃ§Ã£o de imagem',
        description: 'Aplica ajustes visuais em uma imagem.',
        payload: {
          'file': {
            'id': uploaded.fileId,
            'name': uploaded.fileName,
            'mimeType': uploaded.mimeType,
          },
          'visual': {
            'quarterTurns': quarterTurns,
            'rotationDegrees': rotationDegrees,
            'mirrored': mirrored,
            'brightness': brightness,
            'contrast': contrast,
            'removeBackground': removeBackground,
            'cropShape': cropShape,
            'textLayers': textLayers,
            'imageLayers': imageLayers,
            ...cropPayload,
            'marks': marks,
          },
        },
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
  }) async {
    final uploaded = await api.enviarArquivo(file, keepProgress: true);
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('edit-document'),
        category: 'edit',
        type: 'editable_document_export',
        title: 'Editor de documento',
        description:
            'Aplica ediÃ§Ãµes em documento Word e exporta no formato solicitado.',
        payload: {
          'file': {
            'id': uploaded.fileId,
            'name': uploaded.fileName,
            'mimeType': sourceMimeType,
          },
          'document': {
            'workingFormat': 'docx',
            'outputFormat': outputFormat,
            'textLayers': textLayers,
            'imageLayers': imageLayers,
            'marks': marks,
          },
        },
      ),
    );
  }
}
