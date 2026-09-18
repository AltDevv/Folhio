part of '../../screen/edit/edit_flows_screen.dart';

class _ArquivoVisualCanvas extends StatelessWidget {
  final File? file;
  final String selectedTool;
  final int quarterTurns;
  final double rotationDegrees;
  final int cropZoom;
  final String cropShape;
  final bool mirrored;
  final int brightness;
  final int contrast;
  final List<CamadaTextoVisual> textLayers;
  final int? selectedTextIndex;
  final ValueChanged<int> onSelectTextLayer;
  final void Function(int index, CamadaTextoVisual layer) onUpdateTextLayer;
  final List<CamadaImagemVisual> imageLayers;
  final int? selectedImageIndex;
  final ValueChanged<int> onSelectImageLayer;
  final void Function(int index, CamadaImagemVisual layer) onUpdateImageLayer;
  final ValueChanged<Size> onCanvasSizeChanged;
  final Rect? contentRect;
  final Rect? cropRect;
  final Rect? draftCropRect;
  final ValueChanged<Rect> onCropRectChanged;
  final List<TracoMarcacaoVisual> markStrokes;
  final ValueChanged<List<TracoMarcacaoVisual>> onMarkStrokesChanged;
  final Color markColor;
  final bool processing;
  final bool isImage;
  final VoidCallback onSelectFile;
  final VoidCallback onDeselectTextLayer;

  const _ArquivoVisualCanvas({
    required this.file,
    required this.selectedTool,
    required this.quarterTurns,
    required this.rotationDegrees,
    required this.cropZoom,
    required this.cropShape,
    required this.mirrored,
    required this.brightness,
    required this.contrast,
    required this.textLayers,
    required this.selectedTextIndex,
    required this.onSelectTextLayer,
    required this.onUpdateTextLayer,
    required this.imageLayers,
    required this.selectedImageIndex,
    required this.onSelectImageLayer,
    required this.onUpdateImageLayer,
    required this.onCanvasSizeChanged,
    required this.contentRect,
    required this.cropRect,
    required this.draftCropRect,
    required this.onCropRectChanged,
    required this.markStrokes,
    required this.onMarkStrokesChanged,
    required this.markColor,
    required this.processing,
    required this.isImage,
    required this.onSelectFile,
    required this.onDeselectTextLayer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: file == null && !processing ? onSelectFile : onDeselectTextLayer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fallbackHeight = (constraints.maxWidth * 1.42)
              .clamp(400.0, 720.0)
              .toDouble();
          final canvasHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : fallbackHeight;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCanvasSizeChanged(Size(constraints.maxWidth, canvasHeight));
          });
          return SizedBox(
            height: canvasHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: colors.background),
                      child: _conteudoPrevia(context),
                    ),
                  ),
                ),
                if (processing)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x88000000),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CoresFolhio.green,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _conteudoPrevia(BuildContext context) {
    if (file == null) {
      final colors = context.folhioColors;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_to_photos_outlined, color: colors.dim, size: 54),
            const SizedBox(height: 12),
            Text(
              'Toque aqui para escolher o arquivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Imagem, Word ou PDF',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (!isImage) {
      return _previaEditavel(
        _PaginaDocumentoPreview(
          fileName: file!.uri.pathSegments.isEmpty
              ? 'Documento'
              : file!.uri.pathSegments.last,
          convertedFromPdf:
              file!.uri.pathSegments.isNotEmpty &&
              file!.uri.pathSegments.last.toLowerCase().endsWith('.pdf'),
        ),
      );
    }

    return _previaEditavel(
      Image.file(
        file!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            _mensagemErro('Não foi possível abrir a imagem'),
      ),
    );
  }

  Widget _previaEditavel(Widget image) {
    final zoom = 1 + (cropZoom / 100);
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: Center(
              child: Transform.scale(
                scaleX: mirrored ? -zoom : zoom,
                scaleY: zoom,
                child: RotatedBox(
                  quarterTurns: quarterTurns,
                  child: Transform.rotate(
                    angle: rotationDegrees * math.pi / 180,
                    child: ColorFiltered(
                      colorFilter: _corFilter(),
                      child: image,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (imageLayers.isNotEmpty)
          Positioned.fill(
            child: _ImagemEditavelOverlay(
              layers: imageLayers,
              selectedIndex: selectedImageIndex,
              editable: selectedTool == VisualEdicaoFerramenta.image,
              contentRect: contentRect,
              onSelect: onSelectImageLayer,
              onUpdate: onUpdateImageLayer,
            ),
          ),
        if (textLayers.isNotEmpty)
          Positioned.fill(
            child: _TextoEditavelOverlay(
              layers: textLayers,
              selectedIndex: selectedTextIndex,
              editable: selectedTool == VisualEdicaoFerramenta.text,
              onSelect: onSelectTextLayer,
              onDeselect: onDeselectTextLayer,
              onUpdate: onUpdateTextLayer,
            ),
          ),
        if (cropRect != null && selectedTool != VisualEdicaoFerramenta.crop)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RecorteAplicadoPainter(cropRect!, cropShape),
              ),
            ),
          ),
        if (selectedTool == VisualEdicaoFerramenta.crop)
          Positioned.fill(
            child: _SelecaoRecorteOverlay(
              cropZoom: cropZoom,
              cropShape: cropShape,
              contentRect: contentRect,
              rect: draftCropRect ?? cropRect,
              onChanged: onCropRectChanged,
            ),
          ),
        if (markStrokes.isNotEmpty || selectedTool == VisualEdicaoFerramenta.mark)
          Positioned.fill(
            child: _MarcacaoOverlay(
              strokes: markStrokes,
              editable: selectedTool == VisualEdicaoFerramenta.mark,
              color: markColor,
              onChanged: onMarkStrokesChanged,
            ),
          ),
      ],
    );
  }

  Widget _mensagemErro(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF777D78),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  ColorFilter _corFilter() {
    final b = brightness / 100;
    final c = 1 + (contrast / 100);
    return ColorFilter.matrix([
      c,
      0,
      0,
      0,
      b * 255,
      0,
      c,
      0,
      0,
      b * 255,
      0,
      0,
      c,
      0,
      b * 255,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}
