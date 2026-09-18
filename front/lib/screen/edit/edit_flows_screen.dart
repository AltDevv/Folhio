import 'dart:async';
import 'dart:io';

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../model/edit/visual_edit_models.dart';
import '../../controller/edit/compactacao_pdf_view_model.dart';
import '../../controller/edit/recorte_paginas_view_model.dart';
import '../../controller/edit/cabecalho_pdf_view_model.dart';
import '../../controller/edit/mesclagem_pdf_view_model.dart';
import '../../controller/edit/numeracao_paginas_view_model.dart';
import '../../controller/edit/assinatura_pdf_view_model.dart';
import '../../controller/edit/edicao_visual_view_model.dart';
import '../../widget/actions.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../../widget/previews.dart';

part '../../widget/edit/visual_editor_controls.dart';
part '../../widget/edit/visual_canvas_widget.dart';
part '../../widget/edit/visual_text_overlay.dart';
part '../../widget/edit/visual_image_overlay.dart';
part '../../widget/edit/visual_mark_overlay.dart';
part '../../widget/edit/visual_crop_overlay.dart';
part '../../widget/edit/visual_editor_panels.dart';
part '../../widget/edit/visual_panel_controls.dart';
part '../../widget/edit/visual_crop_controls.dart';
part 'pdf_tool_screens.dart';
part 'recorte_paginas_screen.dart';
part 'mesclagem_pdf_screen.dart';
part 'compactacao_pdf_screen.dart';
part 'cabecalho_pdf_screen.dart';
part 'numeracao_paginas_screen.dart';
part 'assinatura_pdf_screen.dart';
part '../../widget/edit/pdf_tool_widgets.dart';
part 'visual_editor_actions.dart';
part 'visual_layer_actions.dart';
part 'visual_export_actions.dart';

Future<File?> _escolherArquivoPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  final path = result?.files.single.path;
  return path == null ? null : File(path);
}

Future<File?> _escolherArquivoEdicaoVisual() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'doc', 'docx'],
  );
  final path = result?.files.single.path;
  return path == null ? null : File(path);
}

Future<File?> _escolherArquivoImagemSobreposta() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg'],
  );
  final path = result?.files.single.path;
  return path == null ? null : File(path);
}

Path _caminhoFormaRecorte(String shape, Rect rect) {
  if (shape == 'triangle') {
    return Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }
  if (shape == 'hexagon') {
    return Path()
      ..moveTo(rect.left + rect.width * 0.25, rect.top)
      ..lineTo(rect.left + rect.width * 0.75, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.left + rect.width * 0.75, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.25, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
  }
  return Path()..addRect(rect);
}

Path _caminhoRecortePorForma(String shape, Rect rect) {
  if (shape == 'circle') {
    return Path()..addOval(rect);
  }
  return _caminhoFormaRecorte(shape, rect);
}

void _mostrarResultadoEdicao(BuildContext context, String message, String? fileName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(fileName == null ? message : '$message Arquivo: $fileName'),
    ),
  );
}

class EdicaoImagemScreen extends StatefulWidget {
  final bool showBack;
  final File? initialFile;

  const EdicaoImagemScreen({super.key, this.showBack = true, this.initialFile});

  @override
  State<EdicaoImagemScreen> createState() => _EdicaoImagemScreenState();
}

