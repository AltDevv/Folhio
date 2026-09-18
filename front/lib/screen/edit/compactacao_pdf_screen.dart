part of 'edit_flows_screen.dart';

class CompactacaoPdfScreen extends StatefulWidget {
  const CompactacaoPdfScreen({super.key});

  @override
  State<CompactacaoPdfScreen> createState() => _CompactacaoPdfScreenState();
}

class _CompactacaoPdfScreenState extends State<CompactacaoPdfScreen> {
  final _viewModel = CompactacaoPdfViewModel();

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

  Future<void> _compactar() async {
    final file = _viewModel.selectedFile ?? await _escolherArquivoPdf();
    if (file == null) return;
    try {
      final response = await _viewModel.compactar(fallbackFile: file);
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível comprimir o arquivo. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioScaffold(
      title: 'Comprimir PDF',
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
                  : 'Arquivo pronto para compactar',
            ),
          ),
          const TituloSecao('Nível de compressão'),
          Row(
            children: [
              for (
                var index = 0;
                index < CompactacaoPdfViewModel.levels.length;
                index++
              ) ...[
                Expanded(
                  child: _EscolhaCompactacao(
                    title: const ['Leve', 'Médio', 'Forte'][index],
                    detail: CompactacaoPdfViewModel.compressionDetails[index],
                    selected: _viewModel.compressionIndex == index,
                    onTap: () => _viewModel.definirIndiceCompactacao(index),
                  ),
                ),
                if (index < CompactacaoPdfViewModel.levels.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FolhioCard(
            child: Row(
              children: [
                const Expanded(
                  child: _Metrica(label: 'Antes', value: 'Original'),
                ),
                Icon(Icons.arrow_forward, color: colors.dim),
                Expanded(
                  child: _Metrica(
                    label: 'Depois',
                    value: _viewModel.estimatedSize,
                  ),
                ),
                StatusPill(
                  label: _viewModel.reductionLabel,
                  tone: TomIndicador.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AcaoPrincipalButton(
            label: _viewModel.processing
                ? 'Comprimindo...'
                : 'Comprimir arquivo',
            onPressed: _viewModel.processing ? null : _compactar,
          ),
        ],
      ),
    );
  }
}
