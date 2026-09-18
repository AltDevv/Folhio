part of '../../screen/edit/edit_flows_screen.dart';

class _TextoEditavelOverlay extends StatefulWidget {
  final List<CamadaTextoVisual> layers;
  final int? selectedIndex;
  final bool editable;
  final ValueChanged<int> onSelect;
  final VoidCallback onDeselect;
  final void Function(int index, CamadaTextoVisual layer) onUpdate;

  const _TextoEditavelOverlay({
    required this.layers,
    required this.selectedIndex,
    required this.editable,
    required this.onSelect,
    required this.onDeselect,
    required this.onUpdate,
  });

  @override
  State<_TextoEditavelOverlay> createState() => _TextoEditavelOverlayState();
}

class _TextoEditavelOverlayState extends State<_TextoEditavelOverlay> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  Rect? _dragStartRect;
  Offset? _dragStartGlobal;
  Rect? _resizeStartRect;
  Offset? _resizeStartGlobal;

  static const double _hitSize = 34;
  static const double _minWidth = 38;
  static const double _minHeight = 38;

  @override
  void didUpdateWidget(covariant _TextoEditavelOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeIndexes = {
      for (var index = 0; index < widget.layers.length; index++) index,
    };
    for (final index
        in _controllers.keys
            .where((index) => !activeIndexes.contains(index))
            .toList()) {
      _controllers.remove(index)?.dispose();
      _focusNodes.remove(index)?.dispose();
    }
    for (var index = 0; index < widget.layers.length; index++) {
      final controller = _controllers[index];
      final focusNode = _focusNodes[index];
      final text = _exibirTexto(widget.layers[index].text);
      if (controller != null &&
          focusNode?.hasFocus != true &&
          controller.text != text) {
        controller.text = text;
      }
    }
    if (!widget.editable || widget.selectedIndex == null) {
      for (final focusNode in _focusNodes.values) {
        focusNode.unfocus();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onDeselect,
              ),
            ),
            for (var index = 0; index < widget.layers.length; index++)
              ..._widgetsCamadas(context, index, widget.layers[index], size),
          ],
        );
      },
    );
  }

  List<Widget> _widgetsCamadas(
    BuildContext context,
    int index,
    CamadaTextoVisual layer,
    Size size,
  ) {
    final rect = layer.rect ?? _inicialRetangulo(size, index);
    final selected = widget.selectedIndex == index;
    final isEditing = selected && widget.editable;
    return [
      Positioned.fromRect(
        rect: rect,
        child: IgnorePointer(
          ignoring: !widget.editable,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              widget.onSelect(index);
              if (layer.rect == null) {
                widget.onUpdate(index, layer.copiarCom(rect: rect));
              }
              _focusNodes[index]?.requestFocus();
            },
            onPanStart: (details) {
              widget.onSelect(index);
              setState(() {
                _dragStartRect = rect;
                _dragStartGlobal = details.globalPosition;
              });
            },
            onPanUpdate: (details) =>
                _moverDesdeInicio(index, layer, details.globalPosition, size),
            onPanEnd: (_) {
              setState(() {
                _dragStartRect = null;
                _dragStartGlobal = null;
              });
            },
            onPanCancel: () {
              setState(() {
                _dragStartRect = null;
                _dragStartGlobal = null;
              });
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: isEditing
                    ? Border.all(color: CoresFolhio.green, width: 1.8)
                    : null,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: _editorTexto(index, layer, rect, isEditing, size),
            ),
          ),
        ),
      ),
      if (isEditing) ...[
        _tratar(index, layer, rect.left, rect.top, 'topLeft', size),
        _tratar(index, layer, rect.right, rect.top, 'topRight', size),
        _tratar(index, layer, rect.left, rect.bottom, 'bottomLeft', size),
        _tratar(index, layer, rect.right, rect.bottom, 'bottomRight', size),
        _alcaBorda(index, layer, rect.left, rect.center.dy, 'left', size),
        _alcaBorda(index, layer, rect.right, rect.center.dy, 'right', size),
        _alcaBorda(
          index,
          layer,
          rect.center.dx,
          rect.top,
          'top',
          size,
          vertical: false,
        ),
        _alcaBorda(
          index,
          layer,
          rect.center.dx,
          rect.bottom,
          'bottom',
          size,
          vertical: false,
        ),
      ],
    ];
  }

  Rect _inicialRetangulo(Size size, int index) {
    final width = (size.width * 0.58)
        .clamp(_minWidth, size.width - 32)
        .toDouble();
    final height = (size.height * 0.12).clamp(_minHeight, 82.0).toDouble();
    final offset = (index * 18).clamp(0, 90).toDouble();
    return Rect.fromLTWH(
      (size.width - width) / 2 + offset,
      (size.height - height) / 2 + offset,
      width,
      height,
    );
  }

  Widget _editorTexto(
    int index,
    CamadaTextoVisual layer,
    Rect rect,
    bool isEditing,
    Size size,
  ) {
    final fontSize = (rect.height * 0.42).clamp(12.0, 52.0).toDouble();
    final style = TextStyle(
      color: layer.color,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
    );

    if (!isEditing) {
      return Center(
        child: Text(
          _exibirTexto(layer.text),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
    }

    final controller = _controllerPara(index, layer.text);
    final focusNode = _noFocoPara(index);
    if (!focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedIndex == index && widget.editable) {
          focusNode.requestFocus();
        }
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            maxLines: null,
            minLines: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            cursorColor: CoresFolhio.green,
            style: style,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
            textAlignVertical: TextAlignVertical.center,
            onTap: () => widget.onSelect(index),
            onChanged: (value) =>
                widget.onUpdate(index, layer.copiarCom(text: value, rect: rect)),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              widget.onSelect(index);
              if (layer.rect == null) {
                widget.onUpdate(index, layer.copiarCom(rect: rect));
              }
              focusNode.requestFocus();
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
            },
            onPanStart: (details) {
              setState(() {
                _dragStartRect = rect;
                _dragStartGlobal = details.globalPosition;
              });
            },
            onPanUpdate: (details) =>
                _moverDesdeInicio(index, layer, details.globalPosition, size),
            onPanEnd: (_) {
              setState(() {
                _dragStartRect = null;
                _dragStartGlobal = null;
              });
            },
            onPanCancel: () {
              setState(() {
                _dragStartRect = null;
                _dragStartGlobal = null;
              });
            },
          ),
        ),
      ],
    );
  }

  TextEditingController _controllerPara(int index, String text) {
    final controller = _controllers.putIfAbsent(index, () {
      final value = _exibirTexto(text);
      return TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length);
    });
    final focusNode = _focusNodes[index];
    final value = _exibirTexto(text);
    if (focusNode?.hasFocus != true && controller.text != value) {
      controller.text = value;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
    return controller;
  }

  FocusNode _noFocoPara(int index) =>
      _focusNodes.putIfAbsent(index, FocusNode.new);

  String _exibirTexto(String text) {
    final value = text.trim();
    return value.isEmpty ? 'Texto' : value;
  }

  Widget _tratar(
    int index,
    CamadaTextoVisual layer,
    double x,
    double y,
    String handle,
    Size size,
  ) {
    return Positioned(
      left: x - _hitSize / 2,
      top: y - _hitSize / 2,
      width: _hitSize,
      height: _hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _resizeStartRect = layer.rect ?? _inicialRetangulo(size, index);
          _resizeStartGlobal = details.globalPosition;
        },
        onPanUpdate: (details) => _redimensionarDesdeInicio(
          index,
          layer,
          handle,
          details.globalPosition,
          size,
        ),
        onPanEnd: (_) => _limparInicioRedimensionamento(),
        onPanCancel: _limparInicioRedimensionamento,
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: CoresFolhio.green,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alcaBorda(
    int index,
    CamadaTextoVisual layer,
    double x,
    double y,
    String handle,
    Size size, {
    bool vertical = true,
  }) {
    return Positioned(
      left: vertical ? x - _hitSize / 2 : x - 32,
      top: vertical ? y - 24 : y - _hitSize / 2,
      width: vertical ? _hitSize : 64,
      height: vertical ? 48 : _hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _resizeStartRect = layer.rect ?? _inicialRetangulo(size, index);
          _resizeStartGlobal = details.globalPosition;
        },
        onPanUpdate: (details) => _redimensionarDesdeInicio(
          index,
          layer,
          handle,
          details.globalPosition,
          size,
        ),
        onPanEnd: (_) => _limparInicioRedimensionamento(),
        onPanCancel: _limparInicioRedimensionamento,
        child: Center(
          child: Container(
            width: vertical ? 8 : 48,
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
    CamadaTextoVisual layer,
    Offset globalPosition,
    Size size,
  ) {
    final rect = _dragStartRect ?? layer.rect ?? _inicialRetangulo(size, index);
    final delta = _dragStartGlobal == null
        ? Offset.zero
        : globalPosition - _dragStartGlobal!;
    final nextLeft = (rect.left + delta.dx)
        .clamp(0.0, size.width - rect.width)
        .toDouble();
    final nextTop = (rect.top + delta.dy)
        .clamp(0.0, size.height - rect.height)
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
    CamadaTextoVisual layer,
    String handle,
    Offset globalPosition,
    Size size,
  ) {
    final rect = _resizeStartRect ?? layer.rect ?? _inicialRetangulo(size, index);
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

    left = left.clamp(0.0, right - _minWidth).toDouble();
    right = right.clamp(left + _minWidth, size.width).toDouble();
    top = top.clamp(0.0, bottom - _minHeight).toDouble();
    bottom = bottom.clamp(top + _minHeight, size.height).toDouble();

    widget.onUpdate(
      index,
      layer.copiarCom(rect: Rect.fromLTRB(left, top, right, bottom)),
    );
  }

  void _limparInicioRedimensionamento() {
    _resizeStartRect = null;
    _resizeStartGlobal = null;
  }
}
