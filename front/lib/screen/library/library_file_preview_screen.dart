part of 'meus_arquivos_screen.dart';

class _PreviaArquivoBibliotecaScreen extends StatelessWidget {
  final FolhioArquivoBiblioteca source;
  final FolhioArquivoGerado file;

  const _PreviaArquivoBibliotecaScreen({required this.source, required this.file});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    final isImage = _ehImagemBiblioteca(source) || _ehImagemGerada(file);

    return FolhioScaffold(
      title: 'Visualizar',
      currentIndex: 2,
      showBack: true,
      body: FolhioCorpoPagina(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            _nomeAmigavelArquivoPrevia(source.fileName),
            style: TextStyle(
              color: colors.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_rotuloTipoPrevia(source, file)} · ${_rotuloTamanhoPrevia(source.sizeBytes ?? file.bytes.length)}',
            style: TextStyle(
              color: colors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (isImage)
            _ImagemPreview(bytes: file.bytes)
          else
            _PreviaDocumentoCard(source: source, file: file),
          const SizedBox(height: 16),
          FolhioCard(
            color: CoresFolhio.surfaceSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.visibility_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isImage
                        ? 'Essa é uma visualização do arquivo salvo. Nada foi baixado para fora do app.'
                        : 'A prévia direta desse formato ainda não está disponível. Você pode renomear ou editar visualmente quando compatível.',
                    style: TextStyle(
                      color: colors.muted,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagemPreview extends StatelessWidget {
  final Uint8List bytes;

  const _ImagemPreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 260, maxHeight: 560),
        color: colors.surface,
        alignment: Alignment.center,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const _PreviaIndisponivel(),
          ),
        ),
      ),
    );
  }
}

class _PreviaDocumentoCard extends StatelessWidget {
  final FolhioArquivoBiblioteca source;
  final FolhioArquivoGerado file;

  const _PreviaDocumentoCard({required this.source, required this.file});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return FolhioCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _corPreviaPara(source, file).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _iconePreviaPara(source, file),
              color: _corPreviaPara(source, file),
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _rotuloTipoPrevia(source, file),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            file.fileName,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PreviaIndisponivel extends StatelessWidget {
  const _PreviaIndisponivel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: colors.muted, size: 42),
          const SizedBox(height: 10),
          Text(
            'Não foi possível mostrar essa imagem.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

bool _ehImagemBiblioteca(FolhioArquivoBiblioteca file) {
  final lower = '${file.mimeType} ${file.fileName}'.toLowerCase();
  return lower.contains('image/') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg');
}

bool _ehImagemGerada(FolhioArquivoGerado file) {
  final lower = '${file.mimeType} ${file.fileName}'.toLowerCase();
  return lower.contains('image/') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg');
}

String _nomeAmigavelArquivoPrevia(String fileName) {
  final original = fileName.trim();
  final name = original.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
  return name.isEmpty ? 'Material' : name;
}

String _rotuloTamanhoPrevia(int bytes) {
  if (bytes <= 0) return 'tamanho indisponível';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

String _rotuloTipoPrevia(FolhioArquivoBiblioteca source, FolhioArquivoGerado file) {
  final lower =
      '${source.mimeType} ${file.mimeType} ${source.fileName} ${file.fileName}'
          .toLowerCase();
  if (lower.contains('pdf')) return 'PDF';
  if (lower.contains('image') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg')) {
    return 'Imagem';
  }
  if (lower.contains('word') || lower.endsWith('.docx')) {
    return 'Documento Word';
  }
  if (lower.contains('sheet') || lower.endsWith('.xlsx')) return 'Planilha';
  if (lower.contains('presentation') || lower.endsWith('.pptx')) {
    return 'Apresentação';
  }
  if (lower.contains('video') || lower.endsWith('.mp4')) return 'Vídeo';
  return 'Arquivo';
}

IconData _iconePreviaPara(FolhioArquivoBiblioteca source, FolhioArquivoGerado file) {
  final label = _rotuloTipoPrevia(source, file);
  return switch (label) {
    'PDF' => Icons.picture_as_pdf_outlined,
    'Imagem' => Icons.image_outlined,
    'Documento Word' => Icons.description_outlined,
    'Planilha' => Icons.table_chart_outlined,
    'Apresentação' => Icons.slideshow_outlined,
    'Vídeo' => Icons.movie_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

Color _corPreviaPara(FolhioArquivoBiblioteca source, FolhioArquivoGerado file) {
  final label = _rotuloTipoPrevia(source, file);
  return switch (label) {
    'PDF' => CoresFolhio.coral,
    'Imagem' => CoresFolhio.blue,
    'Documento Word' => CoresFolhio.violet,
    'Planilha' => CoresFolhio.green,
    'Apresentação' => CoresFolhio.orange,
    'Vídeo' => CoresFolhio.violet,
    _ => CoresFolhio.orange,
  };
}
