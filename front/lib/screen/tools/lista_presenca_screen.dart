part of 'tools_flows_screen.dart';

class ListaPresencaScreen extends StatefulWidget {
  const ListaPresencaScreen({super.key});

  @override
  State<ListaPresencaScreen> createState() => _ListaPresencaScreenState();
}

class _ListaPresencaScreenState extends State<ListaPresencaScreen> {
  final _repository = PersistenciaLocalRepository.instance;
  List<SchoolClass> _classes = const [];
  List<Student> _students = const [];
  Map<String, bool> _presentByStudentId = const {};
  int _classIndex = 0;
  int _dateIndex = 0;
  bool _includeSignature = true;
  bool _includeObservations = true;
  bool _processing = false;
  bool _loading = true;

  SchoolClass? get _selectedClass {
    if (_classes.isEmpty) return null;
    return _classes[_classIndex.clamp(0, _classes.length - 1)];
  }

  int get _presentCount => _students
      .where((student) => _presentByStudentId[student.id] ?? true)
      .length;

  int get _absentCount => _students.length - _presentCount;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final classes = await _repository.listarTurmas();
    var nextClassIndex = _classIndex;
    if (nextClassIndex >= classes.length) nextClassIndex = 0;
    final students = classes.isEmpty
        ? <Student>[]
        : await _repository.listarAlunos(classes[nextClassIndex].id);
    if (!mounted) return;
    final activeStudents = students.where((student) => student.active).toList();
    setState(() {
      _classes = classes;
      _classIndex = nextClassIndex;
      _students = activeStudents;
      _presentByStudentId = {
        for (final student in activeStudents)
          student.id: _presentByStudentId[student.id] ?? true,
      };
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
    final activeStudents = students.where((student) => student.active).toList();
    setState(() {
      _students = activeStudents;
      _presentByStudentId = {
        for (final student in activeStudents) student.id: true,
      };
      _loading = false;
    });
  }

  void _alternarPresenca(Student student) {
    setState(() {
      _presentByStudentId = {
        ..._presentByStudentId,
        student.id: !(_presentByStudentId[student.id] ?? true),
      };
    });
  }

  Future<void> _gerarListaPresenca() async {
    final selected = _selectedClass;
    if (selected == null) return;
    const dates = ['today', 'tomorrow', 'custom'];
    setState(() => _processing = true);
    try {
      final response = await FerramentasController(FolhioApiGateway())
          .gerarListaPresenca(
            classId: selected.id,
            className: selected.name,
            dateMode: dates[_dateIndex],
            includeTeacherSignature: _includeSignature,
            includeObservations: _includeObservations,
            students: [
              for (final student in _students)
                {
                  'id': student.id,
                  'name': student.name,
                  'registration': student.registration,
                  'status': (_presentByStudentId[student.id] ?? true)
                      ? 'present'
                      : 'absent',
                },
            ],
          );
      if (!mounted) return;
      _mostrarResultadoFerramenta(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoFerramenta(
        context,
        'Não foi possível gerar a chamada. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _abrirAlunos() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ListaAlunosScreen()));
    if (mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedClass;
    return FolhioScaffold(
      title: 'Chamada e presença',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          _FerramentaDestaqueCard(
            icon: Icons.fact_check_outlined,
            title: 'Presença pronta para aula',
            subtitle:
                'Escolha uma turma da lista de alunos e marque a presença de cada estudante.',
            actionLabel: 'Editar lista de alunos',
            onAction: _abrirAlunos,
          ),
          if (_classes.isEmpty)
            const _FerramentaVaziaState(
              icon: Icons.groups_2_outlined,
              title: 'Nenhuma turma cadastrada',
              subtitle:
                  'Crie uma turma na lista de alunos e adicione estudantes para fazer a chamada.',
            )
          else ...[
            const TituloSecao('Turmas'),
            _ListaTurmasPresenca(
              classes: _classes,
              studentsCount: _students.length,
              selectedIndex: _classIndex,
              onSelected: _selecionarTurma,
            ),
            const SizedBox(height: 12),
            _LinhaEstatisticasFerramenta(
              items: [
                _ItemEstatisticaFerramenta(
                  icon: Icons.groups_2_outlined,
                  label: 'Alunos',
                  value: '${_students.length}',
                ),
                _ItemEstatisticaFerramenta(
                  icon: Icons.check_circle_outline,
                  label: 'Presentes',
                  value: '$_presentCount',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LinhaEstatisticasFerramenta(
              items: [
                _ItemEstatisticaFerramenta(
                  icon: Icons.cancel_outlined,
                  label: 'Faltas',
                  value: '$_absentCount',
                ),
                _ItemEstatisticaFerramenta(
                  icon: Icons.event_available_outlined,
                  label: 'Data',
                  value: const ['Hoje', 'Amanhã', 'Livre'][_dateIndex],
                ),
              ],
            ),
            const TituloSecao('Data'),
            SeletorChip(
              labels: const ['Hoje', 'Amanhã', 'Personalizada'],
              selectedIndex: _dateIndex,
              onSelected: (index) => setState(() => _dateIndex = index),
            ),
            const TituloSecao('Alunos'),
            if (_loading)
              const _FerramentaVaziaState(
                icon: Icons.sync,
                title: 'Carregando alunos...',
                subtitle: '',
              )
            else if (_students.isEmpty)
              _FerramentaVaziaState(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Lista vazia',
                subtitle:
                    'Cadastre os alunos de ${selected?.name ?? 'uma turma'} antes de fazer a chamada.',
              )
            else
              for (final (index, student) in _students.indexed)
                _AlunoPresencaTile(
                  number: index + 1,
                  student: student,
                  present: _presentByStudentId[student.id] ?? true,
                  onToggle: () => _alternarPresenca(student),
                ),
            const TituloSecao('Campos da folha'),
            _LinhaAlternancia(
              title: 'Assinatura do professor',
              subtitle: 'Inclui uma linha ao final da chamada',
              value: _includeSignature,
              onChanged: (value) => setState(() => _includeSignature = value),
            ),
            _LinhaAlternancia(
              title: 'Observações',
              subtitle: 'Espaço para justificativas e recados rápidos',
              value: _includeObservations,
              onChanged: (value) =>
                  setState(() => _includeObservations = value),
            ),
            const SizedBox(height: 14),
            AcaoPrincipalButton(
              label: _processing ? 'Gerando...' : 'Gerar chamada em PDF',
              icon: Icons.picture_as_pdf,
              onPressed: _processing || _students.isEmpty
                  ? null
                  : _gerarListaPresenca,
            ),
          ],
        ],
      ),
    );
  }
}

class _ListaTurmasPresenca extends StatelessWidget {
  final List<SchoolClass> classes;
  final int studentsCount;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ListaTurmasPresenca({
    required this.classes,
    required this.studentsCount,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Column(
      children: [
        for (final (index, schoolClass) in classes.indexed)
          FolhioCard(
            onTap: () => onSelected(index),
            borderColor: index == selectedIndex
                ? colors.primary
                : colors.borderSoft,
            color: index == selectedIndex
                ? colors.primary.withValues(alpha: 0.10)
                : null,
            child: Row(
              children: [
                IconeArredondado(
                  icon: Icons.groups_2_outlined,
                  color: index == selectedIndex ? colors.primary : colors.muted,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolClass.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _detalhesTurma(schoolClass),
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
                if (index == selectedIndex)
                  StatusPill(label: '$studentsCount alunos')
                else
                  Icon(Icons.chevron_right, color: colors.muted),
              ],
            ),
          ),
      ],
    );
  }

  String _detalhesTurma(SchoolClass schoolClass) {
    final parts = [
      schoolClass.schoolYear,
      schoolClass.subject,
      schoolClass.shift,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Turma cadastrada' : parts.join(' - ');
  }
}

class _AlunoPresencaTile extends StatelessWidget {
  final int number;
  final Student student;
  final bool present;
  final VoidCallback onToggle;

  const _AlunoPresencaTile({
    required this.number,
    required this.student,
    required this.present,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final statusColor = present ? colors.primary : const Color(0xFFE15B5B);
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withValues(alpha: 0.14),
            child: Text(
              '$number',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onToggle,
            icon: Icon(
              present ? Icons.check_circle : Icons.cancel_outlined,
              size: 18,
            ),
            label: Text(present ? 'Presente' : 'Falta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: statusColor,
              side: BorderSide(color: statusColor.withValues(alpha: 0.55)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
