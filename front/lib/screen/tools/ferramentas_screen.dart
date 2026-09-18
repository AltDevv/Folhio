import 'dart:convert';

import 'package:flutter/material.dart';

import '../../controller/settings/aparencia_controller.dart';
import '../../style/estilo_folhio.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../converter/conversor_screen.dart';
import '../edit/edit_flows_screen.dart';
import 'layout_pdf_screen.dart';
import 'poster_pdf_screen.dart';
import 'pdf_para_slides_screen.dart';
import 'tools_flows_screen.dart';

part '../../widget/tools/tools_screen_widgets.dart';

class FerramentasScreen extends StatefulWidget {
  const FerramentasScreen({super.key});

  @override
  State<FerramentasScreen> createState() => _FerramentasScreenState();
}

class _FerramentasScreenState extends State<FerramentasScreen> {
  static const _usageSettingKey = 'tools.usageCounts.v1';
  final _repo = PersistenciaLocalRepository.instance;
  final _search = TextEditingController();
  Map<String, int> _usage = const {};

  static final List<_DefinicaoFerramenta> _tools = [
    _DefinicaoFerramenta(
      id: 'convert',
      title: 'Converter arquivos',
      subtitle: 'PDF, imagem, DOCX e planilhas',
      categoryId: 'pdf',
      icon: Icons.cached_outlined,
      color: CoresFolhio.green,
      screen: const ConversorScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'edit_image',
      title: 'Editar imagem',
      subtitle: 'Cortar, ajustar, remover fundo e adicionar texto',
      categoryId: 'pdf',
      icon: Icons.edit_outlined,
      color: CoresFolhio.green,
      screen: const EdicaoImagemScreen(showBack: true),
    ),
    _DefinicaoFerramenta(
      id: 'stamp_documents',
      title: 'Assinar/carimbar',
      subtitle: 'Aplique assinatura em PDFs e imagens',
      categoryId: 'pdf',
      icon: Icons.approval_outlined,
      color: CoresFolhio.violet,
      screen: const CarimboPdfScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'merge_pdf',
      title: 'Mesclar PDF',
      subtitle: 'Juntar arquivos',
      categoryId: 'pdf',
      icon: Icons.file_copy,
      color: CoresFolhio.orange,
      screen: const MesclagemPdfScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'compress_pdf',
      title: 'Compactar PDF',
      subtitle: 'Enviar arquivos menores',
      categoryId: 'pdf',
      icon: Icons.compress,
      color: CoresFolhio.coral,
      screen: const CompactacaoPdfScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'cut_pdf',
      title: 'Dividir PDF',
      subtitle: 'Escolha páginas para separar',
      categoryId: 'pdf',
      icon: Icons.content_cut,
      color: CoresFolhio.blue,
      screen: const RecortePaginasScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'layout_pdf',
      title: 'Reorganizar páginas',
      subtitle: '2, 4 ou 6 páginas em uma folha',
      categoryId: 'pdf',
      icon: Icons.splitscreen,
      color: CoresFolhio.green,
      screen: const LayoutPdfScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'pdf_poster',
      title: 'PDF em pôster',
      subtitle: 'Divida uma página em folhas A4',
      categoryId: 'pdf',
      icon: Icons.grid_view,
      color: CoresFolhio.blue,
      screen: const PosterPdfScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'pdf_slides',
      title: 'PDF para slides',
      subtitle: 'OCR e apresentação editável',
      categoryId: 'pdf',
      icon: Icons.slideshow_outlined,
      color: CoresFolhio.violet,
      screen: const PdfParaSlidesScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'students',
      title: 'Lista de alunos',
      subtitle: 'Organize nomes por turma',
      categoryId: 'classroom',
      icon: Icons.people_alt_outlined,
      color: CoresFolhio.green,
      screen: const ListaAlunosScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'attendance_print',
      title: 'Chamada e presença',
      subtitle: 'Lista pronta para imprimir',
      categoryId: 'classroom',
      icon: Icons.fact_check_outlined,
      color: CoresFolhio.green,
      screen: const ListaPresencaScreen(),
    ),
    _DefinicaoFerramenta(
      id: 'notes',
      title: 'Comunicados',
      subtitle: 'Avisos individuais',
      categoryId: 'classroom',
      icon: Icons.badge,
      color: CoresFolhio.blue,
      screen: const ComunicadoIndividualScreen(),
    ),
  ];

