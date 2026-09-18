part of 'meus_arquivos_screen.dart';

extension _AcoesMateriaisBiblioteca on _MeusArquivosScreenState {
  Future<void> _escolherEEnviarArquivo() async {
    try {
      final picked = await FilePicker.platform.pickFiles(withData: true);
      final pickedFile = picked?.files.single;
      final path = pickedFile?.path;
      final folder = _path.isEmpty ? _rootMaterialsLabel : _path.last.name;
      if (path != null) {
        await _viewModel.salvarArquivoLocal(
          File(path),
          fileName: pickedFile?.name,
          folderId: _currentFolderId,
          folder: folder,
          search: _searchController.text,
        );
      } else if (pickedFile?.bytes != null) {
        await _viewModel.salvarArquivoGerado(
          FolhioArquivoGerado(
            fileName: pickedFile!.name,
            mimeType: 'application/octet-stream',
            bytes: pickedFile.bytes!,
          ),
          folderId: _currentFolderId,
          folder: folder,
          search: _searchController.text,
        );
      } else {
        throw const FolhioExibicaoUsuarioException(
          'Nao foi possivel acessar esse arquivo. Escolha outro arquivo ou outra pasta.',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material salvo na Biblioteca.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
      );
    }
  }

  Future<void> _visualizarArquivo(FolhioArquivoBiblioteca file) async {
    try {
      final prepared = await _viewModel.prepararArquivo(file);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              _PreviaArquivoBibliotecaScreen(source: file, file: prepared),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
      );
    }
  }

  Future<void> _editarArquivoVisualmente(FolhioArquivoBiblioteca file) async {
    try {
      final prepared = await _viewModel.prepararArquivo(file);
      final localPath = prepared.localPath;
      if (localPath == null || localPath.trim().isEmpty) {
        throw const FolhioExibicaoUsuarioException(
          'Não foi possível preparar esse arquivo para edição.',
        );
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              EdicaoImagemScreen(showBack: true, initialFile: File(localPath)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
      );
    }
  }

  Future<void> _criarPasta() async {
    final data = await _dialogoPasta();
    if (data == null) return;
    try {
      await _viewModel.criarPasta(
        input: EntradaPastaBiblioteca(
          name: data.name,
          tags: data.tags,
          notes: data.notes,
          links: data.links,
        ),
        parentId: _currentFolderId,
        search: _searchController.text,
      );
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<void> _editarPasta(FolhioPastaBiblioteca folder) async {
    final data = await _dialogoPasta(folder: folder);
    if (data == null) return;
    try {
      await _viewModel.atualizarPasta(
        folder,
        input: EntradaPastaBiblioteca(
          name: data.name,
          tags: data.tags,
          notes: data.notes,
          links: data.links,
        ),
        currentParentId: _currentFolderId ?? 'root',
        search: _searchController.text,
      );
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<void> _excluirPasta(FolhioPastaBiblioteca folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar pasta?'),
        content: Text(
          'A pasta "${folder.name}" será apagada. Os materiais dentro dela voltam para Meus materiais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _viewModel.excluirPasta(
        folder,
        currentParentId: _currentFolderId ?? 'root',
        search: _searchController.text,
      );
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<void> _moverArquivo(FolhioArquivoBiblioteca file) async {
    try {
      final folders = await _viewModel.arvorePastas();
      if (!mounted) return;

      _DestinoMovimentacao? target;
      if (folders.isEmpty) {
        target = await _dialogoSemDestinosMovimentacao();
      } else {
        target = await showDialog<_DestinoMovimentacao>(
          context: context,
          builder: (context) =>
              _MovimentacaoArquivoDialog(file: file, currentPath: _path, folders: folders),
        );
      }
      if (target == null) return;

      if (target.createFolder) {
        final data = await _dialogoPasta();
        if (data == null) return;
        final folder = await _viewModel.criarPasta(
          input: EntradaPastaBiblioteca(
            name: data.name,
            tags: data.tags,
            notes: data.notes,
            links: data.links,
          ),
          parentId: _currentFolderId,
          search: _searchController.text,
        );
        await _viewModel.moverArquivo(
          file,
          folderId: folder.id,
          folder: folder.name,
          currentParentId: _currentFolderId ?? 'root',
          search: _searchController.text,
        );
      } else {
        await _viewModel.moverArquivo(
          file,
          folderId: target.folderId,
          folder: target.folderName,
          currentParentId: _currentFolderId ?? 'root',
          search: _searchController.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material movido.')));
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<void> _renomearArquivo(FolhioArquivoBiblioteca file) async {
    final newBaseName = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RenomeacaoArquivoDialog(initialName: _nomeSemExtensao(file.fileName)),
    );
    if (newBaseName == null) return;
    final resolvedName = _comExtensaoOriginal(newBaseName, file.fileName);
    if (resolvedName.trim().isEmpty || resolvedName == file.fileName) return;
    try {
      await _viewModel.renomearArquivo(
        file,
        fileName: resolvedName,
        currentParentId: _currentFolderId ?? 'root',
        search: _searchController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material renomeado.')));
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<void> _excluirArquivo(FolhioArquivoBiblioteca file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir material?'),
        content: Text(
          'O material "${file.fileName}" será removido da Biblioteca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _viewModel.excluirArquivo(
        file,
        currentParentId: _currentFolderId ?? 'root',
        search: _searchController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material excluído.')));
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<void> _alternarFavorito(FolhioArquivoBiblioteca file) async {
    try {
      final favorite = await _viewModel.alternarFavorito(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favorite
                ? 'Material adicionado aos favoritos.'
                : 'Material removido dos favoritos.',
          ),
        ),
      );
    } catch (error) {
      _mostrarErro(error);
    }
  }

  Future<_DestinoMovimentacao?> _dialogoSemDestinosMovimentacao() {
    return showDialog<_DestinoMovimentacao>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mover material'),
        content: const Text(
          'Você ainda não tem pastas. Deseja criar uma agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, const _DestinoMovimentacao.criarPasta()),
            child: const Text('Criar pasta'),
          ),
        ],
      ),
    );
  }

  Future<_FormularioPasta?> _dialogoPasta({FolhioPastaBiblioteca? folder}) {
    return showDialog<_FormularioPasta>(
      context: context,
      builder: (context) => _FormularioPastaDialog(folder: folder),
    );
  }

  void _abrirPasta(FolhioPastaBiblioteca folder) {
    _renovar(() {
      _path.add(folder);
    });
    _carregarConteudo();
  }

  void _abrirModelo(DetalhesModelo template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalhesModeloScreen(template: template),
      ),
    );
  }

  void _voltarPastaAnterior() {
    if (_path.isEmpty) return;
    _renovar(() {
      _path.removeLast();
    });
    _carregarConteudo();
  }

  void _mostrarErro(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
    );
  }
}
