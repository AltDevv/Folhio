part of '../../screen/library/meus_arquivos_screen.dart';

class _FiltrosMaterial {
  final String? status;
  final Set<String> tags;

  const _FiltrosMaterial({this.status, this.tags = const <String>{}});
}

class _MaterialFilterFolha extends StatefulWidget {
  final _FiltrosMaterial initial;
  final List<String> tags;

  const _MaterialFilterFolha({required this.initial, required this.tags});

  @override
  State<_MaterialFilterFolha> createState() => _MaterialFilterFolhaState();
}

class _MaterialFilterFolhaState extends State<_MaterialFilterFolha> {
  String? _status;
  late Set<String> _tags;

  static const _statuses = [
    'Rascunhos',
    'Publicados',
    'Importados',
    'Recentes',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _tags = Set<String>.from(widget.initial.tags);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajustes de materiais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const _RotuloPainelFiltros('Status'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _status == null,
                    label: const Text('Todos'),
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  for (final status in _statuses)
                    ChoiceChip(
                      selected: _status == status,
                      label: Text(status),
                      onSelected: (_) => setState(() => _status = status),
                    ),
                ],
              ),
              if (widget.tags.isNotEmpty)
                _DicaPainelFiltros(
                  text:
                      'Use as tags na tela da Biblioteca para combinar filtros como Favoritos e Gabarito.',
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, const _FiltrosMaterial()),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _FiltrosMaterial(status: _status, tags: _tags),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltrosModelo {
  final String? type;
  final String? access;
  final Set<String> tags;

  const _FiltrosModelo({
    this.type,
    this.access,
    this.tags = const <String>{},
  });
}

class _ModeloFilterFolha extends StatefulWidget {
  final _FiltrosModelo initial;
  final List<String> tags;

  const _ModeloFilterFolha({required this.initial, required this.tags});

  @override
  State<_ModeloFilterFolha> createState() => _ModeloFilterFolhaState();
}

class _ModeloFilterFolhaState extends State<_ModeloFilterFolha> {
  String? _type;
  String? _access;
  late Set<String> _tags;

  static const _types = [
    'Atividades',
    'Provas',
    'Planos',
    'Revis�es',
    'Simulados',
  ];
  static const _accessTypes = ['Gratis', 'Premium'];

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _access = widget.initial.access;
    _tags = Set<String>.from(widget.initial.tags);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajustes de modelos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const _RotuloPainelFiltros('Tipo de modelo'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _type == null,
                    label: const Text('Todos'),
                    onSelected: (_) => setState(() => _type = null),
                  ),
                  for (final type in _types)
                    ChoiceChip(
                      selected: _type == type,
                      label: Text(type),
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const _RotuloPainelFiltros('Acesso'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _access == null,
                    label: const Text('Todos'),
                    onSelected: (_) => setState(() => _access = null),
                  ),
                  for (final access in _accessTypes)
                    ChoiceChip(
                      selected: _access == access,
                      label: Text(_rotuloAcessoModelo(access)),
                      onSelected: (_) => setState(() => _access = access),
                    ),
                ],
              ),
              if (widget.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                const _RotuloPainelFiltros('Filtros r�pidos'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in widget.tags)
                      FilterChip(
                        selected: _tags.any(
                          (item) => item.toLowerCase() == tag.toLowerCase(),
                        ),
                        avatar: Icon(
                          tag == _favoriteTag
                              ? Icons.star_border
                              : Icons.sell_outlined,
                          size: 16,
                        ),
                        label: Text(tag),
                        onSelected: (_) {
                          setState(() {
                            final next = Set<String>.from(_tags);
                            final existing = next.where(
                              (item) => item.toLowerCase() == tag.toLowerCase(),
                            );
                            if (existing.isNotEmpty) {
                              next.remove(existing.first);
                            } else {
                              next.add(tag);
                            }
                            _tags = next;
                          });
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, const _FiltrosModelo()),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _FiltrosModelo(
                          type: _type,
                          access: _access,
                          tags: _tags,
                        ),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotuloPainelFiltros extends StatelessWidget {
  final String label;

  const _RotuloPainelFiltros(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DicaPainelFiltros extends StatelessWidget {
  final String text;

  const _DicaPainelFiltros({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
