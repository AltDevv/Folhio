part of 'meus_arquivos_screen.dart';

extension _SecoesTelaBiblioteca on _MeusArquivosScreenState {
  void _selecionarAba(_AbaBiblioteca tab) {
    _renovar(() {
      _tab = tab;
      if (tab != _AbaBiblioteca.templates) {
        _showFloatingTemplateSearch = false;
      }
    });
    if (tab == _AbaBiblioteca.files) _carregarConteudo();
  }

  Widget _corpoModelos() {
    final query = _templateSearchController.text.trim();
    final showHighlights = query.isEmpty && !_templateFiltersActive;
    final searchBar = _BarraBuscaBiblioteca(
      controller: _templateSearchController,
      onSearch: () => _renovar(() {}),
      onChanged: (_) => _renovar(() {}),
      onFilterTap: _mostrarFiltroBiblioteca,
      filterActive: _templateFiltersActive,
    );
    return Stack(
      children: [
        FolhioCorpoPagina(
          controller: _templateScrollController,
          children: [
            const _IntroducaoBiblioteca(),
            searchBar,
            _AbasBiblioteca(selected: _tab, onSelected: _selecionarAba),
            _BibliotecaFilterFaixa(
              options: const [
                'Atividades',
                'Provas',
                'Planos',
                'Revisões',
                'Simulados',
              ],
              selected: _templateTypeFilter,
              onSelected: _selecionarTipoModelo,
            ),
            if (_templateAccessFilter != null || _templateTagFilters.isNotEmpty)
              _FiltrosModelosAtivos(
                access: _templateAccessFilter,
                tags: _templateTagFilters,
                onClear: () {
                  _renovar(() {
                    _templateAccessFilter = null;
                    _templateTagFilters = const <String>{};
                  });
                },
              ),
            if (showHighlights) ...[
              _ModelosDestaque(onOpenTemplate: _abrirModelo),
              const SizedBox(height: 14),
            ],
            _SecoesCatalogoModelos(
              query: query,
              type: _templateTypeFilter,
              access: _templateAccessFilter,
              tags: _templateTagFilters,
              onOpenTemplate: _abrirModelo,
            ),
            const SizedBox(height: 18),
            const _CabecalhoSecaoBiblioteca(
              icon: Icons.view_list_outlined,
              title: 'Todos',
              showIcon: false,
            ),
            const SizedBox(height: 10),
            _ModeloTodosLista(
              query: query,
              type: _templateTypeFilter,
              access: _templateAccessFilter,
              tags: _templateTagFilters,
              onOpenTemplate: _abrirModelo,
            ),
          ],
        ),
        _BarraBuscaBibliotecaFlutuante(
          visible: _showFloatingTemplateSearch,
          controller: _templateSearchController,
          onSearch: () => _renovar(() {}),
          onChanged: (_) => _renovar(() {}),
          onFilterTap: _mostrarFiltroBiblioteca,
          filterActive: _templateFiltersActive,
        ),
      ],
    );
  }

  Widget _corpoMateriais() {
    return FolhioCorpoPagina(
      children: [
        const _IntroducaoBiblioteca(),
        _BarraBuscaBiblioteca(
          controller: _searchController,
          onSearch: _carregarConteudo,
          onFilterTap: _mostrarFiltroBiblioteca,
          filterActive: _fileFiltersActive,
        ),
        _AbasBiblioteca(selected: _tab, onSelected: _selecionarAba),
        _BibliotecaFilterFaixa(
          options: const ['Rascunhos', 'Publicados', 'Importados'],
          selected: _materialStatusFilter,
          onSelected: _selecionarStatusMaterial,
        ),
        if (_availableMaterialTagOptions.isNotEmpty)
          _FaixaEtiquetasBiblioteca(
            tags: _availableMaterialTagOptions,
            selected: _fileTagFilters,
            onSelected: _selecionarEtiquetaArquivo,
          ),
        ..._visualizacaoArquivos(),
      ],
    );
  }

