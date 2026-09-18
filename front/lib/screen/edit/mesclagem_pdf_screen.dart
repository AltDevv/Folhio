part of 'edit_flows_screen.dart';

class MesclagemPdfScreen extends StatefulWidget {
  const MesclagemPdfScreen({super.key});

  @override
  State<MesclagemPdfScreen> createState() => _MesclagemPdfScreenState();
}

class _MesclagemPdfScreenState extends State<MesclagemPdfScreen> {
  final _viewModel = MesclagemPdfViewModel();

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

  Future<void> _adicionarArquivos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final paths =
        result?.files.map((file) => file.path).whereType<String>().toList() ??
        [];
    if (paths.isEmpty) return;
    _viewModel.adicionarArquivos(paths.map(File.new).toList());
  }

  Future<void> _mesclarArquivos() async {
    if (!_viewModel.hasFiles) {
      await _adicionarArquivos();
      return;
    }
    try {
      final response = await _viewModel.mesclarArquivos();
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível juntar os arquivos. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioScaffold(
      title: 'Mesclar PDFs',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          Text(
            'Arraste para definir a ordem final dos arquivos.',
            style: TextStyle(
              color: colors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _viewModel.files.length,
            onReorderItem: _viewModel.processing
                ? (_, _) {}
                : _viewModel.reordenarArquivos,
            itemBuilder: (context, index) {
              final file = _viewModel.files[index];
              return _ItemMesclagem(
                key: ValueKey(file.path),
                order: '${index + 1}',
                name: file.uri.pathSegments.last,
                detail: 'PDF selecionado',
                selected: _viewModel.selectedFile == index,
                dragIndex: index,
                onTap: () => _viewModel.selecionarArquivo(index),
              );
            },
          ),
          const SizedBox(height: 12),
          FolhioCard(
            onTap: _viewModel.processing ? null : _adicionarArquivos,
            borderColor: colors.border,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: CoresFolhio.green),
                SizedBox(width: 8),
                Text(
                  'Adicionar arquivo',
                  style: TextStyle(
                    color: CoresFolhio.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FolhioCard(
            child: Text.rich(
              TextSpan(
                text: 'Resultado final\n',
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: _viewModel.resultSummary,
                    style: const TextStyle(
                      color: CoresFolhio.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AcaoPrincipalButton(
            label: _viewModel.processing ? 'Mesclando...' : 'Mesclar arquivos',
            onPressed: _viewModel.processing ? null : _mesclarArquivos,
          ),
        ],
      ),
    );
  }
}
