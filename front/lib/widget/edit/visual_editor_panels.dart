part of '../../screen/edit/edit_flows_screen.dart';

class _FaixaAjustesCompacta extends StatelessWidget {
  final String selectedTool;
  final int brightness;
  final int contrast;
  final Color markColor;
  final ValueChanged<int> onBrightnessChanged;
  final ValueChanged<int> onContrastChanged;
  final ValueChanged<Color> onMarkColorChanged;
  final VoidCallback onRotate;
  final double rotationDegrees;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback onMirror;
  final String cropShape;
  final ValueChanged<String> onCropShapeChanged;
  final VoidCallback onAddText;
  final VoidCallback onRemoveText;
  final bool canRemoveText;
  final VoidCallback onAddImage;
  final VoidCallback onRemoveImage;
  final bool canRemoveImage;
  final ValueChanged<Color> onTextColorChanged;
  final Color selectedTextColor;

  const _FaixaAjustesCompacta({
    required this.selectedTool,
    required this.brightness,
    required this.contrast,
    required this.markColor,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onMarkColorChanged,
    required this.onRotate,
    required this.rotationDegrees,
    required this.onRotationChanged,
    required this.onMirror,
    required this.cropShape,
    required this.onCropShapeChanged,
    required this.onAddText,
    required this.onRemoveText,
    required this.canRemoveText,
    required this.onAddImage,
    required this.onRemoveImage,
    required this.canRemoveImage,
    required this.onTextColorChanged,
    required this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTool == VisualEdicaoFerramenta.crop) {
      return _AjusteRecortePanel(
        rotationDegrees: rotationDegrees,
        cropShape: cropShape,
        onRotate: onRotate,
        onMirror: onMirror,
        onRotationChanged: onRotationChanged,
        onCropShapeChanged: onCropShapeChanged,
      );
    }
    if (selectedTool == VisualEdicaoFerramenta.adjustments) {
      return _MiniPanel(
        title: 'Ajustes',
        child: Row(
          children: [
            Expanded(
              child: _PercentualSlider(
                label: 'Luz',
                value: brightness,
                min: -50,
                max: 50,
                onChanged: onBrightnessChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PercentualSlider(
                label: 'Contraste',
                value: contrast,
                min: -50,
                max: 50,
                onChanged: onContrastChanged,
              ),
            ),
          ],
        ),
      );
    }
    if (selectedTool == VisualEdicaoFerramenta.text) {
      return _MiniPanel(
        title: 'Texto',
        child: Row(
          children: [
            _AcaoTextoButton(onTap: onAddText),
            const SizedBox(width: 8),
            _ExclusaoTextoButton(onTap: canRemoveText ? onRemoveText : null),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final color in const [
                      Colors.black,
                      Colors.white,
                      Color(0xFFE53935),
                      Color(0xFF21C89A),
                      Color(0xFFFFD54F),
                      Color(0xFF42A5F5),
                    ])
                      _PontoCor(
                        color: color,
                        selected: color == selectedTextColor,
                        onTap: () => onTextColorChanged(color),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (selectedTool == VisualEdicaoFerramenta.image) {
      return _MiniPanel(
        title: 'Imagem',
        child: Row(
          children: [
            _AcaoCamadaButton(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Imagem',
              onTap: onAddImage,
            ),
            const SizedBox(width: 8),
            _ExclusaoCamadaButton(onTap: canRemoveImage ? onRemoveImage : null),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Arraste a imagem e puxe as pontas para ajustar.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CoresFolhio.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (selectedTool == VisualEdicaoFerramenta.mark) {
      return _MiniPanel(
        title: 'Marcação',
        child: Row(
          children: [
            const Text(
              'Cor',
              style: TextStyle(
                color: CoresFolhio.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final color in const [
                      Color(0xFF21C89A),
                      Color(0xFFFFD54F),
                      Color(0xFFE53935),
                      Color(0xFF42A5F5),
                      Colors.white,
                      Colors.black,
                    ])
                      _PontoCor(
                        color: color,
                        selected: color == markColor,
                        onTap: () => onMarkColorChanged(color),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (selectedTool == VisualEdicaoFerramenta.removeBackground) {
      return const _MiniPanel(
        title: 'Remover fundo',
        child: Text(
          'Pronto para remover o fundo.',
          style: TextStyle(
            color: CoresFolhio.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return const SizedBox(height: 0);
  }
}