  static final List<_CategoriaFerramenta> _categories = [
    _CategoriaFerramenta(
      id: 'pdf',
      title: 'PDF e arquivos',
      subtitle: 'Converter, compactar, mesclar e dividir',
      icon: Icons.file_copy,
      color: CoresFolhio.orange,
    ),
    _CategoriaFerramenta(
      id: 'classroom',
      title: 'Sala de aula',
      subtitle: 'Lista, chamada e comunicados',
      icon: Icons.groups,
      color: CoresFolhio.green,
    ),
  ];

  static const _defaultMostUsed = [
    'convert',
    'edit_image',
    'stamp_documents',
    'merge_pdf',
  ];

  @override
  void initState() {
    super.initState();
    _carregarUso();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _carregarUso() async {
    final raw = await _repo.configuracao(_usageSettingKey);
    final next = <String, int>{};
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is num) next[entry.key] = value.toInt();
          }
        }
      } catch (_) {
        // Ignore old or malformed local settings.
      }
    }
    if (!mounted) return;
    setState(() => _usage = next);
  }

  Future<void> _abrirFerramenta(_DefinicaoFerramenta tool) async {
    final next = Map<String, int>.from(_usage);
    next[tool.id] = (next[tool.id] ?? 0) + 1;
    setState(() => _usage = next);
    await _repo.definirConfiguracao(_usageSettingKey, jsonEncode(next));
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => tool.screen));
  }

  List<_DefinicaoFerramenta> get _mostUsedTools {
    final used = _tools.where((tool) => (_usage[tool.id] ?? 0) > 0).toList()
      ..sort((a, b) {
        final count = (_usage[b.id] ?? 0).compareTo(_usage[a.id] ?? 0);
        if (count != 0) return count;
        return _tools.indexOf(a).compareTo(_tools.indexOf(b));
      });
    final result = <_DefinicaoFerramenta>[...used.take(4)];
    for (final id in _defaultMostUsed) {
      if (result.length >= 4) break;
      final matches = _tools.where((item) => item.id == id);
      if (matches.isEmpty) continue;
      final tool = matches.first;
      if (!result.any((item) => item.id == tool.id)) result.add(tool);
    }
    return result;
  }

  List<_DefinicaoFerramenta> get _searchResults {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _tools.where((tool) {
      return tool.title.toLowerCase().contains(query) ||
          tool.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  List<_DefinicaoFerramenta> _ferramentasPorCategoria(String categoryId) {
    return _tools.where((tool) => tool.categoryId == categoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final results = _searchResults;
    final searching = _search.text.trim().isNotEmpty;
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;

    return FolhioScaffold(
      title: 'Ferramentas',
      currentIndex: 3,
      body: FolhioCorpoPagina(
        children: [
          if (showDescriptions) ...[
            Text(
              'Recursos para criar, organizar e compartilhar.',
              style: TextStyle(
                color: colors.muted,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar ferramenta...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          if (searching) ...[
            const TituloSecao('Resultados'),
            if (results.isEmpty)
              const _BuscaFerramentasVazia()
            else
              for (final tool in results)
                _LinhaListaFerramentas(tool: tool, onTap: () => _abrirFerramenta(tool)),
          ] else ...[
            const TituloSecao('Mais usadas'),
            _GradeMaisUsados(tools: _mostUsedTools, onTap: _abrirFerramenta),
            const TituloSecao('Categorias'),
            for (final category in _categories)
              _CategoriaFerramentaCard(
                category: category,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _CategoriaFerramentaScreen(
                        category: category,
                        tools: _ferramentasPorCategoria(category.id),
                        usage: _usage,
                        onToolOpened: _abrirFerramenta,
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
