part of '../../screen/edit/edit_flows_screen.dart';

class _MarcacaoOverlay extends StatelessWidget {
  final List<TracoMarcacaoVisual> strokes;
  final bool editable;
  final Color color;
  final ValueChanged<List<TracoMarcacaoVisual>> onChanged;

  const _MarcacaoOverlay({
    required this.strokes,
    required this.editable,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !editable,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          final next = strokes.map((stroke) => stroke.copiarCom()).toList();
          next.add(
            TracoMarcacaoVisual(points: [details.localPosition], color: color),
          );
          onChanged(next);
        },
        onPanUpdate: (details) {
          if (strokes.isEmpty) return;
          final next = strokes.map((stroke) => stroke.copiarCom()).toList();
          next.last = next.last.copiarCom(
            points: [...next.last.points, details.localPosition],
          );
          onChanged(next);
        },
        child: CustomPaint(
          painter: _MarcacaoPainter(strokes),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _MarcacaoPainter extends CustomPainter {
  final List<TracoMarcacaoVisual> strokes;

  const _MarcacaoPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: 0.82)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < stroke.points.length; i++) {
        canvas.drawLine(stroke.points[i - 1], stroke.points[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MarcacaoPainter oldDelegate) => true;
}
