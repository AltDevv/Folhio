import 'dart:io';

import '../../controller/converter/conversor_controller.dart';
import '../../controller/edit/edicao_controller.dart';
import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';

abstract class FluxoEdicaoRepository {
  Future<FolhioAcaoResponse> mesclarPdfsLocais(List<File> files);

  Future<FolhioArquivoEnviado> enviarPdf(File file);

  Future<FolhioArquivoEnviado> enviarArquivo(File file, {bool keepProgress = false});

  String urlPreviaPdf(String fileId, {int page = 1});

  Future<FolhioAcaoResponse> recortarPaginas({
    required String fileId,
    required String fileName,
    required List<int> pagesToKeep,
  });

  Future<FolhioAcaoResponse> compactarPdfLocal({
    required File file,
    required String compressionLevel,
  });

  Future<FolhioAcaoResponse> numerarPaginasPdfLocal({
    required File file,
    required String position,
    required int startAtPage,
    required int firstNumber,
    required String format,
  });

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
  });

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
  });

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
  });

  Future<FolhioAcaoResponse> exportarDocumentoEditavel({
    required File file,
    required String sourceMimeType,
    required String outputFormat,
    required List<Map<String, dynamic>> textLayers,
    required List<Map<String, dynamic>> imageLayers,
    required List<Map<String, dynamic>> marks,
  });

  Future<DocumentoEditavelVisual> converterPdfParaWordEditavel(File file);

  void fechar();
}

class FolhioFluxoEdicaoRepository implements FluxoEdicaoRepository {
  final FolhioApiGateway api;
  final bool ownsApi;

  FolhioFluxoEdicaoRepository({FolhioApiGateway? api})
    : api = api ?? FolhioApiGateway(),
      ownsApi = api == null;

  @override
  Future<FolhioAcaoResponse> mesclarPdfsLocais(List<File> files) {
    return EdicaoController(api).mesclarPdfsLocais(files: files);
  }

  @override
  Future<FolhioArquivoEnviado> enviarPdf(File file) {
    return api.enviarArquivo(file);
  }

  @override
  Future<FolhioArquivoEnviado> enviarArquivo(
    File file, {
    bool keepProgress = false,
  }) {
    return api.enviarArquivo(file, keepProgress: keepProgress);
  }

  @override
  String urlPreviaPdf(String fileId, {int page = 1}) {
    return api.urlPreviaPdf(fileId, page: page);
  }

  @override
  Future<FolhioAcaoResponse> recortarPaginas({
    required String fileId,
    required String fileName,
    required List<int> pagesToKeep,
  }) {
    return EdicaoController(
      api,
    ).recortarPaginas(fileId: fileId, fileName: fileName, pagesToKeep: pagesToKeep);
  }

  @override
  Future<FolhioAcaoResponse> compactarPdfLocal({
    required File file,
    required String compressionLevel,
  }) {
    return EdicaoController(
      api,
    ).compactarPdfLocal(file: file, compressionLevel: compressionLevel);
  }

  @override
  Future<FolhioAcaoResponse> numerarPaginasPdfLocal({
    required File file,
    required String position,
    required int startAtPage,
    required int firstNumber,
    required String format,
  }) {
    return EdicaoController(api).numerarPaginasPdfLocal(
      file: file,
      position: position,
      startAtPage: startAtPage,
      firstNumber: firstNumber,
      format: format,
    );
  }

  @override
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
  }) {
    return EdicaoController(api).adicionarIdentificacaoAtividadeAoPdfLocal(
      file: file,
      schoolName: schoolName,
      subject: subject,
      className: className,
      teacherName: teacherName,
      dateMode: dateMode,
      dateText: dateText,
      showStudentNameLine: showStudentNameLine,
      showGradeLine: showGradeLine,
      applyToAllPages: applyToAllPages,
    );
  }

  @override
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
  }) {
    return EdicaoController(api).adicionarAssinaturaAoPdfLocal(
      file: file,
      uploadedPdf: uploadedPdf,
      signatureImage: signatureImage,
      signerName: signerName,
      role: role,
      dateText: dateText,
      position: position,
      xRatio: xRatio,
      yRatio: yRatio,
      widthRatio: widthRatio,
      applyToAllPages: applyToAllPages,
    );
  }

  @override
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
    return EdicaoController(api).exportarImagemVisual(
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
    );
  }

  @override
  Future<FolhioAcaoResponse> exportarDocumentoEditavel({
    required File file,
    required String sourceMimeType,
    required String outputFormat,
    required List<Map<String, dynamic>> textLayers,
    required List<Map<String, dynamic>> imageLayers,
    required List<Map<String, dynamic>> marks,
  }) {
    return EdicaoController(api).exportarDocumentoEditavel(
      file: file,
      sourceMimeType: sourceMimeType,
      outputFormat: outputFormat,
      textLayers: textLayers,
      imageLayers: imageLayers,
      marks: marks,
    );
  }

  @override
  Future<DocumentoEditavelVisual> converterPdfParaWordEditavel(File file) async {
    final response = await ConversorController(api).converterDocumentoLocal(
      file: file,
      sourceMimeType: 'application/pdf',
      targetFormat: 'docx',
      orientation: 'auto',
    );
    final generated = FolhioApiGateway.generatedFile.value;
    if (generated == null) {
      throw const FormatException('A conversao nao retornou um Word editavel.');
    }
    final output = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}${generated.fileName}',
    );
    await output.writeAsBytes(generated.bytes, flush: true);
    return DocumentoEditavelVisual(file: output, response: response);
  }

  @override
  void fechar() {
    if (ownsApi) api.fechar();
  }
}

class DocumentoEditavelVisual {
  final File file;
  final FolhioAcaoResponse response;

  const DocumentoEditavelVisual({required this.file, required this.response});
}