  List<Widget> _visualizacaoArquivos() {
    final visibleFolders = _visibleFolders;
    final visibleFiles = _visibleFiles;
    return [
      _BarraCaminho(path: _path, onBackFolder: _voltarPastaAnterior),
      const SizedBox(height: 14),
      Row(
        children: [
          const Expanded(child: TituloSecao('Meus materiais')),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _carregarConteudo,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 158,
            child: OutlinedButton.icon(
              onPressed: _canCreateSubfolder ? _criarPasta : null,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(_canCreateSubfolder ? 'Nova pasta' : 'Limite'),
            ),
          ),
          SizedBox(
            width: 178,
            child: FilledButton.icon(
              onPressed: _escolherEEnviarArquivo,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar material'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loading)
        FolhioCard(
          child: Text(
            'Carregando materiais...',
            style: TextStyle(
              color: Theme.of(context).extension<CoresTemaFolhio>()!.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        )
      else if (_message != null)
        FolhioCard(
          borderColor: CoresFolhio.coral,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _message!,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).extension<CoresTemaFolhio>()!.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _carregarConteudo,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        )
      else if (visibleFolders.isEmpty && visibleFiles.isEmpty)
        _BibliotecaVaziaState(tags: _fileTagFilters)
      else ...[
        ...visibleFolders.map(_itemPasta),
        ...visibleFiles.map(_itemArquivo),
      ],
    ];
  }

  Widget _itemPasta(FolhioPastaBiblioteca folder) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    final tags = _etiquetasPasta(folder.tags);
    return FolhioItemLista(
      icon: Icons.folder,
      iconColor: CoresFolhio.orange,
      iconBackground: CoresFolhio.surfaceSoft,
      title: folder.name,
      subtitle: '',
      badges: tags,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: colors.text),
        onSelected: (value) {
          if (value == 'edit') _editarPasta(folder);
          if (value == 'delete') _excluirPasta(folder);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Apagar')),
        ],
      ),
      onTap: () => _abrirPasta(folder),
    );
  }

  Widget _itemArquivo(FolhioArquivoBiblioteca file) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    final isFavorite = _favoriteFileIds.contains(file.id);
    final canFavorite = _viewModel.podeFavoritar(file);
    return FolhioItemLista(
      icon: _iconePara(file),
      iconColor: _corPara(file),
      iconBackground: CoresFolhio.surfaceSoft,
      title: _nomeArquivoAmigavel(file),
      subtitle: '${_statusMaterialPara(file)} · ${_dataRotulo(file.updatedAt)}',
      badge: _indicadorPara(file),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canFavorite)
            IconButton(
              tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
              onPressed: () => _alternarFavorito(file),
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? CoresFolhio.orange : colors.text,
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.text),
            onSelected: (value) {
              if (value == 'preview') _visualizarArquivo(file);
              if (value == 'rename') _renomearArquivo(file);
              if (value == 'edit') _editarArquivoVisualmente(file);
              if (value == 'favorite') _alternarFavorito(file);
              if (value == 'move') _moverArquivo(file);
              if (value == 'delete') _excluirArquivo(file);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'preview', child: Text('Visualizar')),
              const PopupMenuItem(value: 'rename', child: Text('Renomear')),
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'move', child: Text('Mover')),
              const PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconePara(FolhioArquivoBiblioteca file) {
    final lower = '${file.mimeType} ${file.fileName}'.toLowerCase();
    if (lower.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.contains('image')) return Icons.image_outlined;
    if (_ehVideo(file)) return Icons.movie_outlined;
    if (lower.contains('word') || lower.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    if (lower.contains('sheet') || lower.endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }
    if (lower.contains('presentation') || lower.endsWith('.pptx')) {
      return Icons.slideshow_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _corPara(FolhioArquivoBiblioteca file) {
    final lower = '${file.mimeType} ${file.fileName}'.toLowerCase();
    if (lower.contains('pdf')) return CoresFolhio.coral;
    if (lower.contains('image')) return CoresFolhio.blue;
    if (_ehVideo(file)) return CoresFolhio.violet;
    if (lower.contains('word')) return CoresFolhio.violet;
    if (lower.contains('sheet')) return CoresFolhio.green;
    return CoresFolhio.orange;
  }

  String _nomeArquivoAmigavel(FolhioArquivoBiblioteca file) {
    final original = file.fileName.trim();
    final name = original.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
    final looksTechnical =
        name.length > 22 &&
        RegExp(r'^[a-f0-9_-]+$', caseSensitive: false).hasMatch(name);
    if (name.isEmpty || looksTechnical) {
      final lower = '${file.mimeType} $original'.toLowerCase();
      if (lower.contains('pdf')) return 'PDF importado';
      if (lower.contains('image') ||
          lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg')) {
        return 'Imagem importada';
      }
      if (lower.contains('word') || lower.endsWith('.docx')) {
        return 'Atividade sem titulo';
      }
      final date = file.updatedAt?.toLocal();
      if (date != null) {
        return 'Material de ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
      return 'Material importado';
    }
    return name;
  }

  String _nomeSemExtensao(String fileName) {
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
  }

  String _comExtensaoOriginal(String newName, String originalName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return '';
    final originalExtension =
        RegExp(r'(\.[^.]+)$').firstMatch(originalName)?.group(1) ?? '';
    if (originalExtension.isEmpty ||
        trimmed.toLowerCase().endsWith(originalExtension.toLowerCase())) {
      return trimmed;
    }
    return '$trimmed$originalExtension';
  }

  String _indicadorPara(FolhioArquivoBiblioteca file) {
    final lower = '${file.mimeType} ${file.fileName} ${file.folder}'
        .toLowerCase();
    if (lower.contains('template')) return 'Modelo';
    if (lower.contains('prova')) return 'Prova';
    if (lower.contains('atividade') ||
        lower.contains('word') ||
        lower.endsWith('.docx')) {
      return 'Atividade';
    }
    if (lower.contains('pdf') || lower.contains('image')) return 'Importado';
    return 'Material';
  }

  String _statusMaterialPara(FolhioArquivoBiblioteca file) {
    final lower = '${file.mimeType} ${file.fileName} ${file.folder}'
        .toLowerCase();
    if (lower.contains('publicado') || lower.contains('publicada')) {
      return 'Publicados';
    }
    if (lower.contains('pdf') ||
        lower.contains('image') ||
        lower.contains('import')) {
      return 'Importados';
    }
    final updated = file.updatedAt?.toLocal();
    if (updated != null) {
      final now = DateTime.now();
      if (now.difference(updated).inDays <= 7) return 'Recentes';
    }
    return 'Rascunhos';
  }

  List<String> _etiquetasPasta(String value) {
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .take(5)
        .toList();
  }

  bool _ehVideo(FolhioArquivoBiblioteca file) {
    final lower = '${file.mimeType} ${file.fileName}'.toLowerCase();
    return lower.contains('video') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.mpeg') ||
        lower.endsWith('.mpg') ||
        lower.endsWith('.mts') ||
        lower.endsWith('.m2ts') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.wmv') ||
        lower.endsWith('.flv');
  }

  String _dataRotulo(DateTime? value) {
    if (value == null) return 'recente';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}
