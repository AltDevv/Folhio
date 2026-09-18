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

class LayoutPdfScreen extends StatefulWidget {
  const LayoutPdfScreen({super.key});

  @override
  State<LayoutPdfScreen> createState() => _LayoutPdfScreenState();
}

class _LayoutPdfScreenState extends State<LayoutPdfScreen> {
  int _layoutIndex = 0;
  int _orientationIndex = 1;
  int _margin = 4;
  File? _selectedFile;
  String? _selectedFileName;
  bool _processing = false;

  static const _pagesPerSheetOptions = [2, 4, 6];

  int get _pagesPerSheet => _pagesPerSheetOptions[_layoutIndex];

  Future<void> _escolherArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _selectedFile = File(path);
      _selectedFileName = result!.files.single.name;
    });
  }

  Future<void> _aplicarLayout() async {
    final file = _selectedFile;
    if (file == null) {
      await _escolherArquivo();
      return;
    }

    setState(() => _processing = true);
    try {
      final response = await EdicaoController(FolhioApiGateway())
          .aplicarLayoutPdfLocal(
            file: file,
            pagesPerSheet: _pagesPerSheet,
            landscape: _orientationIndex == 1,
            pageMargin: _margin,
          );
      if (!mounted) return;
      _mostrarResultado(response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultado(
        'Não foi possível reorganizar o PDF. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    } finally {
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
      title: 'Páginas por folha',
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
              name: _selectedFileName ?? 'Selecionar PDF',
              detail: _selectedFile == null
                  ? 'Toque para escolher um arquivo'
                  : 'Arquivo pronto para editar',
            ),
          ),
          const TituloSecao('Layout'),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = ((constraints.maxWidth - 12) / 2).clamp(
                150.0,
                190.0,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    for (final (index, pages)
                        in _pagesPerSheetOptions.indexed) ...[
                      SizedBox(
                        width: cardWidth,
                        height: 122,
                        child: _EscolhaLayout(
                          label: '$pages por folha',
                          selected: _layoutIndex == index,
                          pages: pages,
                          onTap: () => setState(() => _layoutIndex = index),
                        ),
                      ),
                      if (index < _pagesPerSheetOptions.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const TituloSecao('Orientação da folha'),
          Row(
            children: [
              Expanded(
                child: _EscolhaOrientacao(
                  label: 'Retrato',
                  icon: Icons.stay_current_portrait,
                  selected: _orientationIndex == 0,
                  onTap: () => setState(() => _orientationIndex = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EscolhaOrientacao(
                  label: 'Paisagem',
                  icon: Icons.stay_current_landscape,
                  selected: _orientationIndex == 1,
                  onTap: () => setState(() => _orientationIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Margem entre páginas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NumeracaoStepper(
                    value: _margin,
                    min: 0,
                    max: 12,
                    onChanged: (value) => setState(() => _margin = value),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'mm',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          AcaoPrincipalButton(
            label: _processing ? 'Processando...' : 'Aplicar layout',
            onPressed: _processing ? null : _aplicarLayout,
          ),
        ],
      ),
    );
  }
}

class _EscolhaLayout extends StatelessWidget {
  final String label;
  final int pages;
  final bool selected;
  final VoidCallback onTap;

  const _EscolhaLayout({
    required this.label,
    required this.pages,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final color = selected ? colors.primary : colors.dim;
    return FolhioCard(
      onTap: onTap,
      borderColor: selected ? colors.primary : colors.borderSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 58,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _IconePaginasPorFolha(pages: pages, color: color),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                color: selected ? colors.primary : colors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconePaginasPorFolha extends StatelessWidget {
  final int pages;
  final Color color;

  const _IconePaginasPorFolha({required this.pages, required this.color});

  @override
  Widget build(BuildContext context) {
    final columns = switch (pages) {
      6 => 3,
      _ => 2,
    };
    final rows = (pages / columns).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) const SizedBox(width: 5),
                if (row * columns + column < pages)
                  _MiniPagina(color: color)
                else
                  const SizedBox(width: 28, height: 32),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniPagina extends StatelessWidget {
  final Color color;

  const _MiniPagina({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _EscolhaOrientacao extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EscolhaOrientacao({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      onTap: onTap,
      borderColor: selected ? CoresFolhio.green : CoresFolhio.borderSoft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: SizedBox(
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? CoresFolhio.green : CoresFolhio.dim,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? CoresFolhio.green : CoresFolhio.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
