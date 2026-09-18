part of 'edit_flows_screen.dart';

class CabecalhoPdfScreen extends StatefulWidget {
  const CabecalhoPdfScreen({super.key});

  @override
  State<CabecalhoPdfScreen> createState() => _CabecalhoPdfScreenState();
}

class _CabecalhoPdfScreenState extends State<CabecalhoPdfScreen> {
  final _viewModel = CabecalhoPdfViewModel();
  final _schoolController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _teacherController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_aoVisualizacaoModeloAlterado);
    _viewModel.dispose();
    _schoolController.dispose();
    _subjectController.dispose();
    _classController.dispose();
    _teacherController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  Future<void> _adicionarCabecalho() async {
    final file = _viewModel.selectedFile ?? await _escolherArquivoPdf();
    if (file == null) return;
    try {
      final response = await _viewModel.adicionarCabecalho(
        fallbackFile: file,
        schoolName: _schoolController.text,
        subject: _subjectController.text,
        className: _classController.text,
        teacherName: _teacherController.text,
        dateText: _dateController.text,
      );
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível aplicar a identificação. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final preview = [
      _schoolController.text,
      _subjectController.text,
      _classController.text,
      _teacherController.text,
      _dateController.text,
    ].where((part) => part.trim().isNotEmpty).join(' • ');
    return FolhioScaffold(
      title: 'Identificação da atividade',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            onTap: _viewModel.processing
                ? null
                : () async {
                    final file = await _escolherArquivoPdf();
                    if (file != null && mounted) _viewModel.selecionarArquivo(file);
                  },
            borderColor: _viewModel.selectedFile == null
                ? colors.borderSoft
                : colors.primary,
            child: FaixaArquivos(
              name:
                  _viewModel.selectedFile?.uri.pathSegments.last ??
                  'Selecionar PDF',
              detail: _viewModel.selectedFile == null
                  ? 'Toque para escolher o arquivo'
                  : 'Arquivo pronto para identificar',
            ),
          ),
          const TituloSecao('Dados da atividade'),
          _EntradaTextoCard(
            label: 'Escola',
            hint: 'Ex: E.E. Prof. João Silva',
            controller: _schoolController,
            onChanged: () => setState(() {}),
          ),
          _EntradaTextoCard(
            label: 'Disciplina',
            hint: 'Ex: Matemática',
            controller: _subjectController,
            onChanged: () => setState(() {}),
          ),
          _EntradaTextoCard(
            label: 'Turma',
            hint: 'Ex: 8º A',
            controller: _classController,
            onChanged: () => setState(() {}),
          ),
          _EntradaTextoCard(
            label: 'Professor',
            hint: 'Ex: Prof. Vítor',
            controller: _teacherController,
            onChanged: () => setState(() {}),
          ),
          _EntradaTextoCard(
            label: 'Data',
            hint: 'Deixe vazio para linha em branco',
            controller: _dateController,
            onChanged: () => setState(() {}),
          ),
          _AlternanciaCard(
            title: 'Linha para nome do aluno',
            subtitle: 'Adiciona campo no topo da atividade',
            value: _viewModel.showStudentLine,
            onChanged: _viewModel.definirExibicaoLinhaAluno,
          ),
          _AlternanciaCard(
            title: 'Linha para nota',
            subtitle: 'Inclui campo de nota ou conceito',
            value: _viewModel.showGradeLine,
            onChanged: _viewModel.definirExibicaoLinhaNota,
          ),
          _AlternanciaCard(
            title: 'Aplicar em todas as páginas',
            subtitle: 'Repete a identificação no PDF inteiro',
            value: _viewModel.applyToAllPages,
            onChanged: _viewModel.definirAplicacaoEmTodasPaginas,
          ),
          FolhioCard(
            child: _IdentificacaoPreview(
              text: preview.isEmpty
                  ? 'Preencha os dados para montar a prévia.'
                  : preview,
            ),
          ),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: _viewModel.processing
                ? 'Aplicando...'
                : 'Adicionar identificação',
            onPressed: _viewModel.processing ? null : _adicionarCabecalho,
          ),
        ],
      ),
    );
  }
}
