part of '../../screen/home/inicio_screen.dart';

class _CabecalhoSaudacao extends StatefulWidget {
  const _CabecalhoSaudacao();

  @override
  State<_CabecalhoSaudacao> createState() => _CabecalhoSaudacaoState();
}

class _CabecalhoSaudacaoState extends State<_CabecalhoSaudacao> {
  String _name = 'professor';

  @override
  void initState() {
    super.initState();
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    final name = await PersistenciaLocalRepository.instance.configuracao('profile.name');
    if (!mounted) return;
    setState(
      () =>
          _name = name?.trim().isNotEmpty == true ? name!.trim() : 'professor',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: CoresFolhio.cream,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/folhio_icon_transparent.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $_name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showDescriptions) ...[
                const SizedBox(height: 3),
                Text(
                  'O que você quer preparar hoje?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).extension<CoresTemaFolhio>()!.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AcaoRapidaCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AcaoRapidaCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;
    return Container(
      width: 142,
      margin: const EdgeInsets.only(right: 10),
      child: FolhioCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 27),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                if (showDescriptions) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).extension<CoresTemaFolhio>()!.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAcaoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MiniAcaoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;
    final colors = context.folhioColors;
    return FolhioCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: CoresFolhio.surfaceSoft,
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (showDescriptions) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).extension<CoresTemaFolhio>()!.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArquivoBibliotecaTile extends StatelessWidget {
  final FolhioArquivoBiblioteca file;
  final VoidCallback onDownload;
  final VoidCallback onOpenFiles;
  final VoidCallback onDelete;

  const _ArquivoBibliotecaTile({
    required this.file,
    required this.onDownload,
    required this.onOpenFiles,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    final kind = _tipoPara(file.mimeType, file.fileName);
    return FolhioItemLista(
      icon: _iconePara(file.mimeType, file.fileName),
      iconColor: _corPara(file.mimeType, file.fileName),
      iconBackground: CoresFolhio.surfaceSoft,
      title: _tituloAmigavel(file.fileName),
      subtitle: '${file.folder} • ${_dataRotulo(file.updatedAt)}',
      badge: kind,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Baixar',
            onPressed: onDownload,
            icon: Icon(Icons.download, color: colors.text),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.text),
            onSelected: (value) {
              if (value == 'open') onOpenFiles();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'open', child: Text('Abrir na Biblioteca')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
      onTap: onOpenFiles,
    );
  }

  String _tituloAmigavel(String fileName) {
    final name = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return name.isEmpty ? fileName : name;
  }

  String _tipoPara(String mimeType, String fileName) {
    final lower = '$mimeType $fileName'.toLowerCase();
    if (lower.contains('pdf')) return 'PDF';
    if (lower.contains('image') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg')) {
      return 'Imagem';
    }
    if (lower.contains('word') || lower.endsWith('.docx')) return 'Atividade';
    if (lower.contains('sheet') || lower.endsWith('.xlsx')) return 'Planilha';
    return 'Material';
  }

  IconData _iconePara(String mimeType, String fileName) {
    final lower = '$mimeType $fileName'.toLowerCase();
    if (lower.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.contains('image') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg')) {
      return Icons.image_outlined;
    }
    if (lower.contains('word') || lower.endsWith('.docx')) {
      return Icons.assignment_outlined;
    }
    if (lower.contains('sheet') || lower.endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _corPara(String mimeType, String fileName) {
    final lower = '$mimeType $fileName'.toLowerCase();
    if (lower.contains('pdf')) return CoresFolhio.coral;
    if (lower.contains('image')) return CoresFolhio.blue;
    if (lower.contains('word')) return CoresFolhio.violet;
    return CoresFolhio.green;
  }

  String _dataRotulo(DateTime? value) {
    if (value == null) return 'recente';
    final now = DateTime.now();
    final diff = now.difference(value.toLocal());
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes} min atrás';
    if (diff.inDays < 1) return '${diff.inHours} h atrás';
    if (diff.inDays == 1) return 'ontem';
    return '${value.toLocal().day.toString().padLeft(2, '0')}/${value.toLocal().month.toString().padLeft(2, '0')}';
  }
}

class _TextoVazioDiscreto extends StatelessWidget {
  final String text;

  const _TextoVazioDiscreto(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ArquivosInicioVazios extends StatelessWidget {
  const _ArquivosInicioVazios();

  @override
  Widget build(BuildContext context) {
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;
    return FolhioCard(
      color: CoresFolhio.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nada em andamento ainda.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          if (showDescriptions) ...[
            SizedBox(height: 6),
            Text(
              'Crie uma atividade ou importe um PDF para continuar daqui depois.',
              style: TextStyle(
                color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
