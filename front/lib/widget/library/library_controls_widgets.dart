part of '../../screen/library/meus_arquivos_screen.dart';

class _MovimentacaoArquivoDialog extends StatelessWidget {
  final FolhioArquivoBiblioteca file;
  final List<FolhioPastaBiblioteca> currentPath;
  final List<OpcaoDestinoPastaBiblioteca> folders;

  const _MovimentacaoArquivoDialog({
    required this.file,
    required this.currentPath,
    required this.folders,
  });

  @override
  Widget build(BuildContext context) {
    final currentFolderId = currentPath.isEmpty ? null : currentPath.last.id;
    final parentFolder = currentPath.length >= 2
        ? currentPath[currentPath.length - 2]
        : null;
    final canMoveUp =
        currentPath.isNotEmpty && file.folderId == currentFolderId;
    final availableFolders = folders
        .where((option) => option.folder.id != file.folderId)
        .toList();

    return AlertDialog(
      title: const Text('Mover material'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (canMoveUp) ...[
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.arrow_upward,
                    color: CoresFolhio.green,
                  ),
                  title: const Text('Voltar um nivel'),
                  subtitle: Text(
                    parentFolder == null
                        ? _rootMaterialsLabel
                        : parentFolder.name,
                  ),
                  onTap: () => Navigator.pop(
                    context,
                    _DestinoMovimentacao(
                      folderId: parentFolder?.id,
                      folderName: parentFolder?.name ?? _rootMaterialsLabel,
                    ),
                  ),
                ),
              ],
              if (file.folderId != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.drive_folder_upload_outlined,
                    color: CoresFolhio.orange,
                  ),
                  title: const Text('Retirar da pasta'),
                  subtitle: const Text('Mover para Meus materiais'),
                  onTap: () => Navigator.pop(
                    context,
                    const _DestinoMovimentacao(folderName: _rootMaterialsLabel),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Pastas',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).extension<CoresTemaFolhio>()!.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              if (availableFolders.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'N�o h� outras pastas dispon�veis.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).extension<CoresTemaFolhio>()!.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...availableFolders.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.folder,
                      color: CoresFolhio.orange,
                    ),
                    title: Text(option.folder.name),
                    subtitle: Text(option.label),
                    onTap: () => Navigator.pop(
                      context,
                      _DestinoMovimentacao(
                        folderId: option.folder.id,
                        folderName: option.folder.name,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, const _DestinoMovimentacao.criarPasta()),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Criar pasta'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _DestinoMovimentacao {
  final String? folderId;
  final String folderName;
  final bool createFolder;

  const _DestinoMovimentacao({this.folderId, required this.folderName})
    : createFolder = false;

  const _DestinoMovimentacao.criarPasta()
    : folderId = null,
      folderName = _rootMaterialsLabel,
      createFolder = true;
}

class _BarraBuscaBibliotecaFlutuante extends StatelessWidget {
  final bool visible;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final bool filterActive;

  const _BarraBuscaBibliotecaFlutuante({
    required this.visible,
    required this.controller,
    required this.onSearch,
    this.onFilterTap,
    this.onChanged,
    this.filterActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Positioned(
      left: 16,
      right: 16,
      top: 8,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : const Offset(0, -0.2),
          child: AnimatedOpacity(
            key: const Key('library-floating-template-search'),
            duration: const Duration(milliseconds: 160),
            opacity: visible ? 1 : 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _BarraBuscaBiblioteca(
                  controller: controller,
                  onSearch: onSearch,
                  onFilterTap: onFilterTap,
                  onChanged: onChanged,
                  filterActive: filterActive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraBuscaBiblioteca extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final bool filterActive;

  const _BarraBuscaBiblioteca({
    required this.controller,
    required this.onSearch,
    this.onFilterTap,
    this.onChanged,
    this.filterActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: (_) => onSearch(),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar modelos ou materiais...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 52,
          child: OutlinedButton(
            onPressed: onFilterTap ?? onSearch,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: Icon(
              Icons.tune,
              color: filterActive ? colors.primary : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroducaoBiblioteca extends StatelessWidget {
  const _IntroducaoBiblioteca();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Encontre modelos prontos e seus materiais salvos.',
        style: TextStyle(
          color: context.folhioColors.muted,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AbasBiblioteca extends StatelessWidget {
  final _AbaBiblioteca selected;
  final ValueChanged<_AbaBiblioteca> onSelected;

  const _AbasBiblioteca({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BibliotecaAbaChip(
              icon: Icons.auto_awesome,
              label: 'Modelos',
              selected: selected == _AbaBiblioteca.templates,
              onTap: () => onSelected(_AbaBiblioteca.templates),
            ),
            _BibliotecaAbaChip(
              icon: Icons.collections_bookmark_outlined,
              label: 'Meus materiais',
              selected: selected == _AbaBiblioteca.files,
              onTap: () => onSelected(_AbaBiblioteca.files),
            ),
          ],
        ),
      ),
    );
  }
}

class _BibliotecaAbaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BibliotecaAbaChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colors.primary : colors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BibliotecaFilterFaixa extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _BibliotecaFilterFaixa({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: options.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ChoiceChip(
                selected: selected == null,
                label: const Text('Todos'),
                onSelected: (_) => onSelected(null),
              );
            }
            final option = options[index - 1];
            return ChoiceChip(
              selected: selected == option,
              label: Text(option),
              onSelected: (_) => onSelected(option),
            );
          },
        ),
      ),
    );
  }
}

class _FaixaEtiquetasBiblioteca extends StatelessWidget {
  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  const _FaixaEtiquetasBiblioteca({
    required this.tags,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tags.length + (selected.isEmpty ? 0 : 1),
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (selected.isNotEmpty && index == 0) {
              return ActionChip(
                avatar: const Icon(Icons.close, size: 16),
                label: const Text('Limpar'),
                onPressed: () {
                  for (final tag in selected.toList()) {
                    onSelected(tag);
                  }
                },
              );
            }
            final tag = tags[index - (selected.isEmpty ? 0 : 1)];
            final isSelected = selected.any(
              (item) => item.toLowerCase() == tag.toLowerCase(),
            );
            return ChoiceChip(
              selected: isSelected,
              avatar: Icon(
                tag == _favoriteTag ? Icons.star_border : Icons.sell_outlined,
                size: 16,
              ),
              label: Text(tag),
              onSelected: (_) => onSelected(tag),
            );
          },
        ),
      ),
    );
  }
}

class _FiltrosModelosAtivos extends StatelessWidget {
  final String? access;
  final Set<String> tags;
  final VoidCallback onClear;

  const _FiltrosModelosAtivos({
    required this.access,
    required this.tags,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final accessLabel = access == null ? null : _rotuloAcessoModelo(access!);
    final labels = [?accessLabel, ...tags];
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in labels)
            Chip(
              label: Text(label),
              avatar: const Icon(Icons.tune, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ActionChip(label: const Text('Limpar filtros'), onPressed: onClear),
        ],
      ),
    );
  }
}
