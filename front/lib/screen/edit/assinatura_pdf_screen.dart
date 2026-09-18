part of 'edit_flows_screen.dart';

Future<File?> _escolherImagemAssinatura() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg'],
  );
  final path = result?.files.single.path;
  return path == null ? null : File(path);
}

class AssinaturaPdfScreen extends StatefulWidget {
  const AssinaturaPdfScreen({super.key});

  @override
  State<AssinaturaPdfScreen> createState() => _AssinaturaPdfScreenState();
}

class _AssinaturaPdfScreenState extends State<AssinaturaPdfScreen> {
  final _viewModel = AssinaturaPdfViewModel();

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

  Future<void> _selecionarAssinatura() async {
    final file = await _escolherImagemAssinatura();
    if (file == null) return;
    _viewModel.selecionarImagemAssinatura(file);
  }

  Future<void> _adicionarAssinatura() async {
    try {
      if (_viewModel.selectedFile == null) {
        await _selecionarPdf();
        if (_viewModel.selectedFile == null) return;
      }
      if (_viewModel.signatureImage == null) {
        await _selecionarAssinatura();
        if (_viewModel.signatureImage == null) return;
      }
      final response = await _viewModel.adicionarAssinatura();
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível adicionar a assinatura. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioScaffold(
      title: 'Assinar PDF',
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
              detail: _viewModel.selectedFile == null
                  ? 'Escolha o documento'
                  : 'PDF pronto para assinar',
            ),
          ),
          FolhioCard(
            onTap: _viewModel.processing ? null : _selecionarAssinatura,
            borderColor: _viewModel.signatureImage == null
                ? colors.borderSoft
                : colors.primary,
            child: FaixaArquivos(
              name:
                  _viewModel.signatureImage?.uri.pathSegments.last ??
                  'Selecionar assinatura',
              detail: 'PNG ou JPG com fundo transparente funciona melhor',
            ),
          ),
          PosicionamentoAssinaturaPreview(
            pdfPreviewUrl: _viewModel.pdfPreviewUrl,
            pageWidth: _viewModel.uploadedPdf?.pageWidth,
            pageHeight: _viewModel.uploadedPdf?.pageHeight,
            signatureImage: _viewModel.signatureImage,
            xRatio: _viewModel.signatureX,
            yRatio: _viewModel.signatureY,
            widthRatio: _viewModel.signatureWidth,
            onMoved: _viewModel.definirPosicaoAssinatura,
          ),
          FolhioCard(
            child: _LinhaIncremento(
              title: 'Largura da assinatura',
              subtitle: 'Ajuste em relação à largura da página',
              value: (_viewModel.signatureWidth * 100).round(),
              min: 8,
              max: 60,
              onChanged: _viewModel.definirPercentualLarguraAssinatura,
            ),
          ),
          _AlternanciaCard(
            title: 'Aplicar em todas as páginas',
            subtitle: 'Repete a assinatura em todo o documento',
            value: _viewModel.applyToAllPages,
            onChanged: _viewModel.definirAplicacaoEmTodasPaginas,
          ),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: _viewModel.processing
                ? 'Aplicando...'
                : 'Adicionar assinatura',
            onPressed: _viewModel.processing ? null : _adicionarAssinatura,
          ),
        ],
      ),
    );
  }
}
