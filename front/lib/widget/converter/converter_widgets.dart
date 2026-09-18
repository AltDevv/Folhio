part of '../../screen/converter/conversor_screen.dart';

class _FluxoConversao {
  final String key;
  final String title;
  final String detail;
  final List<String> sourceExtensions;
  final String targetFormat;
  final IconData icon;
  final Color color;
  final bool beta;

  const _FluxoConversao({
    required this.key,
    required this.title,
    required this.detail,
    required this.sourceExtensions,
    required this.targetFormat,
    required this.icon,
    required this.color,
    this.beta = false,
  });
}

class _ArquivoOrigemPanel extends StatelessWidget {
  final String? fileName;
  final String extension;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _ArquivoOrigemPanel({
    required this.fileName,
    required this.extension,
    required this.busy,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final hasFile = fileName != null;
    return FolhioCard(
      onTap: busy ? null : onPick,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      borderColor: hasFile ? colors.primary : colors.borderSoft,
      child: Column(
        children: [
          IconeArredondado(
            icon: hasFile ? _iconePara(extension) : Icons.folder_outlined,
            color: hasFile ? colors.primary : colors.text,
            backgroundColor: colors.surfaceSoft,
          ),
          const SizedBox(height: 12),
          Text(
            hasFile ? 'Arquivo selecionado' : 'Nenhum arquivo selecionado',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (hasFile)
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    tooltip: 'Trocar arquivo',
                    onPressed: busy ? null : onClear,
                    icon: Icon(Icons.close, color: colors.muted),
                  ),
              ],
            )
          else
            SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onPick,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Escolher arquivo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconePara(String extension) {
    if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
    if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
      return Icons.image_outlined;
    }
    if (extension == 'doc' || extension == 'docx') {
      return Icons.description_outlined;
    }
    if (extension == 'xls' || extension == 'xlsx') {
      return Icons.table_chart_outlined;
    }
    if (extension == 'ppt' || extension == 'pptx') {
      return Icons.slideshow_outlined;
    }
    return Icons.insert_drive_file;
  }
}

class _LinhaAcoesConversao extends StatelessWidget {
  final _FluxoConversao flow;
  final bool processing;
  final bool disabled;
  final int imageFormatIndex;
  final ValueChanged<int> onImageFormatChanged;
  final VoidCallback onConvert;

  const _LinhaAcoesConversao({
    required this.flow,
    required this.processing,
    required this.disabled,
    required this.imageFormatIndex,
    required this.onImageFormatChanged,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final muted = disabled || processing;
    return FolhioCard(
      onTap: muted ? null : onConvert,
      borderColor: flow.beta ? CoresFolhio.violet : colors.borderSoft,
      child: Column(
        children: [
          Row(
            children: [
              IconeArredondado(
                icon: flow.icon,
                color: muted ? colors.dim : flow.color,
                backgroundColor: colors.surfaceSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flow.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted ? colors.dim : colors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      flow.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (flow.beta) ...[
                const SizedBox(width: 8),
                const StatusPill(label: 'Beta', tone: TomIndicador.violet),
              ],
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: TextButton(
                  onPressed: muted ? null : onConvert,
                  child: Text(processing ? 'Convertendo...' : 'Converter'),
                ),
              ),
            ],
          ),
          if (flow.key == 'pdf_image') ...[
            const SizedBox(height: 10),
            SeletorChip(
              labels: const ['PNG', 'JPG'],
              selectedIndex: imageFormatIndex,
              onSelected: disabled || processing ? null : onImageFormatChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeConversoesRapidas extends StatelessWidget {
  final List<_FluxoConversao> flows;
  final bool busy;
  final ValueChanged<_FluxoConversao> onSelected;

  const _GradeConversoesRapidas({
    required this.flows,
    required this.busy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flows.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final flow = flows[index];
        return _ConversaoRapidaTile(
          flow: flow,
          disabled: busy,
          onTap: () => onSelected(flow),
        );
      },
    );
  }
}

class _ConversaoRapidaTile extends StatelessWidget {
  final _FluxoConversao flow;
  final bool disabled;
  final VoidCallback onTap;

  const _ConversaoRapidaTile({
    required this.flow,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final color = disabled ? colors.dim : flow.color;
    return FolhioCard(
      onTap: disabled ? null : onTap,
      padding: const EdgeInsets.all(10),
      borderColor: flow.beta ? CoresFolhio.violet : colors.borderSoft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconeOrigem(flow), color: color, size: 23),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward, color: colors.muted, size: 16),
              ),
              Icon(_iconeDestino(flow), color: color, size: 23),
            ],
          ),
          Text(
            _rotuloRapido(flow),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: disabled ? colors.dim : colors.text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (flow.beta)
            const StatusPill(label: 'Beta', tone: TomIndicador.violet)
          else
            Text(
              flow.targetFormat.toUpperCase(),
              style: TextStyle(
                color: colors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconeOrigem(_FluxoConversao flow) {
    final first = flow.sourceExtensions.first;
    if (first == 'pdf') return Icons.picture_as_pdf_outlined;
    if (first == 'png' || first == 'jpg' || first == 'jpeg') {
      return Icons.image_outlined;
    }
    if (first == 'doc' || first == 'docx') return Icons.description_outlined;
    if (first == 'xls' || first == 'xlsx') return Icons.table_chart_outlined;
    if (first == 'ppt' || first == 'pptx') return Icons.slideshow_outlined;
    return Icons.insert_drive_file;
  }

  IconData _iconeDestino(_FluxoConversao flow) {
    final target = flow.targetFormat;
    if (target == 'pdf') return Icons.picture_as_pdf_outlined;
    if (target == 'png' || target == 'jpg') return Icons.image_outlined;
    if (target == 'docx') return Icons.description_outlined;
    if (target == 'xlsx') return Icons.table_chart_outlined;
    if (target == 'pptx') return Icons.slideshow_outlined;
    return Icons.insert_drive_file;
  }

  String _rotuloRapido(_FluxoConversao flow) {
    final source = _rotuloOrigem(flow.sourceExtensions.first);
    final target = _rotuloDestino(flow.targetFormat);
    return '$source para $target';
  }

  String _rotuloOrigem(String extension) {
    if (extension == 'pdf') return 'PDF';
    if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
      return 'Imagem';
    }
    if (extension == 'doc' || extension == 'docx') return 'Word';
    if (extension == 'xls' || extension == 'xlsx') return 'Excel';
    if (extension == 'ppt' || extension == 'pptx') return 'Slide';
    return 'Arquivo';
  }

  String _rotuloDestino(String target) {
    if (target == 'pdf') return 'PDF';
    if (target == 'png' || target == 'jpg') return 'Imagem';
    if (target == 'docx') return 'Word';
    if (target == 'xlsx') return 'Excel';
    if (target == 'pptx') return 'Slide';
    return target.toUpperCase();
  }
}

class _DicaConversaoVazia extends StatelessWidget {
  const _DicaConversaoVazia();

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      color: colors.surfaceSoft,
      child: Row(
        children: [
          Icon(Icons.touch_app, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escolha um arquivo ou use uma conversão rápida. O app abre o tipo ideal automaticamente.',
              style: TextStyle(
                color: colors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemAcoesCard extends StatelessWidget {
  const _SemAcoesCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      child: Text(
        'Nenhuma conversão disponível para esse arquivo.',
        style: TextStyle(
          color: colors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
