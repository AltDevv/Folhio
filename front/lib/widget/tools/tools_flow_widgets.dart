part of '../../screen/tools/tools_flows_screen.dart';

class _CampoTextoFerramenta extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final VoidCallback? onChanged;

  const _CampoTextoFerramenta({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => onChanged?.call(),
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
      ),
    );
  }
}

class _LinhaAlternancia extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LinhaAlternancia({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    );
  }
}

class _PreviaBox extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _PreviaBox({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArquivosSelecionadosCard extends StatelessWidget {
  final int count;
  final String detail;
  final VoidCallback? onTap;

  const _ArquivosSelecionadosCard({
    required this.count,
    required this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      onTap: onTap,
      borderColor: count == 0 ? colors.borderSoft : colors.primary,
      child: Row(
        children: [
          const IconeArredondado(
            icon: Icons.folder,
            color: CoresFolhio.green,
            backgroundColor: Color(0xFFE3F8F1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'Selecionar arquivos'
                      : '$count arquivos selecionados',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
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
          ),
          if (onTap != null) const Icon(Icons.add, color: CoresFolhio.green),
        ],
      ),
    );
  }
}

class _FerramentaDestaqueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  const _FerramentaDestaqueCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      color: colors.primary.withValues(alpha: 0.10),
      borderColor: colors.primary.withValues(alpha: 0.40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeArredondado(
                icon: icon,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: 0.14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: actionLabel,
            icon: Icons.add,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _FerramentaVaziaState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FerramentaVaziaState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      child: Row(
        children: [
          IconeArredondado(
            icon: icon,
            color: colors.primary,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
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

class _CampoBuscaFerramentas extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _CampoBuscaFerramentas({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: colors.input,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}

class _LinhaEstatisticasFerramenta extends StatelessWidget {
  final List<_ItemEstatisticaFerramenta> items;

  const _LinhaEstatisticasFerramenta({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: item),
        ],
      ],
    );
  }
}

class _ItemEstatisticaFerramenta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ItemEstatisticaFerramenta({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorTurma extends StatelessWidget {
  final List<SchoolClass> classes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SeletorTurma({
    required this.classes,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, schoolClass) in classes.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: index == selectedIndex,
                label: Text(schoolClass.name),
                avatar: Icon(
                  Icons.dashboard_customize_outlined,
                  size: 16,
                  color: index == selectedIndex
                      ? context.folhioColors.primary
                      : context.folhioColors.muted,
                ),
                onSelected: (_) => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlunoTile extends StatelessWidget {
  final int number;
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlunoTile({
    required this.number,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primary.withValues(alpha: 0.14),
            child: Text(
              '$number',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (student.registration.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    student.registration,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar aluno',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remover aluno',
            onPressed: onDelete,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
