part of '../../screen/edit/edit_flows_screen.dart';

class PosicionamentoAssinaturaPreview extends StatefulWidget {
  final String? pdfPreviewUrl;
  final double? pageWidth;
  final double? pageHeight;
  final File? signatureImage;
  final double xRatio;
  final double yRatio;
  final double widthRatio;
  final void Function(double xRatio, double yRatio) onMoved;

  const PosicionamentoAssinaturaPreview({
    super.key,
    required this.pdfPreviewUrl,
    required this.pageWidth,
    required this.pageHeight,
    required this.signatureImage,
    required this.xRatio,
    required this.yRatio,
    required this.widthRatio,
    required this.onMoved,
  });

  @override
  State<PosicionamentoAssinaturaPreview> createState() =>
      _PosicionamentoAssinaturaPreviewState();
}

class _PosicionamentoAssinaturaPreviewState extends State<PosicionamentoAssinaturaPreview> {
  double? _dragLeft;
  double? _dragTop;
  bool _dragging = false;

  @override
  void didUpdateWidget(PosicionamentoAssinaturaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging &&
        (oldWidget.xRatio != widget.xRatio ||
            oldWidget.yRatio != widget.yRatio ||
            oldWidget.widthRatio != widget.widthRatio ||
            oldWidget.pageWidth != widget.pageWidth ||
            oldWidget.pageHeight != widget.pageHeight)) {
      _dragLeft = null;
      _dragTop = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final pageWidth = width;
          final aspect =
              (widget.pageWidth != null &&
                  widget.pageHeight != null &&
                  widget.pageWidth! > 0)
              ? widget.pageHeight! / widget.pageWidth!
              : 1.36;
          final pageHeight = width * aspect.clamp(0.55, 1.60).toDouble();
          final signWidth =
              pageWidth * widget.widthRatio.clamp(0.10, 0.60).toDouble();
          final signHeight = signWidth * 0.42;
          final fallbackLeft =
              (pageWidth - signWidth) * widget.xRatio.clamp(0, 1).toDouble();
          final fallbackTop =
              (pageHeight - signHeight) * widget.yRatio.clamp(0, 1).toDouble();
          final left = (_dragLeft ?? fallbackLeft)
              .clamp(0.0, pageWidth - signWidth)
              .toDouble();
          final top = (_dragTop ?? fallbackTop)
              .clamp(0.0, pageHeight - signHeight)
              .toDouble();

          return SizedBox(
            height: pageHeight,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: pageWidth,
                    height: pageHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: CoresFolhio.border),
                    ),
                    child: widget.pdfPreviewUrl == null
                        ? const Center(
                            child: Text(
                              'Escolha o PDF para ver a p�gina',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : Image.network(
                            widget.pdfPreviewUrl!,
                            headers: FolhioApiGateway.apiHeaders,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Center(
                              child: Text(
                                'N�o foi poss�vel carregar a pr�via',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF777777),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: signWidth,
                  height: signHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) {
                      _dragging = true;
                      _dragLeft = left;
                      _dragTop = top;
                    },
                    onPanUpdate: (details) {
                      final currentLeft = _dragLeft ?? left;
                      final currentTop = _dragTop ?? top;
                      final nextLeft = (currentLeft + details.delta.dx)
                          .clamp(0.0, pageWidth - signWidth)
                          .toDouble();
                      final nextTop = (currentTop + details.delta.dy)
                          .clamp(0.0, pageHeight - signHeight)
                          .toDouble();
                      setState(() {
                        _dragLeft = nextLeft;
                        _dragTop = nextTop;
                      });
                      widget.onMoved(
                        pageWidth == signWidth
                            ? 0.0
                            : nextLeft / (pageWidth - signWidth),
                        pageHeight == signHeight
                            ? 0.0
                            : nextTop / (pageHeight - signHeight),
                      );
                    },
                    onPanEnd: (_) {
                      _dragging = false;
                    },
                    onPanCancel: () {
                      _dragging = false;
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CoresFolhio.green,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                      child: Image.file(
                        widget.signatureImage!,
                        fit: BoxFit.contain,
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
}

class _ItemMesclagem extends StatelessWidget {
  final String order;
  final String name;
  final String detail;
  final bool selected;
  final int dragIndex;
  final VoidCallback onTap;

  const _ItemMesclagem({
    super.key,
    required this.order,
    required this.name,
    required this.detail,
    required this.selected,
    required this.dragIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: selected
                ? colors.primary
                : colors.primary.withValues(alpha: 0.12),
            child: Text(
              order,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FolhioCard(
              onTap: onTap,
              borderColor: selected ? colors.primary : colors.borderSoft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: CoresFolhio.coral,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ReorderableDragStartListener(
            index: dragIndex,
            child: Icon(Icons.drag_indicator, color: colors.dim),
          ),
        ],
      ),
    );
  }
}

class _EscolhaCompactacao extends StatelessWidget {
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  const _EscolhaCompactacao({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      onTap: onTap,
      borderColor: selected ? colors.primary : colors.borderSoft,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected ? colors.primary : colors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
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
}

class _Metrica extends StatelessWidget {
  final String label;
  final String value;

  const _Metrica({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.dim, fontWeight: FontWeight.w800),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EntradaTextoCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _EntradaTextoCard({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: colors.input,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CoresFolhio.green),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _AlternanciaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AlternanciaCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FolhioCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _IdentificacaoPreview extends StatelessWidget {
  final String text;

  const _IdentificacaoPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Text.rich(
      TextSpan(
        text: 'Pr�via\n\n',
        style: TextStyle(color: colors.dim, fontWeight: FontWeight.w800),
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaIncremento extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _LinhaIncremento({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        NumeracaoStepper(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _EscolhaPosicao extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EscolhaPosicao({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      onTap: onTap,
      borderColor: selected ? colors.primary : colors.borderSoft,
      child: Column(
        children: [
          Icon(
            Icons.horizontal_rule,
            color: selected ? colors.primary : colors.dim,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? colors.primary : colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
