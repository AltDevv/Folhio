import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../edit/edit_flows_screen.dart';
import '../../model/library/library_models.dart';
import '../../repository/library/biblioteca_repository.dart';
import '../../controller/library/biblioteca_view_model.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../create/detalhes_modelo_screen.dart';

part '../../widget/library/library_controls_widgets.dart';
part '../../widget/library/library_filter_widgets.dart';
part '../../widget/library/library_template_catalog_data.dart';
part '../../widget/library/library_template_catalog_models.dart';
part '../../widget/library/library_catalog_widgets.dart';
part '../../widget/library/library_dialog_widgets.dart';
part 'library_material_actions.dart';
part 'library_filter_state.dart';
part 'library_screen_sections.dart';
part 'library_file_preview_screen.dart';

enum _AbaBiblioteca { templates, files }

const String _favoriteTag = 'Favoritos';
const String _rootMaterialsLabel = 'Meus materiais';

class MeusArquivosScreen extends StatefulWidget {
  final String initialSearch;
  final bool showBack;
  final bool startInFiles;

  const MeusArquivosScreen({
    super.key,
    this.initialSearch = '',
    this.showBack = true,
    this.startInFiles = false,
  });

  @override
  State<MeusArquivosScreen> createState() => _MeusArquivosScreenState();
}

class _MeusArquivosScreenState extends State<MeusArquivosScreen> {
  final FolhioApiGateway _api = FolhioApiGateway();
  late final BibliotecaViewModel _viewModel;
  late final TextEditingController _searchController;
  late final TextEditingController _templateSearchController;
  late final ScrollController _templateScrollController;
  final List<FolhioPastaBiblioteca> _path = [];
  List<String> _recentTemplateTags = const [];
  late _AbaBiblioteca _tab;
  Set<String> _fileTagFilters = const <String>{};
  String? _materialStatusFilter;
  String? _templateTypeFilter;
  String? _templateAccessFilter;
  Set<String> _templateTagFilters = const <String>{};
  bool _showFloatingTemplateSearch = false;

  String? get _currentFolderId => _path.isEmpty ? null : _path.last.id;
  int get _depth => _path.length;
  bool get _canCreateSubfolder => _depth <= 2;
  bool get _templateFiltersActive =>
      _templateTypeFilter != null ||
      _templateAccessFilter != null ||
      _templateTagFilters.isNotEmpty;
  bool get _fileFiltersActive =>
      _fileTagFilters.isNotEmpty || _materialStatusFilter != null;
  List<FolhioPastaBiblioteca> get _folders => _viewModel.folders;
  List<FolhioArquivoBiblioteca> get _files => _viewModel.files;
  List<String> get _availableFolderTags => _viewModel.availableFolderTags;
  Map<String, List<String>> get _folderTagsById => _viewModel.folderTagsById;
  Set<String> get _favoriteFileIds => _viewModel.favoriteFileIds;
  bool get _loading => _viewModel.loading;
  String? get _message => _viewModel.message;

  @override
  void initState() {
    super.initState();
    _viewModel = BibliotecaViewModel(
      repository: FolhioBibliotecaRepository(api: _api),
    )..addListener(_aoVisualizacaoModeloAlterado);
    _searchController = TextEditingController(text: widget.initialSearch);
    _templateSearchController = TextEditingController();
    _templateScrollController = ScrollController()
      ..addListener(_tratarRolagemModelos);
    _tab = widget.startInFiles || widget.initialSearch.trim().isNotEmpty
        ? _AbaBiblioteca.files
        : _AbaBiblioteca.templates;
    _carregarConteudo();
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_aoVisualizacaoModeloAlterado)
      ..dispose();
    _api.fechar();
    _templateScrollController
      ..removeListener(_tratarRolagemModelos)
      ..dispose();
    _searchController.dispose();
    _templateSearchController.dispose();
    super.dispose();
  }

  void _aoVisualizacaoModeloAlterado() {
    if (!mounted) return;
    _sincronizarFiltrosComConteudoCarregado();
    setState(() {});
  }

  void _renovar(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  void _tratarRolagemModelos() {
    if (!mounted || _tab != _AbaBiblioteca.templates) return;
    final shouldShow =
        _templateScrollController.hasClients &&
        _templateScrollController.offset > 120;
    if (_showFloatingTemplateSearch == shouldShow) return;
    setState(() => _showFloatingTemplateSearch = shouldShow);
  }

  Future<void> _carregarConteudo() async {
    await _viewModel.carregarConteudo(
      parentId: _currentFolderId ?? 'root',
      search: _searchController.text,
    );
  }

  void _sincronizarFiltrosComConteudoCarregado() {
    final fileTagOptions = _availableMaterialTagOptions;
    _fileTagFilters = _fileTagFilters
        .where(
          (selected) => fileTagOptions.any(
            (tag) => tag.toLowerCase() == selected.toLowerCase(),
          ),
        )
        .toSet();
    final templateTagOptions = _availableTemplateTagOptions;
    _templateTagFilters = _templateTagFilters
        .where(
          (selected) => templateTagOptions.any(
            (tag) => tag.toLowerCase() == selected.toLowerCase(),
          ),
        )
        .toSet();
    _recentTemplateTags = _recentTemplateTags
        .where(
          (recentTag) => _availableTemplateTagOptions.any(
            (tag) => tag.toLowerCase() == recentTag.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _path.isEmpty && (_tab != _AbaBiblioteca.files || widget.showBack),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_path.isNotEmpty) {
          _voltarPastaAnterior();
          return;
        }
        if (_tab == _AbaBiblioteca.files && !widget.showBack) {
          setState(() => _tab = _AbaBiblioteca.templates);
        }
      },
      child: FolhioScaffold(
        title: 'Biblioteca',
        currentIndex: 2,
        showBack: widget.showBack,
        body: _tab == _AbaBiblioteca.templates
            ? _corpoModelos()
            : _corpoMateriais(),
      ),
    );
  }
}
