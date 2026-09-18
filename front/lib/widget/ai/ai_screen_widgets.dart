part of '../../screen/ai/ia_screen.dart';

class _SecaoEtiquetas extends StatelessWidget {
  final String title;
  final bool isRequired;
  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _SecaoEtiquetas({
    required this.title,
    required this.isRequired,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rotulo(text: title, isRequired: isRequired),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: labels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _ChipGrande(
                  label: labels[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntradaTema extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _EntradaTema({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Rotulo(text: 'Tema / conteúdo', isRequired: true),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            decoration: _decoracaoEntrada(
              context,
              'Ex: fração equivalente, cordel, sistema solar',
            ),
          ),
        ],
      ),
    );
  }
}

class _EntradaDetalhes extends StatelessWidget {
  final TextEditingController controller;
  final bool pickingAudio;
  final VoidCallback onMicTap;
  final VoidCallback onChanged;

  const _EntradaDetalhes({
    required this.controller,
    required this.pickingAudio,
    required this.onMicTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Rotulo(
            text: 'Detalhes da atividade (opcional)',
            isRequired: false,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => onChanged(),
            decoration: _decoracaoEntrada(
              context,
              'Fale mais sobre o conteúdo ou regras específicas. '
              'Ex: use vocabulário sobre a água para o 3º ano.',
              suffix: IconButton(
                tooltip: pickingAudio ? 'Ouvindo detalhes' : 'Ditar detalhes',
                onPressed: onMicTap,
                icon: Icon(
                  pickingAudio ? Icons.mic_external_on : Icons.mic,
                  color: pickingAudio ? colors.muted : colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaisOpcoesButton extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;

  const _MaisOpcoesButton({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                open ? Icons.expand_less : Icons.settings,
                color: colors.text,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Configurações',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaisOpcoesPanel extends StatelessWidget {
  final int levelIndex;
  final int adaptationIndex;
  final int questions;
  final bool includeAnswerKey;
  final List<String> levels;
  final List<String> adaptations;
  final ValueChanged<int> onLevelSelected;
  final ValueChanged<int> onAdaptationSelected;
  final ValueChanged<int> onQuestionsChanged;
  final ValueChanged<bool> onAnswerKeyChanged;

  const _MaisOpcoesPanel({
    required this.levelIndex,
    required this.adaptationIndex,
    required this.questions,
    required this.includeAnswerKey,
    required this.levels,
    required this.adaptations,
    required this.onLevelSelected,
    required this.onAdaptationSelected,
    required this.onQuestionsChanged,
    required this.onAnswerKeyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Rotulo(text: 'Nível', isRequired: false),
          const SizedBox(height: 8),
          SeletorChip(
            labels: levels,
            selectedIndex: levelIndex,
            onSelected: onLevelSelected,
          ),
          const SizedBox(height: 14),
          const _Rotulo(text: 'Adaptar para', isRequired: false),
          const SizedBox(height: 8),
          SeletorChip(
            labels: adaptations,
            selectedIndex: adaptationIndex,
            onSelected: onAdaptationSelected,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantidade de questões',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              NumeracaoStepper(
                value: questions,
                min: 1,
                max: 30,
                onChanged: onQuestionsChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Incluir gabarito',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              Switch(value: includeAnswerKey, onChanged: onAnswerKeyChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarraGeracaoFixa extends StatelessWidget {
  final bool enabled;
  final String label;
  final String? helper;
  final VoidCallback onTap;

  const _BarraGeracaoFixa({
    required this.enabled,
    required this.label,
    this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final disabledBackground = isLight
        ? const Color(0xFFD5DAD8)
        : colors.surfaceSoft;
    final disabledForeground = isLight ? const Color(0xFF66706C) : colors.dim;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (helper != null) ...[
                Text(
                  helper!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: enabled ? onTap : null,
                child: Container(
                  key: const Key('generate-material-button'),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: enabled ? colors.primary : disabledBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: enabled ? colors.onAccent : disabledForeground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipGrande extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipGrande({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.primary : colors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onAccent : colors.text,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String text;
  final bool isRequired;

  const _Rotulo({required this.text, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: colors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: CoresFolhio.green,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration _decoracaoEntrada(
  BuildContext context,
  String hint, {
  Widget? suffix,
}) {
  final colors = context.folhioColors;
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
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
  );
}
