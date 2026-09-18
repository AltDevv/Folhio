import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/dto/folhio_action.dart';
import 'package:folhio/service/api/folhio_api_gateway.dart';
import 'package:folhio/repository/edit/fluxo_edicao_repository.dart';
import 'package:folhio/controller/edit/compactacao_pdf_view_model.dart';
import 'package:folhio/controller/edit/recorte_paginas_view_model.dart';
import 'package:folhio/controller/edit/cabecalho_pdf_view_model.dart';
import 'package:folhio/controller/edit/numeracao_paginas_view_model.dart';
import 'package:folhio/controller/edit/assinatura_pdf_view_model.dart';
import 'package:folhio/controller/edit/edicao_visual_view_model.dart';

void main() {
  test('CompressPdfViewModel seleciona nivel e delega compressao', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = CompactacaoPdfViewModel(repository: repository);
    final file = File('prova.pdf');

    viewModel.selecionarArquivo(file);
    viewModel.definirIndiceCompactacao(2);
    final response = await viewModel.compactar();

    expect(response.success, isTrue);
    expect(repository.compressedFile, file);
    expect(repository.compressionLevel, 'strong');
    expect(viewModel.processing, isFalse);

    viewModel.dispose();
  });

  test('CutPagesViewModel envia PDF, seleciona paginas e recorta', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = RecortePaginasViewModel(repository: repository);
    final file = File('lista.pdf');

    await viewModel.selecionarPdf(file);

    expect(viewModel.pageCount, 4);
    expect(viewModel.selectedPages, {1, 2, 3, 4});
    expect(viewModel.urlPreviaPagina(2), 'https://example.com/file-1/2');

    viewModel.alternarPagina(2);
    final response = await viewModel.recortarPaginas();

    expect(response.success, isTrue);
    expect(repository.cutFileId, 'file-1');
    expect(repository.cutPagesToKeep, [1, 3, 4]);
    expect(viewModel.processing, isFalse);

    viewModel.dispose();
  });

  test('NumberPagesViewModel carrega paginas e delega numeracao', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = NumeracaoPaginasViewModel(repository: repository);
    final file = File('apostila.pdf');

    await viewModel.selecionarPdf(file);
    viewModel.definirIndicePosicao(4);
    viewModel.definirPaginaInicial(2);
    viewModel.definirNumeroInicial(10);
    viewModel.definirIndiceFormato(1);
    final response = await viewModel.numerarPaginas();

    expect(response.success, isTrue);
    expect(viewModel.pageCount, 4);
    expect(repository.numberedFile, file);
    expect(repository.numberPosition, 'top_right');
    expect(repository.numberStartAtPage, 2);
    expect(repository.numberFirstNumber, 10);
    expect(repository.numberFormat, 'fraction');

    viewModel.dispose();
  });

  test('HeaderPdfViewModel aplica identificacao com campos e opcoes', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = CabecalhoPdfViewModel(repository: repository);
    final file = File('atividade.pdf');

    viewModel.selecionarArquivo(file);
    viewModel.definirExibicaoLinhaNota(true);
    viewModel.definirAplicacaoEmTodasPaginas(true);
    final response = await viewModel.adicionarCabecalho(
      schoolName: ' Escola ',
      subject: 'Matematica',
      className: '8A',
      teacherName: 'Ana',
      dateText: '02/06/2026',
    );

    expect(response.success, isTrue);
    expect(repository.headerFile, file);
    expect(repository.headerSchoolName, 'Escola');
    expect(repository.headerShowStudentLine, isTrue);
    expect(repository.headerShowGradeLine, isTrue);
    expect(repository.headerApplyToAllPages, isTrue);
    expect(repository.headerDateMode, 'custom');
    expect(viewModel.processing, isFalse);

    viewModel.dispose();
  });

  test('SignaturePdfViewModel prepara previa e delega assinatura', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = AssinaturaPdfViewModel(repository: repository);
    final pdf = File('certificado.pdf');
    final image = File('assinatura.png');

    await viewModel.selecionarPdf(pdf);
    viewModel.selecionarImagemAssinatura(image);
    viewModel.definirPosicaoAssinatura(0.4, 0.7);
    viewModel.definirPercentualLarguraAssinatura(35);
    viewModel.definirAplicacaoEmTodasPaginas(true);
    final response = await viewModel.adicionarAssinatura();

    expect(response.success, isTrue);
    expect(viewModel.pdfPreviewUrl, 'https://example.com/file-1/1');
    expect(repository.signatureFile, pdf);
    expect(repository.signatureImage, image);
    expect(repository.signatureXRatio, 0.4);
    expect(repository.signatureYRatio, 0.7);
    expect(repository.signatureWidthRatio, 0.35);
    expect(repository.signatureApplyToAllPages, isTrue);
    expect(viewModel.processing, isFalse);

    viewModel.dispose();
  });

  test('VisualEditViewModel delega exportacao visual', () async {
    final repository = _SimuladoEdicaoRepository();
    final viewModel = EdicaoVisualViewModel(repository: repository);
    final file = File('imagem.png');

    final response = await viewModel.exportarImagemVisual(
      file: file,
      quarterTurns: 1,
      rotationDegrees: 12,
      mirrored: true,
      brightness: 5,
      contrast: 7,
      removeBackground: false,
      cropShape: 'circle',
      textLayers: const [
        {'text': 'Oi'},
      ],
      imageLayers: const [],
      crop: const {'x': 0.1},
      marks: const [],
    );

    expect(response.success, isTrue);
    expect(repository.visualFile, file);
    expect(repository.visualQuarterTurns, 1);
    expect(repository.visualMirrored, isTrue);
    expect(repository.visualCropShape, 'circle');
    expect(viewModel.processing, isFalse);

    viewModel.dispose();
  });
}

