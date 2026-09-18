part of 'tools_flows_screen.dart';

class PlanilhaNotasScreen extends StatefulWidget {
  const PlanilhaNotasScreen({super.key});

  @override
  State<PlanilhaNotasScreen> createState() => _PlanilhaNotasScreenState();
}

class _PlanilhaNotasScreenState extends State<PlanilhaNotasScreen> {
  int _classIndex = 0;
  int _periodIndex = 1;
  int _columnsIndex = 0;
  bool _processing = false;

  Future<void> _gerarPlanilhaNotas() async {
    const classes = ['8º A', '8º B', '7º A'];
    const periods = ['1bim', '2bim', '3bim', '4bim'];
    const models = ['test_work', 'simple_average', 'recovery'];
    setState(() => _processing = true);
    try {
      final response = await FerramentasController(FolhioApiGateway())
          .gerarPlanilhaNotas(
            classId: 'class-$_classIndex',
            className: classes[_classIndex],
            period: periods[_periodIndex],
            model: models[_columnsIndex],
          );
      if (!mounted) return;
      _mostrarResultadoFerramenta(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoFerramenta(
        context,
        'Não foi possível criar a planilha. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Notas e médias',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          const TituloSecao('Turma'),
          SeletorChip(
            labels: const ['8º A', '8º B', '7º A'],
            selectedIndex: _classIndex,
            onSelected: (index) => setState(() => _classIndex = index),
          ),
          const TituloSecao('Bimestre'),
          SeletorChip(
            labels: const ['1º bim.', '2º bim.', '3º bim.', '4º bim.'],
            selectedIndex: _periodIndex,
            onSelected: (index) => setState(() => _periodIndex = index),
          ),
          const TituloSecao('Modelo'),
          SeletorChip(
            labels: const ['Prova + trabalho', 'Média simples', 'Recuperação'],
            selectedIndex: _columnsIndex,
            onSelected: (index) => setState(() => _columnsIndex = index),
          ),
          const SizedBox(height: 14),
          const _PreviaBox(
            title: 'Prévia da planilha',
            lines: [
              'Aluno            Prova   Trabalho   Média',
              'Ana Clara        8,5     9,0        8,8',
              'Bruno Lima       7,0     8,0        7,5',
            ],
          ),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: _processing ? 'Criando...' : 'Criar planilha de notas',
            icon: Icons.table_chart,
            onPressed: _processing ? null : _gerarPlanilhaNotas,
          ),
        ],
      ),
    );
  }
}
