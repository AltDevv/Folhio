part of 'tools_flows_screen.dart';

class ComunicadoIndividualScreen extends StatefulWidget {
  const ComunicadoIndividualScreen({super.key});

  @override
  State<ComunicadoIndividualScreen> createState() => _ComunicadoIndividualScreenState();
}

class _ComunicadoIndividualScreenState extends State<ComunicadoIndividualScreen> {
  final _repository = PersistenciaLocalRepository.instance;
  final _messageController = TextEditingController(
    text:
        'Olá, família. Segue um comunicado importante sobre a rotina da turma.',
  );
  List<SchoolClass> _classes = const [];
  List<Student> _students = const [];
  int _classIndex = 0;
  int _templateIndex = 0;
  int _audienceIndex = 0;
  bool _includeSignature = true;
  bool _processing = false;
  bool _loading = true;

  SchoolClass? get _selectedClass {
    if (_classes.isEmpty) return null;
    return _classes[_classIndex.clamp(0, _classes.length - 1)];
  }

  List<String> get _templates => const [
    'Olá, família. Segue um comunicado importante sobre a rotina da turma.',
    'O estudante precisa reforçar os estudos nesta semana. Conto com o acompanhamento em casa.',
    'Parabéns pelo desempenho e pela participação nas atividades recentes.',
    'Lembramos que há atividade pendente para entregar na próxima aula.',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
    setState(() {
      _classes = classes;
      _classIndex = nextClassIndex;
      _students = students.where((student) => student.active).toList();
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
      _students = students.where((student) => student.active).toList();
      _loading = false;
    });
  }

  void _selecionarModelo(int index) {
    setState(() {
      _templateIndex = index;
      _messageController.text = _templates[index];
    });
  }

  Future<void> _gerarComunicados() async {
    final selected = _selectedClass;
    if (selected == null) return;
    setState(() => _processing = true);
    try {
      final response = await FerramentasController(FolhioApiGateway())
          .gerarComunicadosIndividuais(
            classId: selected.id,
            className: selected.name,
            messageTemplate: _messageController.text.trim(),
            includeResponsibleSignature: _includeSignature,
          );
      if (!mounted) return;
      _mostrarResultadoFerramenta(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoFerramenta(
        context,
        'Não foi possível gerar os comunicados. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedClass;
    final audienceLabel = _audienceIndex == 0
        ? '${_students.length} alunos'
        : '1 aluno por vez';
    return FolhioScaffold(
      title: 'Comunicados',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          _FerramentaDestaqueCard(
            icon: Icons.campaign_outlined,
            title: 'Bilhetes para famílias',
            subtitle:
                'Monte comunicados rápidos com turma, mensagem e campo de assinatura.',
            actionLabel: _processing ? 'Gerando...' : 'Gerar comunicados',
            onAction: _processing || _classes.isEmpty ? null : _gerarComunicados,
          ),
          if (_classes.isEmpty)
            const _FerramentaVaziaState(
              icon: Icons.dashboard_customize_outlined,
              title: 'Crie um espaço primeiro',
              subtitle: 'Os comunicados usam as turmas salvas no app.',
            )
          else ...[
            const TituloSecao('Turma'),
            _SeletorTurma(
              classes: _classes,
              selectedIndex: _classIndex,
              onSelected: _selecionarTurma,
            ),
            const TituloSecao('Destinatários'),
            SeletorChip(
              labels: const ['Turma inteira', 'Individual'],
              selectedIndex: _audienceIndex,
              onSelected: (index) => setState(() => _audienceIndex = index),
            ),
            const TituloSecao('Modelo'),
            SeletorChip(
              labels: const ['Geral', 'Reforço', 'Parabéns', 'Pendência'],
              selectedIndex: _templateIndex,
              onSelected: _selecionarModelo,
            ),
            const SizedBox(height: 12),
            _CampoTextoFerramenta(
              label: 'Mensagem',
              hint: 'Escreva o comunicado',
              controller: _messageController,
              maxLines: 5,
              onChanged: () => setState(() {}),
            ),
            _LinhaAlternancia(
              title: 'Assinatura do responsável',
              subtitle: 'Adiciona um campo para devolução assinada',
              value: _includeSignature,
              onChanged: (value) => setState(() => _includeSignature = value),
            ),
            const TituloSecao('Prévia'),
            if (_loading)
              const _FerramentaVaziaState(
                icon: Icons.sync,
                title: 'Carregando alunos...',
                subtitle: '',
              )
            else
              _ComunicadoPreview(
                className: selected?.name ?? 'Turma',
                audience: audienceLabel,
                firstStudent: _students.isEmpty ? null : _students.first.name,
                message: _messageController.text.trim(),
                includeSignature: _includeSignature,
              ),
            const SizedBox(height: 14),
            AcaoPrincipalButton(
              label: _processing ? 'Gerando...' : 'Gerar PDF',
              icon: Icons.picture_as_pdf,
              onPressed: _processing || _messageController.text.trim().isEmpty
                  ? null
                  : _gerarComunicados,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComunicadoPreview extends StatelessWidget {
  final String className;
  final String audience;
  final String? firstStudent;
  final String message;
  final bool includeSignature;

  const _ComunicadoPreview({
    required this.className,
    required this.audience,
    required this.firstStudent,
    required this.message,
    required this.includeSignature,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeArredondado(
                icon: Icons.mail_outline,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comunicado escolar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$className · $audience',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Aluno: ${firstStudent ?? 'Nome do aluno'}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message.isEmpty ? 'Sua mensagem aparece aqui.' : message,
            style: TextStyle(
              color: colors.text,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (includeSignature) ...[
            const SizedBox(height: 14),
            Text(
              'Assinatura: __________________________',
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