class _SimuladoEdicaoRepository implements FluxoEdicaoRepository {
  File? compressedFile;
  String? compressionLevel;
  String? cutFileId;
  List<int> cutPagesToKeep = const [];
  File? numberedFile;
  String? numberPosition;
  int? numberStartAtPage;
  int? numberFirstNumber;
  String? numberFormat;
  File? headerFile;
  String? headerSchoolName;
  String? headerDateMode;
  bool? headerShowStudentLine;
  bool? headerShowGradeLine;
  bool? headerApplyToAllPages;
  File? signatureFile;
  File? signatureImage;
  double? signatureXRatio;
  double? signatureYRatio;
  double? signatureWidthRatio;
  bool? signatureApplyToAllPages;
  File? visualFile;
  int? visualQuarterTurns;
  bool? visualMirrored;
  String? visualCropShape;

  @override
  Future<FolhioArquivoEnviado> enviarPdf(File file) async {
    return const FolhioArquivoEnviado(
      fileId: 'file-1',
      fileName: 'lista.pdf',
      mimeType: 'application/pdf',
      pageCount: 4,
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
    cutFileId = fileId;
    cutPagesToKeep = [...pagesToKeep];
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
    compressedFile = file;
    this.compressionLevel = compressionLevel;
    return FolhioAcaoResponse(
      requestId: 'compress',
      success: true,
      status: 'completed',
      message: 'PDF comprimido.',
      data: const {},
    );
  }

  @override
  Future<FolhioAcaoResponse> mesclarPdfsLocais(List<File> files) async {
    return FolhioAcaoResponse(
      requestId: 'merge',
      success: true,
      status: 'completed',
      message: 'PDFs unidos.',
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
    numberedFile = file;
    numberPosition = position;
    numberStartAtPage = startAtPage;
    numberFirstNumber = firstNumber;
    numberFormat = format;
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
    headerFile = file;
    headerSchoolName = schoolName;
    headerDateMode = dateMode;
    headerShowStudentLine = showStudentNameLine;
    headerShowGradeLine = showGradeLine;
    headerApplyToAllPages = applyToAllPages;
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
    signatureFile = file;
    this.signatureImage = signatureImage;
    signatureXRatio = xRatio;
    signatureYRatio = yRatio;
    signatureWidthRatio = widthRatio;
    signatureApplyToAllPages = applyToAllPages;
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
    visualFile = file;
    visualQuarterTurns = quarterTurns;
    visualMirrored = mirrored;
    visualCropShape = cropShape;
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