class _EdicaoImagemScreenState extends State<EdicaoImagemScreen> {
  final _viewModel = EdicaoVisualViewModel();
  final _session = VisualEdicaoSessao();
  File? _selectedFile;
  File? _editableWordFile;
  bool _toolsOpen = true;
  Size? _canvasSize;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
    if (_selectedFile != null) {
      unawaited(_prepararArquivoInicial(_selectedFile!));
    }
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
  }

  Future<void> _prepararArquivoInicial(File file) async {
    try {
      if (_ehImagem(file)) {
        final size = await _lerTamanhoImagem(file);
        if (!mounted) return;
        _renovar(() => _imageSize = size);
      } else {
        if (_ehPdf(file)) {
          await _converterPdfParaWord(file);
        } else if (_ehWord(file)) {
          _editableWordFile = file;
        }
        if (!mounted) return;
        _renovar(() {
          _imageSize = const Size(794, 1123);
          _prepararCamadasDocumento();
        });
      }
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'NÃ£o foi possÃ­vel preparar o arquivo. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  void _renovar(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_aoVisualizacaoModeloAlterado)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Editor',
      currentIndex: 1,
      showBack: widget.showBack,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: Column(
          children: [
            Expanded(
              child: _ArquivoVisualCanvas(
                file: _selectedFile,
                selectedTool: _session.selectedTool,
                quarterTurns: _session.quarterTurns,
                rotationDegrees: _session.rotationDegrees,
                cropZoom: _session.cropZoom,
                cropShape: _session.cropShape,
                mirrored: _session.mirrored,
                brightness: _session.brightness,
                contrast: _session.contrast,
                textLayers: _session.textLayers,
                selectedTextIndex: _session.selectedTextIndex,
                onSelectTextLayer: _selecionarCamadaTexto,
                onUpdateTextLayer: _atualizarCamadaTexto,
                imageLayers: _session.imageLayers,
                selectedImageIndex: _session.selectedImageIndex,
                onSelectImageLayer: _selecionarCamadaImagem,
                onUpdateImageLayer: _atualizarCamadaImagem,
                onCanvasSizeChanged: _atualizarTamanhoTela,
                contentRect: _retanguloConteudoImagem(),
                cropRect: _retanguloRecorteDaProporcao(_session.cropRatio),
                draftCropRect: _session.draftCropRect,
                onCropRectChanged: (rect) =>
                    setState(() => _session.draftCropRect = rect),
                markStrokes: _session.markStrokes,
                onMarkStrokesChanged: (strokes) => setState(() {
                  _session.markStrokes
                    ..clear()
                    ..addAll(strokes);
                }),
                markColor: _session.markColor,
                processing: _viewModel.processing,
                isImage: _selectedFile == null
                    ? false
                    : _ehImagem(_selectedFile!),
                onSelectFile: _selecionarArquivo,
                onDeselectTextLayer: _desmarcarCamadaTexto,
              ),
            ),
            if (_session.selectedTool.isNotEmpty) ...[
              const SizedBox(height: 6),
              _FaixaAjustesCompacta(
                selectedTool: _session.selectedTool,
                brightness: _session.brightness,
                contrast: _session.contrast,
                markColor: _session.markColor,
                onBrightnessChanged: (value) =>
                    setState(() => _session.brightness = value),
                onContrastChanged: (value) =>
                    setState(() => _session.contrast = value),
                onMarkColorChanged: (value) =>
                    setState(() => _session.markColor = value),
                onRotate: _girarDireita,
                rotationDegrees: _session.rotationDegrees,
                onRotationChanged: _definirGrausRotacao,
                onMirror: _alternarEspelhamento,
                cropShape: _session.cropShape,
                onCropShapeChanged: _definirFormaRecorte,
                onAddText: () => setState(() {
                  _session.selectedTool = VisualEdicaoFerramenta.text;
                  _adicionarCamadaTexto();
                }),
                onTextColorChanged: _alterarCorTextoSelecionado,
                onRemoveText: _removerCamadaTextoSelecionada,
                canRemoveText:
                    _session.selectedTextIndex != null &&
                    _session.textLayers.isNotEmpty,
                onAddImage: _escolherCamadaImagem,
                onRemoveImage: _removerCamadaImagemSelecionada,
                canRemoveImage:
                    _session.selectedImageIndex != null &&
                    _session.imageLayers.isNotEmpty,
                selectedTextColor: _corTextoSelecionado(),
              ),
            ],
            const SizedBox(height: 4),
            _EdicaoVisualToolbar(
              selectedTool: _session.selectedTool,
              removeBackgroundActive: _session.removeBackground,
              hasFile: _selectedFile != null,
              open: _toolsOpen,
              onToggleOpen: () => setState(() => _toolsOpen = !_toolsOpen),
              onToolSelected: _escolherFerramenta,
              onReset: _redefinir,
            ),
            const SizedBox(height: 8),
            if (_session.selectedTool == VisualEdicaoFerramenta.crop)
              _FaixaAcoesRecorte(onCancel: _cancelarRecorte, onConfirm: _confirmarRecorte)
            else if (_selectedFile != null)
              _FaixaAcoesEditor(
                processing: _viewModel.processing,
                onCancel: _limparArquivoSelecionado,
                onConfirm: _exportarEdicaoVisual,
              ),
          ],
        ),
      ),
    );
  }
}
