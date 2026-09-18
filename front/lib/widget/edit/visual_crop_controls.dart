part of '../../screen/edit/edit_flows_screen.dart';

class _AjusteRecortePanel extends StatelessWidget {
  final double rotationDegrees;
  final String cropShape;
  final VoidCallback onRotate;
  final VoidCallback onMirror;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<String> onCropShapeChanged;

  const _AjusteRecortePanel({
    required this.rotationDegrees,
    required this.cropShape,
    required this.onRotate,
    required this.onMirror,
    required this.onRotationChanged,
    required this.onCropShapeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF10221D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF23352F)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _AcaoCompactaIconeButton(
                icon: Icons.rotate_right,
                label: 'Girar',
                onTap: onRotate,
              ),
              const SizedBox(width: 6),
              _AcaoCompactaIconeButton(
                icon: Icons.flip,
                label: 'Espelhar',
                onTap: onMirror,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RotacaoSlider(
                  value: rotationDegrees,
                  onChanged: onRotationChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Forma',
                style: TextStyle(
                  color: CoresFolhio.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FormaRecorteButton(
                      shape: 'basic',
                      label: 'Básico',
                      selected: cropShape == 'basic',
                      onTap: () => onCropShapeChanged('basic'),
                    ),
                    _FormaRecorteButton(
                      shape: 'square',
                      label: 'Quadrado',
                      selected: cropShape == 'square',
                      onTap: () => onCropShapeChanged('square'),
                    ),
                    _FormaRecorteButton(
                      shape: 'triangle',
                      label: 'Triângulo',
                      selected: cropShape == 'triangle',
                      onTap: () => onCropShapeChanged('triangle'),
                    ),
                    _FormaRecorteButton(
                      shape: 'circle',
                      label: 'Círculo',
                      selected: cropShape == 'circle',
                      onTap: () => onCropShapeChanged('circle'),
                    ),
                    _FormaRecorteButton(
                      shape: 'hexagon',
                      label: 'Hexágono',
                      selected: cropShape == 'hexagon',
                      onTap: () => onCropShapeChanged('hexagon'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcaoCompactaIconeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AcaoCompactaIconeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        width: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF143A31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoresFolhio.green),
        ),
        child: Tooltip(
          message: label,
          child: Icon(icon, color: CoresFolhio.green, size: 18),
        ),
      ),
    );
  }
}

class _FormaRecorteButton extends StatelessWidget {
  final String shape;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormaRecorteButton({
    required this.shape,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: Container(
            height: 34,
            width: 38,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF143A31)
                  : CoresFolhio.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? CoresFolhio.green : CoresFolhio.borderSoft,
              ),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(20, 20),
                painter: _IconeFormaRecortePainter(
                  shape: shape,
                  color: selected ? CoresFolhio.green : CoresFolhio.cream,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconeFormaRecortePainter extends CustomPainter {
  final String shape;
  final Color color;

  const _IconeFormaRecortePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rect = Offset.zero & size;
    if (shape == 'basic') {
      canvas.drawLine(
        Offset(size.width * 0.22, size.height * 0.12),
        Offset(size.width * 0.22, size.height * 0.78),
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.22, size.height * 0.78),
        Offset(size.width * 0.88, size.height * 0.78),
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.12, size.height * 0.22),
        Offset(size.width * 0.78, size.height * 0.22),
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.78, size.height * 0.22),
        Offset(size.width * 0.78, size.height * 0.88),
        stroke,
      );
      return;
    }
    if (shape == 'circle') {
      canvas.drawOval(rect.deflate(2), stroke);
      return;
    }
    final path = _caminhoFormaRecorte(shape, rect.deflate(2));
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_IconeFormaRecortePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}
