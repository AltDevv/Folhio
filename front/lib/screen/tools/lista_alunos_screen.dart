part of 'tools_flows_screen.dart';

class ListaAlunosScreen extends StatefulWidget {
  const ListaAlunosScreen({super.key});

  @override
  State<ListaAlunosScreen> createState() => _ListaAlunosScreenState();
}

class _ListaAlunosScreenState extends State<ListaAlunosScreen> {
  final _repository = PersistenciaLocalRepository.instance;
  final _searchController = TextEditingController();
  List<SchoolClass> _classes = const [];
  List<Student> _students = const [];
  int _classIndex = 0;
  bool _loading = true;

  SchoolClass? get _selectedClass {
    if (_classes.isEmpty) return null;
    return _classes[_classIndex.clamp(0, _classes.length - 1)];
  }

  List<Student> get _visibleStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students
        .where(
          (student) =>
              student.name.toLowerCase().contains(query) ||
              student.registration.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _adicionarTurma() async {
    var name = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova turma'),
        content: TextField(
          onChanged: (value) => name = value,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Nome da turma'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (name.trim().isNotEmpty) {
                Navigator.pop(context, name.trim());
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      await _repository.salvarTurma(name: result);
      if (mounted) await _carregar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a turma.')),
        );
      }
    }
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final classes = await _repository.listarTurmas();
    if (!mounted) return;
    var nextClassIndex = _classIndex;
    if (classes.isEmpty) {
      setState(() {
        _classes = classes;
        _students = const [];
        _loading = false;
      });
      return;
    }
    if (nextClassIndex >= classes.length) nextClassIndex = 0;
    final students = await _repository.listarAlunos(classes[nextClassIndex].id);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _classIndex = nextClassIndex;
      _students = students;
      _loading = false;
    });
  }

  Future<void> _selecionarTurma(int index) async {
    setState(() {
      _classIndex = index;
      _loading = true;
    });
    final selected = _selectedClass;
    if (selected == null) return;
    final students = await _repository.listarAlunos(selected.id);
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  Future<void> _adicionarAluno() async {
    final selected = _selectedClass;
    if (selected == null) return;
    final data = await _mostrarEditorAluno(context);
    if (data == null) return;
    await _repository.salvarAluno(
      classId: selected.id,
      name: data.name,
      registration: data.registration,
    );
    await _carregar();
  }

  Future<void> _editarAluno(Student student) async {
    final selected = _selectedClass;
    if (selected == null) return;
    final data = await _mostrarEditorAluno(context, student: student);
    if (data == null) return;
    await _repository.salvarAluno(
      id: student.id,
      classId: selected.id,
      name: data.name,
      registration: data.registration,
      active: student.active,
    );
    await _carregar();
  }

  Future<void> _excluirAluno(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover aluno?'),
        content: Text('Isso remove "${student.name}" desta lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.excluirAluno(student.id);
    await _carregar();
  }

  Future<void> _adicionarEmLote() async {
    final selected = _selectedClass;
    if (selected == null) return;
    final names = await _mostrarEditorAlunosLote(context);
    if (names.isEmpty) return;
    for (final name in names) {
      await _repository.salvarAluno(classId: selected.id, name: name);
    }
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedClass;
    final visible = _visibleStudents;
    return FolhioScaffold(
      title: 'Lista de alunos',
      currentIndex: 3,
      showBack: true,
      actions: [
        IconButton(
          tooltip: 'Adicionar turma',
          onPressed: _adicionarTurma,
          icon: const Icon(Icons.group_add_outlined),
        ),
      ],
      body: FolhioCorpoPagina(
        children: [
          _FerramentaDestaqueCard(
            icon: Icons.groups_2_outlined,
            title: 'Base da sala de aula',
            subtitle:
                'Cadastre os alunos uma vez e use a lista em chamadas, comunicados e materiais.',
            actionLabel: 'Adicionar aluno',
            onAction: selected == null ? null : _adicionarAluno,
          ),
          if (_classes.isEmpty)
            const _FerramentaVaziaState(
              icon: Icons.dashboard_customize_outlined,
              title: 'Nenhuma turma cadastrada',
              subtitle: 'Cadastre uma turma para organizar seus alunos.',
            )
          else ...[
            const TituloSecao('Turma'),
            _SeletorTurma(
              classes: _classes,
              selectedIndex: _classIndex,
              onSelected: _selecionarTurma,
            ),
            const SizedBox(height: 12),
            _LinhaEstatisticasFerramenta(
              items: [
                _ItemEstatisticaFerramenta(
                  icon: Icons.person_outline,
                  label: 'Alunos',
                  value: '${_students.length}',
                ),
                _ItemEstatisticaFerramenta(
                  icon: Icons.check_circle_outline,
                  label: 'Ativos',
                  value: '${_students.where((s) => s.active).length}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CampoBuscaFerramentas(
              controller: _searchController,
              hint: 'Buscar aluno ou matrícula',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AcaoPrincipalButton(
                    label: 'Adicionar em lote',
                    icon: Icons.playlist_add,
                    onPressed: _adicionarEmLote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const TituloSecao('Alunos'),
            if (_loading)
              const _FerramentaVaziaState(
                icon: Icons.sync,
                title: 'Carregando lista...',
                subtitle: '',
              )
            else if (visible.isEmpty)
              _FerramentaVaziaState(
                icon: Icons.person_add_alt_1_outlined,
                title: _students.isEmpty
                    ? 'Nenhum aluno cadastrado'
                    : 'Nenhum aluno encontrado',
                subtitle: _students.isEmpty
                    ? 'Adicione os alunos para deixar a chamada pronta.'
                    : 'Tente buscar por outro nome ou matrícula.',
              )
            else
              for (final (index, student) in visible.indexed)
                _AlunoTile(
                  number: index + 1,
                  student: student,
                  onEdit: () => _editarAluno(student),
                  onDelete: () => _excluirAluno(student),
                ),
          ],
        ],
      ),
    );
  }
}

class _DadosFormularioAluno {
  final String name;
  final String registration;

  const _DadosFormularioAluno({required this.name, required this.registration});
}

Future<_DadosFormularioAluno?> _mostrarEditorAluno(
  BuildContext context, {
  Student? student,
}) {
  final nameController = TextEditingController(text: student?.name ?? '');
  final registrationController = TextEditingController(
    text: student?.registration ?? '',
  );
  return showModalBottomSheet<_DadosFormularioAluno>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student == null ? 'Adicionar aluno' : 'Editar aluno',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _CampoTextoFerramenta(
              label: 'Nome',
              hint: 'Ex: Ana Clara',
              controller: nameController,
            ),
            _CampoTextoFerramenta(
              label: 'Matrícula ou número',
              hint: 'Opcional',
              controller: registrationController,
            ),
            AcaoPrincipalButton(
              label: 'Salvar aluno',
              icon: Icons.check,
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  context,
                  _DadosFormularioAluno(
                    name: name,
                    registration: registrationController.text.trim(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<List<String>> _mostrarEditorAlunosLote(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar em lote',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Cole um nome por linha.',
              style: TextStyle(color: context.folhioColors.muted),
            ),
            const SizedBox(height: 14),
            _CampoTextoFerramenta(
              label: 'Alunos',
              hint: 'Ana Clara\nBruno Lima\nCarla Souza',
              controller: controller,
              maxLines: 8,
            ),
            AcaoPrincipalButton(
              label: 'Adicionar lista',
              icon: Icons.playlist_add_check,
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        ),
      );
    },
  );
  if (result == null) return const [];
  return result
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toSet()
      .toList();
}
