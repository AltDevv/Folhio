part of '../../screen/edit/edit_flows_screen.dart';

class _PaginaDocumentoPreview extends StatelessWidget {
  final String fileName;
  final bool convertedFromPdf;

  const _PaginaDocumentoPreview({
    required this.fileName,
    required this.convertedFromPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 794 / 1123,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black87),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  convertedFromPdf
                      ? 'PDF convertido para Word editavel'
                      : 'Documento Word editavel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 10,
                  width: double.infinity,
                  color: const Color(0xFFE9ECEA),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  color: const Color(0xFFE9ECEA),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 220,
                  color: const Color(0xFFE9ECEA),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD8DEDA)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, color: Colors.black38),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Use Texto, Imagem, Marcar e Ajustes para editar no celular.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EdicaoVisualToolbar extends StatelessWidget {
  final String selectedTool;
  final bool removeBackgroundActive;
  final bool hasFile;
  final bool open;
  final VoidCallback onToggleOpen;
  final ValueChanged<String> onToolSelected;
  final VoidCallback onReset;

  const _EdicaoVisualToolbar({
    required this.selectedTool,
    required this.removeBackgroundActive,
    required this.hasFile,
    required this.open,
    required this.onToggleOpen,
    required this.onToolSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.borderSoft)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.bottomCenter,
        child: open
            ? Row(
                children: [
                  _FerramentaAlternanciaButton(open: open, onTap: onToggleOpen),
                  _FerramentaIconButton(
                    icon: Icons.restart_alt,
                    label: 'Limpar',
                    selected: false,
                    enabled: hasFile,
                    onTap: onReset,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _FerramentaIconButton(
                            icon: Icons.auto_fix_high,
                            label: 'Fundo',
                            selected: removeBackgroundActive,
                            enabled: hasFile,
                            onTap: () =>
                                onToolSelected(VisualEdicaoFerramenta.removeBackground),
                          ),
                          _FerramentaIconButton(
                            icon: Icons.crop,
                            label: 'Cortar',
                            selected: selectedTool == VisualEdicaoFerramenta.crop,
                            enabled: hasFile,
                            onTap: () => onToolSelected(VisualEdicaoFerramenta.crop),
                          ),
                          _FerramentaIconButton(
                            icon: Icons.exposure,
                            label: 'Ajustes',
                            selected:
                                selectedTool == VisualEdicaoFerramenta.adjustments,
                            enabled: hasFile,
                            onTap: () =>
                                onToolSelected(VisualEdicaoFerramenta.adjustments),
                          ),
                          _FerramentaIconButton(
                            icon: Icons.text_fields,
                            label: 'Texto',
                            selected: selectedTool == VisualEdicaoFerramenta.text,
                            enabled: hasFile,
                            onTap: () => onToolSelected(VisualEdicaoFerramenta.text),
                          ),
                          _FerramentaIconButton(
                            icon: Icons.add_photo_alternate_outlined,
                            label: 'Imagem',
                            selected: selectedTool == VisualEdicaoFerramenta.image,
                            enabled: hasFile,
                            onTap: () => onToolSelected(VisualEdicaoFerramenta.image),
                          ),
                          _FerramentaIconButton(
                            icon: Icons.brush,
                            label: 'Marcar',
                            selected: selectedTool == VisualEdicaoFerramenta.mark,
                            enabled: hasFile,
                            onTap: () => onToolSelected(VisualEdicaoFerramenta.mark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: _FerramentaAlternanciaButton(open: open, onTap: onToggleOpen),
                ),
              ),
      ),
    );
  }
}

class _FaixaAcoesRecorte extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _FaixaAcoesRecorte({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return _BotoesDecisaoInferiores(
      cancelLabel: 'Cancelar',
      confirmLabel: 'Confirmar',
      onCancel: onCancel,
      onConfirm: onConfirm,
    );
  }
}

class _FaixaAcoesEditor extends StatelessWidget {
  final bool processing;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _FaixaAcoesEditor({
    required this.processing,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _BotoesDecisaoInferiores(
      cancelLabel: 'Cancelar',
      confirmLabel: processing ? 'Exportando...' : 'Confirmar',
      onCancel: processing ? null : onCancel,
      onConfirm: processing ? null : onConfirm,
    );
  }
}

class _BotoesDecisaoInferiores extends StatelessWidget {
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const _BotoesDecisaoInferiores({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: Text(cancelLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.borderSoft),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check, size: 18),
                label: Text(confirmLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresFolhio.green,
                  foregroundColor: CoresFolhio.greenDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FerramentaAlternanciaButton extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;

  const _FerramentaAlternanciaButton({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Tooltip(
      message: open ? 'Recolher ferramentas' : 'Mostrar ferramentas',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 42,
          height: open ? 50 : 34,
          margin: EdgeInsets.only(left: open ? 8 : 0),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary),
          ),
          child: Icon(
            open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            color: colors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _FerramentaIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _FerramentaIconButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 58,
          height: 50,
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? colors.primary : colors.borderSoft,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: !enabled
                    ? colors.dim
                    : selected
                    ? colors.primary
                    : colors.text,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: !enabled
                      ? colors.dim
                      : selected
                      ? colors.primary
                      : colors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
