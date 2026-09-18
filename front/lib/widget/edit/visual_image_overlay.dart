part of '../../screen/edit/edit_flows_screen.dart';

class _ImagemEditavelOverlay extends StatefulWidget {
  final List<CamadaImagemVisual> layers;
  final int? selectedIndex;
  final bool editable;
  final Rect? contentRect;
  final ValueChanged<int> onSelect;
  final void Function(int index, CamadaImagemVisual layer) onUpdate;

  const _ImagemEditavelOverlay({
    required this.layers,
    required this.selectedIndex,
    required this.editable,
    required this.contentRect,
    required this.onSelect,
    required this.onUpdate,
  });

  @override
  State<_ImagemEditavelOverlay> createState() => _ImagemEditavelOverlayState();
}

class _ImagemEditavelOverlayState extends State<_ImagemEditavelOverlay> {
  Rect? _moveStartRect;
  Offset? _moveStartGlobal;
  Rect? _resizeStartRect;
  Offset? _resizeStartGlobal;

  static const double _hitSize = 34;
  static const double _minSize = 42;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final bounds = Offset.zero & size;
        final initialBounds = widget.contentRect ?? bounds;
        return Stack(
          children: [
            for (var index = 0; index < widget.layers.length; index++)
              ..._widgetsCamadas(
                index,
                widget.layers[index],
                bounds,
                initialBounds,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _widgetsCamadas(
    int index,
    CamadaImagemVisual layer,
    Rect bounds,
    Rect initialBounds,
  ) {
    final rect = layer.rect ?? _inicialRetangulo(initialBounds, index);
    final selected = widget.selectedIndex == index;
    return [
      Positioned.fromRect(
        rect: rect,
        child: IgnorePointer(
          ignoring: !widget.editable,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => widget.onSelect(index),
            onPanStart: (details) {
              widget.onSelect(index);
              _moveStartRect = rect;
              _moveStartGlobal = details.globalPosition;
            },
            onPanUpdate: (details) =>
                _moverDesdeInicio(index, layer, details.globalPosition, bounds),
            onPanEnd: (_) => _limparInicioMovimentacao(),
            onPanCancel: _limparInicioMovimentacao,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: selected && widget.editable
                    ? Border.all(color: CoresFolhio.green, width: 1.8)
                    : null,
                color: selected && widget.editable
                    ? const Color(0x12FFFFFF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: selected && widget.editable
                    ? const EdgeInsets.all(2)
                    : EdgeInsets.zero,
                child: Image.file(
                  layer.file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: CoresFolhio.dim,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (selected && widget.editable) ...[
        _tratar(index, layer, rect.left, rect.top, 'topLeft', bounds),
        _tratar(index, layer, rect.right, rect.top, 'topRight', bounds),
        _tratar(index, layer, rect.left, rect.bottom, 'bottomLeft', bounds),
        _tratar(index, layer, rect.right, rect.bottom, 'bottomRight', bounds),
        _alcaBorda(
          index,
          layer,
          rect.left,
          rect.center.dy,
          'left',
          bounds,
          vertical: true,
        ),
        _alcaBorda(
          index,
          layer,
          rect.right,
          rect.center.dy,
          'right',
          bounds,
          vertical: true,
        ),
        _alcaBorda(index, layer, rect.center.dx, rect.top, 'top', bounds),
        _alcaBorda(
          index,
          layer,
          rect.center.dx,
          rect.bottom,
          'bottom',
          bounds,
        ),
      ],
    ];
  }

  Rect _inicialRetangulo(Rect bounds, int index) {
    final width = (bounds.width * 0.24)
        .clamp(_minSize, bounds.width)
        .toDouble();
    final height = (bounds.height * 0.18)
        .clamp(_minSize, bounds.height)
        .toDouble();
    final offset = (index * 14).clamp(0, 70).toDouble();
    final left = (bounds.left + ((bounds.width - width) / 2) + offset)
        .clamp(bounds.left, bounds.right - width)
        .toDouble();
    final top = (bounds.top + ((bounds.height - height) / 2) + offset)
        .clamp(bounds.top, bounds.bottom - height)
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Widget _tratar(
    int index,
    CamadaImagemVisual layer,
    double x,
    double y,
    String handle,
    Rect bounds,
  ) {
    return Positioned(
      left: x - _hitSize / 2,
      top: y - _hitSize / 2,
      width: _hitSize,
      height: _hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _resizeStartRect = layer.rect ?? _inicialRetangulo(bounds, index);
          _resizeStartGlobal = details.globalPosition;
        },
        onPanUpdate: (details) => _redimensionarDesdeInicio(
          index,
          layer,
          handle,
          details.globalPosition,
          bounds,
        ),
        onPanEnd: (_) => _limparInicioRedimensionamento(),
        onPanCancel: _limparInicioRedimensionamento,
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: CoresFolhio.green,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alcaBorda(
    int index,
    CamadaImagemVisual layer,
    double x,
    double y,
    String handle,
    Rect bounds, {
    bool vertical = false,
  }) {
    return Positioned(
      left: x - (vertical ? _hitSize / 2 : 24),
      top: y - (vertical ? 24 : _hitSize / 2),
      width: vertical ? _hitSize : 48,
      height: vertical ? 48 : _hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _resizeStartRect = layer.rect ?? _inicialRetangulo(bounds, index);
          _resizeStartGlobal = details.globalPosition;
        },
        onPanUpdate: (details) => _redimensionarDesdeInicio(
          index,
          layer,
          handle,
          details.globalPosition,
          bounds,
        ),
        onPanEnd: (_) => _limparInicioRedimensionamento(),
        onPanCancel: _limparInicioRedimensionamento,
        child: Center(
          child: Container(
            width: vertical ? 8 : 30,
            height: vertical ? 30 : 8,
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

  void _moverDesdeInicio(
    int index,
    CamadaImagemVisual layer,
    Offset globalPosition,
    Rect bounds,
  ) {
    final rect = _moveStartRect ?? layer.rect ?? _inicialRetangulo(bounds, index);
    final delta = _moveStartGlobal == null
        ? Offset.zero
        : globalPosition - _moveStartGlobal!;
    final nextLeft = (rect.left + delta.dx)
        .clamp(bounds.left, bounds.right - rect.width)
        .toDouble();
    final nextTop = (rect.top + delta.dy)
        .clamp(bounds.top, bounds.bottom - rect.height)
        .toDouble();
    widget.onUpdate(
      index,
      layer.copiarCom(
        rect: Rect.fromLTWH(nextLeft, nextTop, rect.width, rect.height),
      ),
    );
  }

  void _redimensionarDesdeInicio(
    int index,
    CamadaImagemVisual layer,
    String handle,
    Offset globalPosition,
    Rect bounds,
  ) {
    final rect = _resizeStartRect ?? layer.rect ?? _inicialRetangulo(bounds, index);
    final delta = _resizeStartGlobal == null
        ? Offset.zero
        : globalPosition - _resizeStartGlobal!;
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;

    if (handle.contains('left')) left += delta.dx;
    if (handle.contains('right')) right += delta.dx;
    if (handle.contains('top')) top += delta.dy;
    if (handle.contains('bottom')) bottom += delta.dy;

    left = left.clamp(bounds.left, right - _minSize).toDouble();
    right = right.clamp(left + _minSize, bounds.right).toDouble();
    top = top.clamp(bounds.top, bottom - _minSize).toDouble();
    bottom = bottom.clamp(top + _minSize, bounds.bottom).toDouble();

    widget.onUpdate(
      index,
      layer.copiarCom(rect: Rect.fromLTRB(left, top, right, bottom)),
    );
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
