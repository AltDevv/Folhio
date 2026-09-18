part of '../../screen/library/meus_arquivos_screen.dart';

class _BibliotecaVaziaState extends StatelessWidget {
  final Set<String> tags;

  const _BibliotecaVaziaState({this.tags = const <String>{}});

  @override
  Widget build(BuildContext context) {
    final hasTag = tags.isNotEmpty;
    return FolhioCard(
      color: CoresFolhio.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasTag
                ? 'Nenhum material com essas tags.'
                : 'Nenhum material por aqui.',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            hasTag
                ? 'Tente outra tag ou limpe o filtro para ver tudo.'
                : 'Use Nova pasta para organizar seus materiais ou Importar material para adicionar PDFs, imagens e documentos.',
            style: TextStyle(
              color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraCaminho extends StatelessWidget {
  final List<FolhioPastaBiblioteca> path;
  final VoidCallback onBackFolder;

  const _BarraCaminho({required this.path, required this.onBackFolder});

  @override
  Widget build(BuildContext context) {
    final parts = [_rootMaterialsLabel, ...path.map((folder) => folder.name)];
    final label = parts.join(' / ');
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (path.isNotEmpty)
            IconButton(
              onPressed: onBackFolder,
              icon: const Icon(Icons.arrow_upward, color: CoresFolhio.green),
              tooltip: 'Voltar uma pasta',
            ),
          const Icon(Icons.folder_open, color: CoresFolhio.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenomeacaoArquivoDialog extends StatefulWidget {
  final String initialName;

  const _RenomeacaoArquivoDialog({required this.initialName});

  @override
  State<_RenomeacaoArquivoDialog> createState() => _RenomeacaoArquivoDialogState();
}

class _RenomeacaoArquivoDialogState extends State<_RenomeacaoArquivoDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renomear material'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nome',
          hintText: 'Digite o novo nome',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: _enviar,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => _enviar(_name.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _enviar(String value) {
    Navigator.pop(context, value.trim());
  }
}

class _FormularioPastaDialog extends StatefulWidget {
  final FolhioPastaBiblioteca? folder;

  const _FormularioPastaDialog({this.folder});

  @override
  State<_FormularioPastaDialog> createState() => _FormularioPastaDialogState();
}

class _FormularioPastaDialogState extends State<_FormularioPastaDialog> {
  late final TextEditingController _name;
  late final TextEditingController _tagInput;
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.folder?.name ?? '');
    _tagInput = TextEditingController();
    _tags = _limparEtiquetas(widget.folder?.tags ?? '').take(5).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.folder == null ? 'Nova pasta' : 'Editar pasta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInput,
                    decoration: const InputDecoration(
                      labelText: 'Adicionar tag',
                      hintText: 'Ex: prova',
                      helperText: 'M�ximo de 5 tags.',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _adicionarEtiqueta(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _tags.length >= 5 ? null : _adicionarEtiqueta,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar tag',
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _tags)
                      PopupMenuButton<String>(
                        tooltip: 'Op��es da tag',
                        onSelected: (value) {
                          if (value == 'delete') _removerEtiqueta(tag);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir tag'),
                          ),
                        ],
                        child: Chip(
                          label: Text(tag),
                          avatar: const Icon(Icons.sell_outlined, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Materiais enviados aqui podem ter até 110 MB, incluindo PDF, imagem, documento e vídeo. Arquivos maiores ficarão disponíveis nos planos pagos.',
              style: TextStyle(
                color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            _adicionarEtiqueta(showLimitWarning: false);
            Navigator.pop(
              context,
              _FormularioPasta(
                name: _name.text.trim(),
                tags: _tags.join(', '),
                notes: widget.folder?.notes ?? '',
                links: widget.folder?.links ?? '',
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _adicionarEtiqueta({bool showLimitWarning = true}) {
    final tag = _limparEtiqueta(_tagInput.text);
    if (tag.isEmpty) return;
    if (_tags.length >= 5) {
      if (showLimitWarning) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use no maximo 5 tags por pasta.')),
        );
      }
      return;
    }
    if (_tags.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagInput.clear();
    });
  }

  void _removerEtiqueta(String tag) {
    setState(() => _tags.remove(tag));
  }

  List<String> _limparEtiquetas(String value) {
    return value
        .split(',')
        .expand((part) => part.split(';'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  String _limparEtiqueta(String value) {
    final cleaned = value
        .replaceAll(',', ' ')
        .replaceAll(';', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= 24) return cleaned;
    return cleaned.substring(0, 24).trim();
  }
}

class _FormularioPasta {
  final String name;
  final String tags;
  final String notes;
  final String links;

  const _FormularioPasta({
    required this.name,
    required this.tags,
    required this.notes,
    required this.links,
  });
}
