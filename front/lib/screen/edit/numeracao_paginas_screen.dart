part of 'edit_flows_screen.dart';

class NumeracaoPaginasScreen extends StatefulWidget {
  const NumeracaoPaginasScreen({super.key});

  @override
  State<NumeracaoPaginasScreen> createState() => _NumeracaoPaginasScreenState();
}

class _NumeracaoPaginasScreenState extends State<NumeracaoPaginasScreen> {
  final _viewModel = NumeracaoPaginasViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_aoVisualizacaoModeloAlterado);
    _viewModel.dispose();
    super.dispose();
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  Future<void> _selecionarPdf() async {
    final file = await _escolherArquivoPdf();
    if (file == null) return;
    try {
      await _viewModel.selecionarPdf(file);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(context, FolhioApiGateway.humanizarErro(error), null);
    }
  }

  Future<void> _numerarPaginas() async {
    final file = _viewModel.selectedFile ?? await _escolherArquivoPdf();
    if (file == null) return;
    try {
      final response = await _viewModel.numerarPaginas(fallbackFile: file);
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível numerar as páginas. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioScaffold(
      title: 'Numerar páginas',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            onTap: _viewModel.processing ? null : _selecionarPdf,
            borderColor: _viewModel.selectedFile == null
                ? colors.borderSoft
                : colors.primary,
            child: FaixaArquivos(
              name:
                  _viewModel.selectedFile?.uri.pathSegments.last ??
                  'Selecionar PDF',
              detail: 'Páginas detectadas: ${_viewModel.pageCount}',
            ),
          ),
          const TituloSecao('Posição'),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              for (var i = 0; i < NumeracaoPaginasViewModel.positions.length; i++)
                _EscolhaPosicao(
                  label: const [
                    'Rodapé centro',
                    'Rodapé direita',
                    'Rodapé esquerda',
                    'Topo centro',
                    'Topo direita',
                    'Topo esquerda',
                  ][i],
                  selected: _viewModel.positionIndex == i,
                  onTap: () => _viewModel.definirIndicePosicao(i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FolhioCard(
            child: Column(
              children: [
                _LinhaIncremento(
                  title: 'Começar na página',
                  subtitle: 'Página física do PDF',
                  value: _viewModel.startPage,
                  min: 1,
                  max: _viewModel.pageCount,
                  onChanged: _viewModel.definirPaginaInicial,
                ),
                const Divider(),
                _LinhaIncremento(
                  title: 'Primeiro número',
                  subtitle: 'Número impresso inicial',
                  value: _viewModel.firstNumber,
                  min: 1,
                  max: 999,
                  onChanged: _viewModel.definirNumeroInicial,
                ),
              ],
            ),
          ),
          const TituloSecao('Formato'),
          SeletorChip(
            labels: const ['1', '1/10', 'Página 1'],
            selectedIndex: _viewModel.formatIndex,
            onSelected: _viewModel.definirIndiceFormato,
          ),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: _viewModel.processing ? 'Numerando...' : 'Aplicar numeração',
            onPressed: _viewModel.processing ? null : _numerarPaginas,
          ),
        ],
      ),
    );
  }
}
