part of '../../screen/tools/ferramentas_screen.dart';

class _DefinicaoFerramenta {
  final String id;
  final String title;
  final String subtitle;
  final String categoryId;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _DefinicaoFerramenta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryId,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _CategoriaFerramenta {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CategoriaFerramenta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _GradeMaisUsados extends StatelessWidget {
  final List<_DefinicaoFerramenta> tools;
  final ValueChanged<_DefinicaoFerramenta> onTap;

  const _GradeMaisUsados({required this.tools, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tool in tools)
              _FerramentaMaisUsadaCard(
                width: width,
                tool: tool,
                onTap: () => onTap(tool),
              ),
          ],
        );
      },
    );
  }
}

class _FerramentaMaisUsadaCard extends StatelessWidget {
  final double width;
  final _DefinicaoFerramenta tool;
  final VoidCallback onTap;

  const _FerramentaMaisUsadaCard({
    required this.width,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return SizedBox(
      width: width,
      child: FolhioCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        color: colors.surfaceSoft,
        child: Row(
          children: [
            IconeArredondado(
              icon: tool.icon,
              color: tool.color,
              backgroundColor: colors.surface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tool.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaFerramentaCard extends StatelessWidget {
  final _CategoriaFerramenta category;
  final VoidCallback onTap;

  const _CategoriaFerramentaCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;
    return FolhioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: colors.surfaceSoft,
      child: Row(
        children: [
          IconeArredondado(
            icon: category.icon,
            color: category.color,
            backgroundColor: colors.surface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (showDescriptions &&
                    category.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.muted),
        ],
      ),
    );
  }
}

class _LinhaListaFerramentas extends StatelessWidget {
  final _DefinicaoFerramenta tool;
  final VoidCallback onTap;

  const _LinhaListaFerramentas({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioItemLista(
      icon: tool.icon,
      iconColor: tool.color,
      iconBackground: colors.surfaceSoft,
      title: tool.title,
      subtitle: tool.subtitle,
      onTap: onTap,
    );
  }
}

class _CategoriaFerramentaScreen extends StatelessWidget {
  final _CategoriaFerramenta category;
  final List<_DefinicaoFerramenta> tools;
  final Map<String, int> usage;
  final ValueChanged<_DefinicaoFerramenta> onToolOpened;

  const _CategoriaFerramentaScreen({
    required this.category,
    required this.tools,
    required this.usage,
    required this.onToolOpened,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: category.title,
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          for (final tool in tools)
            _LinhaListaFerramentas(tool: tool, onTap: () => onToolOpened(tool)),
        ],
      ),
    );
  }
}

class _BuscaFerramentasVazia extends StatelessWidget {
  const _BuscaFerramentasVazia();

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      child: Text(
        'Nenhuma ferramenta encontrada.',
        style: TextStyle(color: context.folhioColors.muted),
      ),
    );
  }
}
