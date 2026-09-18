part of 'tools_flows_screen.dart';

class CarimboPdfScreen extends StatefulWidget {
  const CarimboPdfScreen({super.key});

  @override
  State<CarimboPdfScreen> createState() => _CarimboPdfScreenState();
}

class _CarimboPdfScreenState extends State<CarimboPdfScreen> {
  final _api = FolhioApiGateway();
  late final _controller = FerramentasController(_api);
  final List<PlatformFile> _documents = [];
  PlatformFile? _signature;
  Offset _position = const Offset(0.58, 0.70);
  double _width = 0.26;
  bool _loading = false;

  Future<void> _escolherDocumentos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _documents
        ..clear()
        ..addAll(result.files.where((file) => file.path != null));
    });
  }

  Future<void> _escolherAssinatura() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _signature = result.files.first);
  }

  Future<void> _aplicarCarimbo() async {
    final signature = _signature;
    if (_documents.isEmpty || signature?.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha os documentos e a assinatura em PNG.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uploadedDocuments = <Map<String, dynamic>>[];
      for (final file in _documents) {
        final path = file.path;
        if (path == null) continue;
        final uploaded = await _api.enviarArquivo(
          File(path),
          fileName: file.name,
          keepProgress: true,
          persistent: true,
        );
        uploadedDocuments.add(_dadosArquivoEnviado(uploaded));
      }

      final uploadedSignature = await _api.enviarArquivo(
        File(signature!.path!),
        fileName: signature.name,
        keepProgress: true,
        persistent: true,
      );

      final response = await _controller.carimbarDocumentos(
        files: uploadedDocuments,
        signature: _dadosArquivoEnviado(uploadedSignature),
        placement: {'x': _position.dx, 'y': _position.dy, 'width': _width},
      );

      if (!mounted) return;
      _mostrarResultadoFerramenta(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _dadosArquivoEnviado(FolhioArquivoEnviado file) {
    return {
      'id': file.fileId,
      'name': file.fileName,
      'mimeType': file.mimeType,
      'sizeBytes': file.sizeBytes,
    };
  }

  bool get _canGenerate =>
      !_loading && _documents.isNotEmpty && _signature?.path != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;

    return FolhioScaffold(
      title: 'Assinar/carimbar',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SeletorButton(
                  icon: Icons.description_outlined,
                  title: _documents.isEmpty
                      ? 'Selecionar certificados'
                      : '${_documents.length} arquivo(s) selecionado(s)',
                  subtitle: 'PDF, PNG ou JPG',
                  onTap: _escolherDocumentos,
                ),
                const SizedBox(height: 12),
                _SeletorButton(
                  icon: Icons.draw_outlined,
                  title: _signature == null
                      ? 'Selecionar assinatura PNG'
                      : _signature!.name,
                  subtitle: 'Use uma imagem com fundo transparente',
                  onTap: _escolherAssinatura,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Posição da assinatura',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _CarimboPreview(
            document: _documents.isEmpty ? null : _documents.first,
            signature: _signature,
            position: _position,
            width: _width,
            onPositionChanged: (value) => setState(() => _position = value),
          ),
          const SizedBox(height: 14),
          FolhioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tamanho',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Slider(
                  value: _width,
                  min: 0.12,
                  max: 0.55,
                  divisions: 12,
                  label: '${(_width * 100).round()}%',
                  onChanged: (value) => setState(() => _width = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _canGenerate ? _aplicarCarimbo : null,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.approval_outlined),
              label: Text(
                _loading ? 'Aplicando...' : 'Gerar arquivos assinados',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SeletorButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _CarimboPreview extends StatelessWidget {
  final PlatformFile? document;
  final PlatformFile? signature;
  final Offset position;
  final double width;
  final ValueChanged<Offset> onPositionChanged;

  const _CarimboPreview({
    required this.document,
    required this.signature,
    required this.position,
    required this.width,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidth = constraints.maxWidth;
        final previewHeight = previewWidth * 1.414;
        final stampWidth = previewWidth * width;
        final stampHeight = stampWidth * 0.42;
        final left = (position.dx * previewWidth).clamp(
          0.0,
          previewWidth - stampWidth,
        );
        final top = (position.dy * previewHeight).clamp(
          0.0,
          previewHeight - stampHeight,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: previewWidth,
            height: previewHeight,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _FundoPrevia(document: document),
                Positioned(
                  left: left,
                  top: top,
                  width: stampWidth,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final nextLeft = (left + details.delta.dx).clamp(
                        0.0,
                        previewWidth - stampWidth,
                      );
                      final nextTop = (top + details.delta.dy).clamp(
                        0.0,
                        previewHeight - stampHeight,
                      );
                      onPositionChanged(
                        Offset(
                          nextLeft / previewWidth,
                          nextTop / previewHeight,
                        ),
                      );
                    },
                    child: _AssinaturaPreview(file: signature),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FundoPrevia extends StatelessWidget {
  final PlatformFile? document;

  const _FundoPrevia({required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final file = document;
    final path = file?.path;
    final extension = (file?.extension ?? '').toLowerCase();
    if (path != null && const ['png', 'jpg', 'jpeg'].contains(extension)) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 18, color: const Color(0xFFE8E8E8)),
          const SizedBox(height: 18),
          Container(height: 12, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 8),
          Container(height: 12, color: const Color(0xFFF0F0F0)),
          const Spacer(),
          Text(
            file == null ? 'Prévia do certificado' : file.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.dim,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssinaturaPreview extends StatelessWidget {
  final PlatformFile? file;

  const _AssinaturaPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final path = file?.path;
    if (path != null) {
      return Image.file(File(path), fit: BoxFit.contain);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Assinatura',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
