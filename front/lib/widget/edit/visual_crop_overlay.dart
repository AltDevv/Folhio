part of '../../screen/edit/edit_flows_screen.dart';

class _SelecaoRecorteOverlay extends StatefulWidget {
  final int cropZoom;
  final String cropShape;
  final Rect? contentRect;
  final Rect? rect;
  final ValueChanged<Rect> onChanged;

  const _SelecaoRecorteOverlay({
    required this.cropZoom,
    required this.cropShape,
    required this.contentRect,
    required this.rect,
    required this.onChanged,
  });

  @override
  State<_SelecaoRecorteOverlay> createState() => _SelecaoRecorteOverlayState();
}

class _SelecaoRecorteOverlayState extends State<_SelecaoRecorteOverlay> {
  Rect? _rect;
  Rect? _moveStartRect;
  Offset? _moveStartGlobal;
  Rect? _resizeStartRect;
  Offset? _resizeStartGlobal;
  static const double _minSize = 64;
  static const double _hitSize = 34;

  @override
  void didUpdateWidget(_SelecaoRecorteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropZoom != widget.cropZoom ||
        oldWidget.cropShape != widget.cropShape) {
      _rect = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final bounds = widget.contentRect ?? (Offset.zero & size);
        final rect = (widget.rect ?? _rect ?? _inicialRetangulo(bounds)).intersect(
          bounds,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SombraRecortePainter(rect, widget.cropShape),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  _moveStartRect = rect;
                  _moveStartGlobal = details.globalPosition;
                },
                onPanUpdate: (details) =>
                    _moverDesdeInicio(details.globalPosition, bounds),
                onPanEnd: (_) => _limparInicioMovimentacao(),
                onPanCancel: _limparInicioMovimentacao,
                child: CustomPaint(
                  painter: _BordaSelecaoRecortePainter(
                    rect: Offset.zero & rect.size,
                    shape: widget.cropShape,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            _alcaBorda(
              rect.left,
              rect.center.dy,
              'left',
              bounds,
              vertical: true,
            ),
            _alcaBorda(
              rect.right,
              rect.center.dy,
              'right',
              bounds,
              vertical: true,
            ),
            _alcaBorda(rect.center.dx, rect.top, 'top', bounds),
            _alcaBorda(rect.center.dx, rect.bottom, 'bottom', bounds),
          ],
        );
      },
    );
  }

  Rect _inicialRetangulo(Rect bounds) {
    final margin = (18 + widget.cropZoom * 0.35).clamp(12.0, 80.0).toDouble();
    return Rect.fromLTRB(
      bounds.left + margin,
      bounds.top + margin,
      (bounds.right - margin).clamp(
        bounds.left + margin + _minSize,
        bounds.right,
      ),
      (bounds.bottom - margin).clamp(
        bounds.top + margin + _minSize,
        bounds.bottom,
      ),
    );
  }

  Widget _alcaBorda(
    double x,
    double y,
    String handle,
    Rect bounds, {
    bool vertical = false,
  }) {
    return Positioned(
      left: x - (vertical ? _hitSize / 2 : 26),
      top: y - (vertical ? 26 : _hitSize / 2),
      width: vertical ? _hitSize : 52,
      height: vertical ? 52 : _hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _resizeStartRect = widget.rect ?? _rect ?? _inicialRetangulo(bounds);
          _resizeStartGlobal = details.globalPosition;
        },
        onPanUpdate: (details) =>
            _redimensionarDesdeInicio(handle, details.globalPosition, bounds),
        onPanEnd: (_) => _limparInicioRedimensionamento(),
        onPanCancel: _limparInicioRedimensionamento,
        child: Center(
          child: Container(
            width: vertical ? 8 : 34,
            height: vertical ? 34 : 8,
            decoration: BoxDecoration(
              color: CoresFolhio.green,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  void _moverDesdeInicio(Offset globalPosition, Rect bounds) {
    final rect = _moveStartRect ?? widget.rect ?? _rect ?? _inicialRetangulo(bounds);
    final delta = _moveStartGlobal == null
        ? Offset.zero
        : globalPosition - _moveStartGlobal!;
    final nextLeft = (rect.left + delta.dx)
        .clamp(bounds.left, bounds.right - rect.width)
        .toDouble();
    final nextTop = (rect.top + delta.dy)
        .clamp(bounds.top, bounds.bottom - rect.height)
        .toDouble();
    final next = Rect.fromLTWH(nextLeft, nextTop, rect.width, rect.height);
    setState(() => _rect = next);
    widget.onChanged(next);
  }

  void _redimensionarDesdeInicio(String handle, Offset globalPosition, Rect bounds) {
    final rect =
        _resizeStartRect ?? widget.rect ?? _rect ?? _inicialRetangulo(bounds);
    final delta = _resizeStartGlobal == null
        ? Offset.zero
        : globalPosition - _resizeStartGlobal!;
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;

    if (handle.contains('left') || handle == 'left') left += delta.dx;
    if (handle.contains('right') || handle == 'right') right += delta.dx;
    if (handle.contains('top') || handle == 'top') top += delta.dy;
    if (handle.contains('bottom') || handle == 'bottom') bottom += delta.dy;

    left = left.clamp(bounds.left, right - _minSize).toDouble();
    right = right.clamp(left + _minSize, bounds.right).toDouble();
    top = top.clamp(bounds.top, bottom - _minSize).toDouble();
    bottom = bottom.clamp(top + _minSize, bounds.bottom).toDouble();

    final resized = Rect.fromLTRB(left, top, right, bottom);
    final next = widget.cropShape == 'basic'
        ? resized
        : _retanguloFormaFixa(handle, resized, rect, bounds);
    setState(() => _rect = next);
    widget.onChanged(next);
  }

  Rect _retanguloFormaFixa(String handle, Rect resized, Rect start, Rect bounds) {
    final maxSide = math.min(bounds.width, bounds.height);
    final minSide = math.min(_minSize, maxSide);
    final rawSide = handle == 'left' || handle == 'right'
        ? resized.width
        : handle == 'top' || handle == 'bottom'
        ? resized.height
        : math.max(resized.width, resized.height);
    final side = rawSide.clamp(minSide, maxSide).toDouble();
    double left;
    double top;

    switch (handle) {
      case 'topLeft':
        left = start.right - side;
        top = start.bottom - side;
        break;
      case 'topRight':
        left = start.left;
        top = start.bottom - side;
        break;
      case 'bottomLeft':
        left = start.right - side;
        top = start.top;
        break;
      case 'bottomRight':
        left = start.left;
        top = start.top;
        break;
      case 'left':
        left = start.right - side;
        top = start.center.dy - side / 2;
        break;
      case 'right':
        left = start.left;
        top = start.center.dy - side / 2;
        break;
      case 'top':
        left = start.center.dx - side / 2;
        top = start.bottom - side;
        break;
      case 'bottom':
        left = start.center.dx - side / 2;
        top = start.top;
        break;
      default:
        left = resized.left;
        top = resized.top;
    }

    return _ajustarRetangulo(Rect.fromLTWH(left, top, side, side), bounds);
  }

  Rect _ajustarRetangulo(Rect rect, Rect bounds) {
    final width = math.min(rect.width, bounds.width);
    final height = math.min(rect.height, bounds.height);
    final left = rect.left.clamp(bounds.left, bounds.right - width).toDouble();
    final top = rect.top.clamp(bounds.top, bounds.bottom - height).toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  void _limparInicioMovimentacao() {
    _moveStartRect = null;
    _moveStartGlobal = null;
  }

  void _limparInicioRedimensionamento() {
    _resizeStartRect = null;
    _resizeStartGlobal = null;
  }
}

class _SombraRecortePainter extends CustomPainter {
  final Rect rect;
  final String shape;

  const _SombraRecortePainter(this.rect, this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = const Color(0x33000000);
    final outer = Path()..addRect(Offset.zero & size);
    final inner = _caminhoRecortePorForma(shape, rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      shade,
    );
  }

  @override
  bool shouldRepaint(_SombraRecortePainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.shape != shape;
}

class _RecorteAplicadoPainter extends CustomPainter {
  final Rect rect;
  final String shape;

  const _RecorteAplicadoPainter(this.rect, this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = const Color(0x22000000);
    final outer = Path()..addRect(Offset.zero & size);
    final inner = _caminhoRecortePorForma(shape, rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      shade,
    );

    final border = Paint()
      ..color = const Color(0xAA21C89A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_caminhoRecortePorForma(shape, rect), border);
  }

  @override
  bool shouldRepaint(_RecorteAplicadoPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.shape != shape;
}

class _BordaSelecaoRecortePainter extends CustomPainter {
  final Rect rect;
  final String shape;

  const _BordaSelecaoRecortePainter({required this.rect, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0x1021C89A)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = CoresFolhio.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = _caminhoRecortePorForma(shape, rect);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_BordaSelecaoRecortePainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.shape != shape;
  }
}
