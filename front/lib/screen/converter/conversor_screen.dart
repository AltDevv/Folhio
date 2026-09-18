import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../controller/converter/conversor_controller.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../widget/actions.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';

part '../../widget/converter/converter_widgets.dart';

class ConversorScreen extends StatefulWidget {
  const ConversorScreen({super.key});

  @override
  State<ConversorScreen> createState() => _ConversorScreenState();
}

class _ConversorScreenState extends State<ConversorScreen> {
  static const _flows = [
    _FluxoConversao(
      key: 'pdf_image',
      title: 'Converter para imagem',
      detail: 'PNG/JPG',
      sourceExtensions: ['pdf'],
      targetFormat: 'png',
      icon: Icons.image_outlined,
      color: CoresFolhio.blue,
    ),
    _FluxoConversao(
      key: 'image_pdf',
      title: 'Converter para PDF',
      detail: 'Juntar imagem em PDF',
      sourceExtensions: ['png', 'jpg', 'jpeg'],
      targetFormat: 'pdf',
      icon: Icons.picture_as_pdf_outlined,
      color: CoresFolhio.coral,
    ),
    _FluxoConversao(
      key: 'word_pdf',
      title: 'Converter para PDF',
      detail: 'Documento Word',
      sourceExtensions: ['doc', 'docx'],
      targetFormat: 'pdf',
      icon: Icons.description_outlined,
      color: CoresFolhio.green,
    ),
    _FluxoConversao(
      key: 'ppt_pdf',
      title: 'Converter para PDF',
      detail: 'Apresentação',
      sourceExtensions: ['ppt', 'pptx'],
      targetFormat: 'pdf',
      icon: Icons.slideshow_outlined,
      color: CoresFolhio.orange,
    ),
    _FluxoConversao(
      key: 'excel_pdf',
      title: 'Converter para PDF',
      detail: 'Planilha',
      sourceExtensions: ['xls', 'xlsx'],
      targetFormat: 'pdf',
      icon: Icons.table_chart_outlined,
      color: CoresFolhio.green,
    ),
    _FluxoConversao(
      key: 'image_word',
      title: 'Converter para Word',
      detail: 'OCR beta',
      sourceExtensions: ['png', 'jpg', 'jpeg'],
      targetFormat: 'docx',
      icon: Icons.document_scanner_outlined,
      color: CoresFolhio.violet,
      beta: true,
    ),
    _FluxoConversao(
      key: 'pdf_word',
      title: 'Converter para Word',
      detail: 'OCR beta',
      sourceExtensions: ['pdf'],
      targetFormat: 'docx',
      icon: Icons.edit_document,
      color: CoresFolhio.violet,
      beta: true,
    ),
  ];

  File? _selectedFile;
  String? _selectedFileName;
  int _imageFormatIndex = 0;
  String? _processingKey;
  bool _showAllQuickConversions = false;

  List<String> get _acceptedExtensions {
    final extensions = <String>{};
    for (final flow in _flows) {
      extensions.addAll(flow.sourceExtensions);
    }
    return extensions.toList()..sort();
  }

  String get _selectedExtension {
    final name = _selectedFileName;
    if (name == null) return '';
    return _extensaoDe(name);
  }

  List<_FluxoConversao> get _availableFlows {
    final extension = _selectedExtension;
    if (extension.isEmpty) return const [];
    return _flows
        .where((flow) => flow.sourceExtensions.contains(extension))
        .toList();
  }

  List<_FluxoConversao> get _quickFlows {
    final preferred = [
      'pdf_word',
      'word_pdf',
      'image_pdf',
      'pdf_image',
      'ppt_pdf',
      'excel_pdf',
    ];
    final ordered = [
      for (final key in preferred) _flows.firstWhere((flow) => flow.key == key),
    ];
    if (!_showAllQuickConversions) {
      return ordered;
    }
    final visibleKeys = ordered.map((flow) => flow.key).toSet();
    return [
      ...ordered,
      ..._flows.where((flow) => !visibleKeys.contains(flow.key)),
    ];
  }

