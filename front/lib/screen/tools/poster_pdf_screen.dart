import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../controller/edit/edicao_controller.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../widget/actions.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../../widget/previews.dart';

class PosterPdfScreen extends StatefulWidget {
  const PosterPdfScreen({super.key});

  @override
  State<PosterPdfScreen> createState() => _PosterPdfScreenState();
}

class _PosterPdfScreenState extends State<PosterPdfScreen> {
  int _sheetsWide = 3;
  int _sheetsTall = 2;
  int _margin = 6;
  File? _selectedFile;
  String? _selectedFileName;
  bool _processing = false;

  int get _totalSheets => _sheetsWide * _sheetsTall;

  Future<void> _escolherArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _selectedFile = File(path);
      _selectedFileName = result!.files.single.name;
    });
  }

  Future<void> _criarPoster() async {
    final file = _selectedFile;
    if (file == null) {
      await _escolherArquivo();
      return;
    }

    setState(() => _processing = true);
    FolhioApiGateway.generatedFile.value = null;
    FolhioApiGateway.progress.value = const FolhioProgressoOperacao(
      progress: 0.01,
      message: 'Preparando arquivo',
    );
    final api = FolhioApiGateway(timeout: const Duration(minutes: 12));
    try {
      final response = await EdicaoController(api)
          .criarPosterPdfLocal(
            file: file,
            sheetsWide: _sheetsWide,
            sheetsTall: _sheetsTall,
            pageMargin: (_margin * 72 / 25.4).round(),
          )
          .timeout(const Duration(minutes: 12));
      if (!mounted) return;
      if (FolhioApiGateway.generatedFile.value == null) {
        _mostrarResultado(response.message, response.outputFile?.fileName);
      }
    } catch (error) {
      FolhioApiGateway.limparArquivoGerado();
      if (!mounted) return;
      _mostrarResultado(
        'Não foi possível criar o pôster. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    } finally {
      api.fechar();
      if (mounted) setState(() => _processing = false);
    }
  }

  void _mostrarResultado(String message, String? fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fileName == null ? message : '$message Arquivo: $fileName',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'PDF em pôster',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            onTap: _processing ? null : _escolherArquivo,
            borderColor: _selectedFile == null
                ? CoresFolhio.borderSoft
                : CoresFolhio.green,
            child: FaixaArquivos(
              name: _selectedFileName ?? 'Selecionar arquivo',
              icon: _selectedFileName == null
                  ? Icons.picture_as_pdf
                  : _iconeArquivo(_selectedFileName!),
              detail: _selectedFile == null
                  ? 'Use PDF, PNG ou JPG'
                  : 'Será dividido em folhas A4',
            ),
          ),
          const TituloSecao('Tamanho final'),
          _PosterPreview(sheetsWide: _sheetsWide, sheetsTall: _sheetsTall),
          const SizedBox(height: 14),
          _LinhaIncrementoPoster(
            label: 'Largura',
            value: _sheetsWide,
            suffix: 'folhas A4',
            onChanged: (value) => setState(() => _sheetsWide = value),
          ),
          const SizedBox(height: 10),
          _LinhaIncrementoPoster(
            label: 'Altura',
            value: _sheetsTall,
            suffix: 'folhas A4',
            onChanged: (value) => setState(() => _sheetsTall = value),
          ),
          const SizedBox(height: 10),
          _LinhaIncrementoPoster(
            label: 'Margem',
            value: _margin,
            suffix: 'mm aprox.',
            min: 0,
            max: 14,
            onChanged: (value) => setState(() => _margin = value),
          ),
          const SizedBox(height: 14),
          FolhioCard(
            child: Row(
              children: [
                const IconeArredondado(
                  icon: Icons.grid_view,
                  color: CoresFolhio.green,
                  backgroundColor: Color(0xFFE3F8F1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vai gerar $_totalSheets páginas A4 para imprimir e montar.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: _processing ? 'Processando...' : 'Gerar PDF em pôster',
            icon: Icons.grid_view,
            onPressed: _processing ? null : _criarPoster,
          ),
        ],
      ),
    );
  }
}

IconData _iconeArquivo(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg')) {
    return Icons.image_outlined;
  }
  return Icons.picture_as_pdf;
}

class _LinhaIncrementoPoster extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _LinhaIncrementoPoster({
    required this.label,
    required this.value,
    required this.suffix,
    this.min = 1,
    this.max = 5,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$value $suffix',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          NumeracaoStepper(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PosterPreview extends StatelessWidget {
  final int sheetsWide;
  final int sheetsTall;

  const _PosterPreview({required this.sheetsWide, required this.sheetsTall});

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      borderColor: CoresFolhio.green,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 5.0;
              final availableWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 240.0;
              final cellSize =
                  ((availableWidth - (sheetsWide - 1) * spacing) / sheetsWide)
                      .clamp(30.0, 42.0);
              final gridWidth =
                  sheetsWide * cellSize + (sheetsWide - 1) * spacing;

              return Center(
                child: SizedBox(
                  width: gridWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var row = 0; row < sheetsTall; row++) ...[
                        if (row > 0) const SizedBox(height: spacing),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var column = 0;
                              column < sheetsWide;
                              column++
                            ) ...[
                              if (column > 0) const SizedBox(width: spacing),
                              _PaginaPosterTile(
                                number: row * sheetsWide + column + 1,
                                size: cellSize,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            '$sheetsWide x $sheetsTall folhas A4',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PaginaPosterTile extends StatelessWidget {
  final int number;
  final double size;

  const _PaginaPosterTile({required this.number, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CoresFolhio.greenSoft,
          border: Border.all(color: CoresFolhio.green, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              color: CoresFolhio.green,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
