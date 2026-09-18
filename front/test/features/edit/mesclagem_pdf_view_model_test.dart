import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/dto/folhio_action.dart';
import 'package:folhio/service/api/folhio_api_gateway.dart';
import 'package:folhio/repository/edit/fluxo_edicao_repository.dart';
import 'package:folhio/controller/edit/mesclagem_pdf_view_model.dart';

void main() {
  test('MergePdfsViewModel adiciona, seleciona e reordena arquivos', () {
    final viewModel = MesclagemPdfViewModel(repository: _SimuladoEdicaoRepository());
    final first = File('primeiro.pdf');
    final second = File('segundo.pdf');

    viewModel.adicionarArquivos([first, second]);

    expect(viewModel.files, [first, second]);
    expect(viewModel.selectedFile, 1);
    expect(viewModel.resultSummary, '2 PDFs serÃ£o unidos em ordem');

    viewModel.selecionarArquivo(0);
    expect(viewModel.selectedFile, 0);

    viewModel.reordenarArquivos(0, 2);
    expect(viewModel.files, [second, first]);
    expect(viewModel.selectedFile, 1);

    viewModel.dispose();
  });

  test('MergePdfsViewModel delega merge ao repository', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = MesclagemPdfViewModel(repository: repository);
    final file = File('aula.pdf');

    viewModel.adicionarArquivos([file]);
    final response = await viewModel.mesclarArquivos();

    expect(response.success, isTrue);
    expect(repository.mergedFiles, [file]);
    expect(viewModel.processing, isFalse);

    viewModel.dispose();
  });

  test('MergePdfsViewModel exige arquivos antes de mesclar', () async {
    final viewModel = MesclagemPdfViewModel(repository: _SimuladoEdicaoRepository());

    expect(
      viewModel.mesclarArquivos,
      throwsA(isA<ArquivosAusentesMesclagemPdfException>()),
    );

    viewModel.dispose();
  });
}

class _SimuladoEdicaoRepository implements FluxoEdicaoRepository {
  List<File> mergedFiles = const [];

  @override
  Future<FolhioAcaoResponse> mesclarPdfsLocais(List<File> files) async {
    mergedFiles = [...files];
    return FolhioAcaoResponse(
      requestId: 'test',
      success: true,
      status: 'completed',
      message: 'PDFs unidos.',
      data: const {},
    );
  }

  @override
  Future<FolhioArquivoEnviado> enviarPdf(File file) async {
    return const FolhioArquivoEnviado(
      fileId: 'uploaded',
      fileName: 'uploaded.pdf',
      mimeType: 'application/pdf',
      pageCount: 3,
    );
  }

  @override
  Future<FolhioArquivoEnviado> enviarArquivo(
    File file, {
    bool keepProgress = false,
  }) {
    return enviarPdf(file);
  }

  @override
  String urlPreviaPdf(String fileId, {int page = 1}) {
    return 'https://example.com/$fileId/$page';
  }

  @override
  Future<FolhioAcaoResponse> recortarPaginas({
    required String fileId,
    required String fileName,
    required List<int> pagesToKeep,
  }) async {
    return FolhioAcaoResponse(
      requestId: 'cut',
      success: true,
      status: 'completed',
      message: 'PDF recortado.',
      data: const {},
    );
  }

  @override
  Future<FolhioAcaoResponse> compactarPdfLocal({
    required File file,
    required String compressionLevel,
  }) async {
    return FolhioAcaoResponse(
      requestId: 'compress',
      success: true,
      status: 'completed',
      message: 'PDF comprimido.',
      data: const {},
    );
  }

  @override
  Future<FolhioAcaoResponse> numerarPaginasPdfLocal({
    required File file,
    required String position,
    required int startAtPage,
    required int firstNumber,
    required String format,
  }) async {
    return FolhioAcaoResponse(
      requestId: 'number',
      success: true,
      status: 'completed',
      message: 'PDF numerado.',
      data: const {},
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
  }) async {
    return FolhioAcaoResponse(
      requestId: 'header',
      success: true,
      status: 'completed',
      message: 'Identificacao aplicada.',
      data: const {},
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
  }) async {
    return FolhioAcaoResponse(
      requestId: 'signature',
      success: true,
      status: 'completed',
      message: 'Assinatura aplicada.',
      data: const {},
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
  }) async {
    return FolhioAcaoResponse(
      requestId: 'visual',
      success: true,
      status: 'completed',
      message: 'Imagem exportada.',
      data: const {},
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
  }) async {
    return FolhioAcaoResponse(
      requestId: 'document',
      success: true,
      status: 'completed',
      message: 'Documento exportado.',
      data: const {},
    );
  }

  @override
  Future<DocumentoEditavelVisual> converterPdfParaWordEditavel(File file) async {
    return DocumentoEditavelVisual(
      file: File('convertido.docx'),
      response: FolhioAcaoResponse(
        requestId: 'convert',
        success: true,
        status: 'completed',
        message: 'PDF convertido.',
        data: const {},
      ),
    );
  }

  @override
  void fechar() {}
}