  Future<void> _escolherArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _acceptedExtensions,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _selectedFile = File(path);
      _selectedFileName = result!.files.single.name;
      _processingKey = null;
    });
  }

  Future<void> _escolherEConverter(_FluxoConversao flow) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: flow.sourceExtensions,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _selectedFile = File(path);
      _selectedFileName = result!.files.single.name;
      _processingKey = null;
    });
    await _converter(flow);
  }

  Future<void> _converter(_FluxoConversao flow) async {
    final file = _selectedFile;
    final fileName = _selectedFileName;
    if (file == null || fileName == null) {
      await _escolherArquivo();
      return;
    }

    if (!flow.sourceExtensions.contains(_extensaoDe(fileName))) {
      _mostrarMensagem('Essa conversão não combina com o arquivo selecionado.');
      return;
    }

    setState(() => _processingKey = flow.key);
    try {
      final controller = ConversorController(FolhioApiGateway());
      final response = await controller.converterDocumentoLocal(
        file: file,
        sourceMimeType: _inferirTipoMime(fileName),
        targetFormat: _formatoDestinoPara(flow),
        orientation: 'portrait',
      );

      if (!mounted) return;
      final output = response.outputFile;
      _mostrarMensagem(
        output == null
            ? response.message
            : '${response.message} Arquivo: ${output.fileName}',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        'Não foi possível converter o arquivo. ${FolhioApiGateway.humanizarErro(error)}',
      );
    } finally {
      if (mounted) setState(() => _processingKey = null);
    }
  }

  String _formatoDestinoPara(_FluxoConversao flow) {
    if (flow.key == 'pdf_image') {
      return _imageFormatIndex == 0 ? 'png' : 'jpg';
    }
    return flow.targetFormat;
  }

  void _limparArquivo() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _processingKey = null;
      _imageFormatIndex = 0;
    });
  }

  void _mostrarMensagem(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _extensaoDe(String name) {
    final cleanName = name.toLowerCase().split('?').first;
    final dotIndex = cleanName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == cleanName.length - 1) return '';
    return cleanName.substring(dotIndex + 1);
  }

  String _inferirTipoMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFile != null;
    final availableFlows = _availableFlows;

    return FolhioScaffold(
      title: 'Converter',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          _ArquivoOrigemPanel(
            fileName: _selectedFileName,
            extension: _selectedExtension,
            busy: _processingKey != null,
            onPick: _escolherArquivo,
            onClear: hasFile ? _limparArquivo : null,
          ),
          if (!hasFile) ...[
            const SizedBox(height: 18),
            const _DicaConversaoVazia(),
            const SizedBox(height: 14),
            const TituloSecao('Conversões rápidas'),
            _GradeConversoesRapidas(
              flows: _quickFlows,
              busy: _processingKey != null,
              onSelected: _escolherEConverter,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(
                    () => _showAllQuickConversions = !_showAllQuickConversions,
                  );
                },
                icon: Icon(
                  _showAllQuickConversions
                      ? Icons.expand_less
                      : Icons.expand_more,
                ),
                label: Text(
                  _showAllQuickConversions
                      ? 'Mostrar menos'
                      : 'Ver todas as conversões',
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const TituloSecao('Opções disponíveis'),
            if (availableFlows.isEmpty)
              const _SemAcoesCard()
            else
              for (final flow in availableFlows) ...[
                _LinhaAcoesConversao(
                  flow: flow,
                  processing: _processingKey == flow.key,
                  disabled:
                      _processingKey != null && _processingKey != flow.key,
                  imageFormatIndex: _imageFormatIndex,
                  onImageFormatChanged: (index) {
                    setState(() => _imageFormatIndex = index);
                  },
                  onConvert: () => _converter(flow),
                ),
                const SizedBox(height: 9),
              ],
          ],
        ],
      ),
    );
  }
}
