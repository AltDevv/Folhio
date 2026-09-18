part of 'edit_flows_screen.dart';

class RecortePaginasScreen extends StatefulWidget {
  const RecortePaginasScreen({super.key});

  @override
  State<RecortePaginasScreen> createState() => _RecortePaginasScreenState();
}

class _RecortePaginasScreenState extends State<RecortePaginasScreen> {
  final _viewModel = RecortePaginasViewModel();

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

  Future<void> _selecionarPdfParaRecorte() async {
    final file = await _escolherArquivoPdf();
    if (file == null) return;
    try {
      await _viewModel.selecionarPdf(file);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível ler as páginas. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  Future<void> _recortarPaginas() async {
    if (_viewModel.selectedFile == null || _viewModel.uploadedFile == null) {
      await _selecionarPdfParaRecorte();
      return;
    }
    try {
      final response = await _viewModel.recortarPaginas();
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível recortar as páginas. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final selectedLabel = _viewModel.selectedLabel;
    return FolhioScaffold(
      title: 'Recortar páginas',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            onTap: _viewModel.processing ? null : _selecionarPdfParaRecorte,
            borderColor: _viewModel.selectedFile == null
                ? colors.borderSoft
                : colors.primary,
            child: FaixaArquivos(
              name:
                  _viewModel.selectedFile?.uri.pathSegments.last ??
                  'Selecionar PDF',
              detail: _viewModel.selectedFile == null
                  ? 'Toque para escolher o arquivo'
                  : 'Arquivo pronto para recorte',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selecione as páginas a manter',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_viewModel.selectedPages.length}\nselecionadas',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: CoresFolhio.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var page = 1; page <= _viewModel.pageCount; page++)
                MiniaturaPagina(
                  label: 'p.$page',
                  previewUrl: _viewModel.urlPreviaPagina(page),
                  selected: _viewModel.selectedPages.contains(page),
                  onTap: () => _viewModel.alternarPagina(page),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _viewModel.selecionarTodos,
                  child: const Text('Selec. todas'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _viewModel.limparSelecao,
                  child: const Text('Limpar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FolhioCard(
            child: Text.rich(
              TextSpan(
                text: 'Ordem das páginas selecionadas\n',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: selectedLabel.isEmpty
                        ? 'Nenhuma página selecionada'
                        : selectedLabel,
                    style: const TextStyle(
                      color: CoresFolhio.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AcaoPrincipalButton(
            label: _viewModel.processing
                ? 'Recortando...'
                : 'Recortar e salvar',
            onPressed: _viewModel.processing ? null : _recortarPaginas,
          ),
        ],
      ),
    );
  }
}
