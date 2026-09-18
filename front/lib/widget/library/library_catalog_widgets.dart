part of '../../screen/library/meus_arquivos_screen.dart';

class _CabecalhoSecaoBiblioteca extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showIcon;

  const _CabecalhoSecaoBiblioteca({
    required this.icon,
    required this.title,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CoresTemaFolhio>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        if (showIcon) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? CoresFolhio.greenDeep
                  : colors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 17),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ModelosDestaque extends StatelessWidget {
  final ValueChanged<DetalhesModelo> onOpenTemplate;

  const _ModelosDestaque({required this.onOpenTemplate});

  @override
  Widget build(BuildContext context) {
    const items = [
      DetalhesModelo(
        id: 'featured-matematica-5',
        title: 'Atividade de Matemática',
        category: '5º ano',
        description:
            'Atividade com 20 questões para praticar conteúdos de Matemática do 5º ano. O material final poderá ser visualizado página por página antes de usar o modelo.',
        access: 'Grátis',
        icon: Icons.assignment_outlined,
        color: CoresFolhio.green,
      ),
      DetalhesModelo(
        id: 'featured-portugues-8',
        title: 'Prova bimestral de Português',
        category: '8º ano',
        description:
            'Estrutura de prova bimestral com 15 questões, espaço para identificação e organização pronta para receber gabarito.',
        access: 'Grátis',
        icon: Icons.quiz_outlined,
        color: CoresFolhio.blue,
      ),
      DetalhesModelo(
        id: 'featured-fracoes-6',
        title: 'Plano de aula - Frações',
        category: '6º ano',
        description:
            'Plano de aula organizado em objetivos, etapas e recursos para trabalhar frações no 6º ano.',
        access: 'Grátis',
        icon: Icons.event_note_outlined,
        color: CoresFolhio.orange,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CabecalhoSecaoBiblioteca(
          icon: Icons.auto_awesome,
          title: 'Modelos em destaque',
          showIcon: false,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 172,
                child: FolhioCard(
                  onTap: () => onOpenTemplate(item),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconeArredondado(
                            icon: item.icon,
                            color: item.color,
                            backgroundColor: item.color.withValues(alpha: 0.15),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: StatusPill(
                          label: item.category,
                          tone: TomIndicador.neutral,
                        ),
                      ),
                      Text(
                        item.id == 'featured-fracoes-6'
                            ? 'Etapas + objetivos'
                            : item.id == 'featured-portugues-8'
                            ? '15 questões · Com gabarito'
                            : '20 questões',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SecoesCatalogoModelos extends StatelessWidget {
  final ValueChanged<DetalhesModelo> onOpenTemplate;
  final String query;
  final String? type;
  final String? access;
  final Set<String> tags;

  const _SecoesCatalogoModelos({
    required this.onOpenTemplate,
    this.query = '',
    this.type,
    this.access,
    this.tags = const <String>{},
  });

  static const sections = _templateCatalogSections;

  static List<String> get templateTags => _templateCatalogTags;

  @override
  Widget build(BuildContext context) {
    final filteredSections = [
      for (final section in sections)
        _DadosSecaoCatalogoModelos(
          section.title,
          section.items
              .where(
                (item) => _modeloCorrespondeFiltros(
                  section: section.title,
                  item: item,
                  query: query,
                  type: type,
                  access: access,
                  tags: tags,
                ),
              )
              .toList(),
        ),
    ].where((section) => section.items.isNotEmpty).toList();

    if (filteredSections.isEmpty) {
      return FolhioCard(
        color: CoresFolhio.surfaceSoft,
        child: Text(
          'Nenhum modelo encontrado com esses filtros.',
          style: TextStyle(
            color: context.folhioColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < filteredSections.length; index++) ...[
          _SecaoCatalogoModelos(
            data: filteredSections[index],
            onOpenTemplate: onOpenTemplate,
          ),
          if (index != filteredSections.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SecaoCatalogoModelos extends StatelessWidget {
  final _DadosSecaoCatalogoModelos data;
  final ValueChanged<DetalhesModelo> onOpenTemplate;

  const _SecaoCatalogoModelos({
    required this.data,
    required this.onOpenTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoSecaoBiblioteca(
          icon: Icons.folder_copy_outlined,
          title: data.title,
          showIcon: false,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = data.items[index];
              return SizedBox(
                width: 164,
                child: _CatalogoModelosCard(
                  item: item,
                  onTap: () => onOpenTemplate(item.detalhes(data.title)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeloTodosLista extends StatelessWidget {
  final String query;
  final String? type;
  final String? access;
  final Set<String> tags;
  final ValueChanged<DetalhesModelo> onOpenTemplate;

  const _ModeloTodosLista({
    required this.query,
    this.type,
    this.access,
    this.tags = const <String>{},
    required this.onOpenTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.toLowerCase();
    final items =
        [
          for (final section in _SecoesCatalogoModelos.sections)
            for (final item in section.items)
              _ItemListaCatalogoModelos(section.title, item),
        ].where((entry) {
          return _modeloCorrespondeFiltros(
            section: entry.section,
            item: entry.item,
            query: normalizedQuery,
            type: type,
            access: access,
            tags: tags,
          );
        }).toList();

    if (items.isEmpty) {
      return FolhioCard(
        color: CoresFolhio.surfaceSoft,
        child: Text(
          'Nenhum modelo encontrado nessa busca.',
          style: TextStyle(
            color: context.folhioColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _TodosModelosCard(
            section: items[index].section,
            item: items[index].item,
            onTap: () =>
                onOpenTemplate(items[index].item.detalhes(items[index].section)),
          ),
        ],
      ],
    );
  }
}

class _TodosModelosCard extends StatelessWidget {
  final String section;
  final _ItemCatalogoModelos item;
  final VoidCallback onTap;

  const _TodosModelosCard({
    required this.section,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final premium = item.access == 'Premium';
    return FolhioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: premium ? CoresFolhio.violet : null,
      child: Row(
        children: [
          IconeArredondado(
            icon: item.icon,
            color: item.color,
            backgroundColor: item.color.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$section · ${item.subtitle}',
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
          const SizedBox(width: 8),
          StatusPill(
            label: _rotuloAcessoModelo(item.access),
            tone: premium ? TomIndicador.violet : TomIndicador.green,
          ),
        ],
      ),
    );
  }
}

class _CatalogoModelosCard extends StatelessWidget {
  final _ItemCatalogoModelos item;
  final VoidCallback onTap;

  const _CatalogoModelosCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final premium = item.access == 'Premium';
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return FolhioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      borderColor: premium ? CoresFolhio.violet : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.scale(
                scale: 0.88,
                child: IconeArredondado(
                  icon: item.icon,
                  color: item.color,
                  backgroundColor: item.color.withValues(alpha: 0.15),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          StatusPill(
            label: _rotuloAcessoModelo(item.access),
            tone: premium ? TomIndicador.violet : TomIndicador.green,
          ),
        ],
      ),
    );
  }
}
