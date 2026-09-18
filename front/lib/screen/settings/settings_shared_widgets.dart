part of 'configuracoes_screen.dart';

class _ConfiguracoesPagina extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ConfiguracoesPagina({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: title,
      currentIndex: 0,
      showBack: true,
      body: FolhioCorpoPagina(children: children),
    );
  }
}

class _MenuConfiguracoesTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuConfiguracoesTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return FolhioItemLista(
      icon: icon,
      iconColor: iconColor,
      iconBackground: colors.surfaceSoft,
      title: title,
      subtitle: subtitle,
      trailing: onTap == null
          ? const SizedBox.shrink()
          : Icon(Icons.chevron_right, color: colors.muted),
      onTap: onTap,
    );
  }
}

class _GrupoConfiguracoes extends StatelessWidget {
  final List<Widget> children;

  const _GrupoConfiguracoes({required this.children});

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(children: children),
    );
  }
}

class _DropdownConfiguracao extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownConfiguracao({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final previewColor = label == 'Cor principal'
        ? _previaCorConfiguracoes(value, colors.primary)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox.shrink(),
              dropdownColor: Theme.of(context).cardTheme.color,
              isExpanded: true,
              items: [
                for (final item in values)
                  DropdownMenuItem(
                    value: item,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (label == 'Cor principal') ...[
                          _PontoCor(
                            color: _previaCorConfiguracoes(item, colors.primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
              selectedItemBuilder: previewColor == null
                  ? null
                  : (context) => [
                      for (final item in values)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _PontoCor(
                              color: _previaCorConfiguracoes(
                                item,
                                colors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                    ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PontoCor extends StatelessWidget {
  final Color color;

  const _PontoCor({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.folhioColors.border),
      ),
    );
  }
}

Color _previaCorConfiguracoes(String label, Color fallback) {
  return switch (label) {
    'Azul' => CoresFolhio.blue,
    'Roxo' => CoresFolhio.violet,
    'Amarelo' => CoresFolhio.orange,
    'Rosa' => CoresFolhio.pink,
    _ => fallback,
  };
}

class _ConfiguracaoAlternancia extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ConfiguracaoAlternancia({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title),
    );
  }
}

class _PlanoCard extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final Color? accentColor;
  final List<String> features;
  final bool selected;
  final String actionLabel;

  const _PlanoCard({
    required this.title,
    required this.price,
    this.badge,
    this.accentColor,
    required this.features,
    this.selected = false,
    this.actionLabel = 'Em breve',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CoresTemaFolhio>()!;
    final primary = accentColor ?? theme.colorScheme.primary;
    return FolhioCard(
      color: selected ? colors.primary.withValues(alpha: 0.08) : null,
      borderColor: selected || accentColor != null ? primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: selected ? 0.18 : 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              color: primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feature, style: TextStyle(color: colors.muted)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: selected
                ? FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(actionLabel),
                  )
                : OutlinedButton(onPressed: null, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

void _avisar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _mensagemErro(Object error, String fallback) {
  return error is FolhioAutenticacaoException ? error.message : fallback;
}
