import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../widget/actions.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../../controller/materials/criacao_material_view_model.dart';

class CriacaoMaterialScreen extends StatefulWidget {
  final String materialType;
  final String initialTitle;

  const CriacaoMaterialScreen({
    super.key,
    required this.materialType,
    this.initialTitle = '',
  });

  @override
  State<CriacaoMaterialScreen> createState() => _CriacaoMaterialScreenState();
}

class _CriacaoMaterialScreenState extends State<CriacaoMaterialScreen> {
  late final CriacaoMaterialViewModel _viewModel;
  late final TextEditingController _titleController;
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CriacaoMaterialViewModel(
      initialMaterialType: widget.materialType,
    );
    _titleController = TextEditingController(
      text: widget.initialTitle.isEmpty
          ? _rotuloPorTipo(widget.materialType)
          : widget.initialTitle,
    );
    _instructionsController.text =
        'Leia com atenção e responda às questões propostas.';
    _viewModel.carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _titleController.dispose();
    _teacherController.dispose();
    _classController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _gerar() async {
    final messenger = ScaffoldMessenger.of(context);
    final built = await _viewModel.gerar(
      title: _titleController.text,
      teacherName: _teacherController.text,
      className: _classController.text,
      instructions: _instructionsController.text,
    );
    if (!mounted || built == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('DOCX criado com ${built.questionCount} questão(ões).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return FolhioScaffold(
          title: 'Criar material',
          currentIndex: 1,
          showBack: true,
          body: _viewModel.loading && _viewModel.catalog == null
              ? const Center(child: CircularProgressIndicator())
              : FolhioCorpoPagina(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _CabecalhoMaterial(viewModel: _viewModel),
                    const SizedBox(height: 14),
                    _FormularioMaterial(
                      viewModel: _viewModel,
                      titleController: _titleController,
                      teacherController: _teacherController,
                      classController: _classController,
                      instructionsController: _instructionsController,
                    ),
                    const SizedBox(height: 14),
                    _OpcoesGeracao(viewModel: _viewModel),
                    const SizedBox(height: 14),
                    _ModeloSeletor(viewModel: _viewModel),
                    const SizedBox(height: 16),
                    if (_viewModel.error != null) ...[
                      _ErroIntegrado(message: _viewModel.error!),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _viewModel.canGenerate ? _gerar : null,
                        icon: _viewModel.generating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.description_outlined),
                        label: Text(
                          _viewModel.generating
                              ? 'Gerando DOCX'
                              : 'Gerar DOCX editável',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MateriaisRecentes(viewModel: _viewModel),
                  ],
                ),
        );
      },
    );
  }

  static String _rotuloPorTipo(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('prova')) return 'Prova';
    if (normalized.contains('lista')) return 'Lista de exercícios';
    if (normalized.contains('revis')) return 'Revisão';
    return 'Atividade';
  }
}

class _CabecalhoMaterial extends StatelessWidget {
  final CriacaoMaterialViewModel viewModel;

  const _CabecalhoMaterial({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.all(14),
      color: colors.primary.withValues(alpha: 0.08),
      borderColor: colors.primary.withValues(alpha: 0.28),
      child: Row(
        children: [
          IconeArredondado(
            icon: Icons.auto_awesome,
            color: colors.primary,
            backgroundColor: colors.primary.withValues(alpha: 0.14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Banco de questões + DOCX',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha o recorte do conteúdo e gere um arquivo editável.',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

class _FormularioMaterial extends StatelessWidget {
  final CriacaoMaterialViewModel viewModel;
  final TextEditingController titleController;
  final TextEditingController teacherController;
  final TextEditingController classController;
  final TextEditingController instructionsController;

  const _FormularioMaterial({
    required this.viewModel,
    required this.titleController,
    required this.teacherController,
    required this.classController,
    required this.instructionsController,
  });

  @override
  Widget build(BuildContext context) {
    final catalog = viewModel.catalog;
    return FolhioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RotuloFormulario('Tipo de material'),
          SeletorChip(
            labels: const ['Atividade', 'Prova', 'Lista'],
            selectedIndex: CriacaoMaterialViewModel.materialTypes.indexOf(
              viewModel.materialType,
            ),
            onSelected: (index) {
              viewModel.definirTipoMaterial(
                CriacaoMaterialViewModel.materialTypes[index],
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            decoration: _decoracao(context, 'Título do material'),
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Disciplina',
            value: viewModel.discipline,
            values: catalog?.disciplines ?? const [],
            onChanged: viewModel.definirDisciplina,
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Assunto',
            value: viewModel.subject,
            values: catalog?.subjects ?? const [],
            onChanged: viewModel.definirAssunto,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'Ano',
                  value: viewModel.schoolYear,
                  values: catalog?.schoolYears ?? const [],
                  onChanged: viewModel.definirAnoEscolar,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownField(
                  label: 'Dificuldade',
                  value: viewModel.difficulty,
                  values: catalog?.difficulties ?? const [],
                  onChanged: viewModel.definirDificuldade,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: teacherController,
                  decoration: _decoracao(context, 'Professor(a)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: classController,
                  decoration: _decoracao(context, 'Turma'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: instructionsController,
            minLines: 2,
            maxLines: 4,
            decoration: _decoracao(context, 'Instruções'),
          ),
        ],
      ),
    );
  }
}

class _OpcoesGeracao extends StatelessWidget {
  final CriacaoMaterialViewModel viewModel;

  const _OpcoesGeracao({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantidade',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${viewModel.questionCount} questões no material',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              NumeracaoStepper(
                value: viewModel.questionCount,
                min: 1,
                max: 30,
                onChanged: viewModel.definirQuantidadeQuestoes,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: viewModel.includeAnswerKey,
            onChanged: viewModel.definirInclusaoGabarito,
            title: const Text('Incluir gabarito'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: viewModel.shuffleQuestions,
            onChanged: viewModel.definirEmbaralharQuestoes,
            title: const Text('Embaralhar questões'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: viewModel.shuffleOptions,
            onChanged: viewModel.definirEmbaralharOpcoes,
            title: const Text('Embaralhar alternativas'),
          ),
        ],
      ),
    );
  }
}

class _ModeloSeletor extends StatelessWidget {
  final CriacaoMaterialViewModel viewModel;

  const _ModeloSeletor({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    if (viewModel.templates.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RotuloFormulario('Modelo DOCX'),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = viewModel.templates[index];
              final selected = template.id == viewModel.templateId;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => viewModel.definirModelo(template.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 190,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 11),
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

class _MateriaisRecentes extends StatelessWidget {
  final CriacaoMaterialViewModel viewModel;

  const _MateriaisRecentes({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.recent.isEmpty) return const SizedBox.shrink();
    final colors = context.folhioColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RotuloFormulario('Gerados recentemente'),
        for (final material in viewModel.recent.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FolhioCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconeArredondado(
                    icon: Icons.description_outlined,
                    color: colors.primary,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${material.questionCount} questões • ${material.fileName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValues = values
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    final selected = cleanValues.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$selected-${cleanValues.length}'),
      initialValue: selected,
      isExpanded: true,
      decoration: _decoracao(context, label),
      items: [
        for (final item in cleanValues)
          DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _RotuloFormulario extends StatelessWidget {
  final String text;

  const _RotuloFormulario(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ErroIntegrado extends StatelessWidget {
  final String message;

  const _ErroIntegrado({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoresFolhio.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoresFolhio.coral.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: CoresFolhio.coral,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

InputDecoration _decoracao(BuildContext context, String label) {
  final colors = context.folhioColors;
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: colors.input,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.primary, width: 1.4),
    ),
  );
}
