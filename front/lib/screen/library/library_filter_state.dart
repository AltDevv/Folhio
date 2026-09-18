part of 'meus_arquivos_screen.dart';

extension _FiltroBibliotecaState on _MeusArquivosScreenState {
  List<String> get _templateTagOptions {
    return _SecoesCatalogoModelos.templateTags;
  }

  List<String> get _availableTemplateTagOptions {
    return [
      ..._templateTagOptions.where(
        (tag) => tag.toLowerCase() != _favoriteTag.toLowerCase(),
      ),
    ];
  }

  List<String> get _availableMaterialTagOptions {
    return [
      if (_favoriteFileIds.isNotEmpty) _favoriteTag,
      ..._availableFolderTags.where(
        (tag) => tag.toLowerCase() != _favoriteTag.toLowerCase(),
      ),
    ];
  }

  List<String> get _orderedTemplateTagOptions {
    final tags = _templateTagOptions;
    final knownByLower = {for (final tag in tags) tag.toLowerCase(): tag};
    final recent = [
      for (final tag in _recentTemplateTags)
        if (knownByLower.containsKey(tag.toLowerCase()))
          knownByLower[tag.toLowerCase()]!,
    ];
    final remaining = tags
        .where(
          (tag) => !recent.any(
            (recentTag) => recentTag.toLowerCase() == tag.toLowerCase(),
          ),
        )
        .toList();
    return [...recent, ...remaining];
  }

  List<FolhioPastaBiblioteca> get _visibleFolders {
    if (_materialStatusFilter != null ||
        _fileTagFilters.any(
          (tag) => tag.toLowerCase() == _favoriteTag.toLowerCase(),
        )) {
      return const <FolhioPastaBiblioteca>[];
    }
    if (_fileTagFilters.isEmpty) return _folders;
    return _folders
        .where(
          (folder) =>
              _fileTagFilters.every((tag) => _pastaTemEtiqueta(folder, tag)),
        )
        .toList();
  }

  List<FolhioArquivoBiblioteca> get _visibleFiles {
    return _files.where((file) {
      for (final tag in _fileTagFilters) {
        if (tag.toLowerCase() == _favoriteTag.toLowerCase()) {
          if (!_favoriteFileIds.contains(file.id)) return false;
        } else if (!_arquivoCorrespondeEtiquetaPasta(file, tag)) {
          return false;
        }
      }
      final status = _materialStatusFilter;
      if (status != null && _statusMaterialPara(file) != status) return false;
      return true;
    }).toList();
  }

  bool _pastaTemEtiqueta(FolhioPastaBiblioteca folder, String tag) {
    final lower = tag.toLowerCase();
    return _etiquetasPasta(folder.tags).any((item) => item.toLowerCase() == lower);
  }

  bool _arquivoCorrespondeEtiquetaPasta(FolhioArquivoBiblioteca file, String tag) {
    final lower = tag.toLowerCase();
    if (_path.isNotEmpty && _pastaTemEtiqueta(_path.last, tag)) return true;
    final folderTags = file.folderId == null
        ? const <String>[]
        : _folderTagsById[file.folderId] ?? const <String>[];
    if (folderTags.any((item) => item.toLowerCase() == lower)) return true;
    return file.folder.toLowerCase().contains(lower);
  }

  Future<void> _mostrarFiltroBiblioteca() {
    return switch (_tab) {
      _AbaBiblioteca.templates => _mostrarPainelFiltrosModelo(),
      _AbaBiblioteca.files => _mostrarPainelFiltrosMaterial(),
    };
  }

  Future<void> _mostrarPainelFiltrosMaterial() async {
    final selected = await showModalBottomSheet<_FiltrosMaterial>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MaterialFilterFolha(
        initial: _FiltrosMaterial(
          status: _materialStatusFilter,
          tags: _fileTagFilters,
        ),
        tags: _availableMaterialTagOptions,
      ),
    );
    if (!mounted || selected == null) return;
    _renovar(() {
      _materialStatusFilter = selected.status;
      _fileTagFilters = selected.tags;
    });
  }

  Future<void> _mostrarPainelFiltrosModelo() async {
    final selected = await showModalBottomSheet<_FiltrosModelo>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ModeloFilterFolha(
        initial: _FiltrosModelo(
          type: _templateTypeFilter,
          access: _templateAccessFilter,
          tags: _templateTagFilters,
        ),
        tags: _orderedTemplateTagOptions,
      ),
    );
    if (selected == null || !mounted) return;
    _renovar(() {
      _templateTypeFilter = selected.type;
      _templateAccessFilter = selected.access;
      _templateTagFilters = selected.tags;
      for (final tag in selected.tags) {
        if (tag != _favoriteTag) _memorizarEtiquetaModelo(tag);
      }
    });
  }

  void _selecionarEtiquetaArquivo(String tag) {
    _renovar(() => _fileTagFilters = _alternarEtiqueta(_fileTagFilters, tag));
  }

  void _selecionarStatusMaterial(String? status) {
    _renovar(() => _materialStatusFilter = status);
  }

  void _selecionarTipoModelo(String? type) {
    _renovar(() {
      _templateTypeFilter = type;
    });
  }

  Set<String> _alternarEtiqueta(Set<String> current, String tag) {
    final next = Set<String>.from(current);
    final existing = next.where(
      (item) => item.toLowerCase() == tag.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      next.remove(existing.first);
    } else {
      next.add(tag);
    }
    return next;
  }

  void _memorizarEtiquetaModelo(String tag) {
    final normalized = tag.toLowerCase();
    _recentTemplateTags = [
      tag,
      ..._recentTemplateTags.where((item) => item.toLowerCase() != normalized),
    ].take(8).toList();
  }
}
