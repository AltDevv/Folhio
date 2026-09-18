part of 'google_integrations_screen.dart';

class IntegracaoGoogleDriveScreen extends StatefulWidget {
  const IntegracaoGoogleDriveScreen({super.key});

  @override
  State<IntegracaoGoogleDriveScreen> createState() =>
      _IntegracaoGoogleDriveScreenState();
}

class _IntegracaoGoogleDriveScreenState
    extends State<IntegracaoGoogleDriveScreen> {
  final IntegracoesGoogleController _controller =
      IntegracoesGoogleController();
  final PersistenciaLocalRepository _local = PersistenciaLocalRepository.instance;
  final FolhioApiGateway _api = FolhioApiGateway();

  bool _busy = false;
  String? _status;
  PlatformFile? _selectedFile;
  List<ArquivoGoogleDrive> _files = const [];
  List<_OpcaoPastaDrive> _folderOptions = const [_OpcaoPastaDrive.nenhum()];
  String _selectedFolderValue = '';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _api.fechar();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _carregarOpcoesPastasLocais();
    if (!mounted) return;
    await _executar(() async {
      await _controller.inicializar();
      final account = _controller.currentAccount;
      if (account != null) {
        await _salvarConexaoGoogleDrive(account.email);
        _files = await _controller.listarArquivosDrive();
      }
    }, quiet: true);
  }

  Future<void> _executar(
    Future<void> Function() action, {
    bool quiet = false,
  }) async {
    setState(() {
      _busy = true;
      if (!quiet) _status = null;
    });

    try {
      await action();
    } catch (error) {
      _status = _mensagemAmigavel(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _iniciarSessao() {
    return _executar(() async {
      final account = await _controller.iniciarSessao();
      await _salvarConexaoGoogleDrive(account.email);
      _files = await _controller.listarArquivosDrive();
      _status = 'Conta Google conectada.';
    });
  }

  Future<void> _encerrarSessao() {
    return _executar(() async {
      await _controller.encerrarSessao();
      await _limparConexaoGoogleDrive();
      _files = const [];
      _selectedFile = null;
      _status = 'Conta desconectada.';
    });
  }

  Future<void> _salvarConexaoGoogleDrive(String email) async {
    await _local.definirConfiguracao('google.drive.connected', 'true');
    await _local.definirConfiguracao('google.drive.email', email);
  }

  Future<void> _limparConexaoGoogleDrive() async {
    await _local.definirConfiguracao('google.drive.connected', 'false');
    await _local.definirConfiguracao('google.drive.email', '');
  }

  _OpcaoPastaDrive? get _selectedFolder {
    for (final option in _folderOptions) {
      if (option.value == _selectedFolderValue) return option;
    }
    return null;
  }

  Future<void> _carregarOpcoesPastasLocais() async {
    final options = <_OpcaoPastaDrive>[const _OpcaoPastaDrive.nenhum()];

    Future<void> coletar(String parentId, String prefix, int depth) async {
      if (depth > 4) return;
      final folders = await _api.listarPastasBiblioteca(
        parentId: parentId,
        limit: 200,
      );
      for (final folder in folders) {
        final label = prefix.isEmpty ? folder.name : '$prefix / ${folder.name}';
        options.add(
          _OpcaoPastaDrive(
            value: folder.id,
            label: label,
            driveFolderName: label,
          ),
        );
        await coletar(folder.id, label, depth + 1);
      }
    }

    try {
      await coletar('root', '', 0);
    } catch (_) {
      // A tela do Drive continua funcionando mesmo sem conseguir listar pastas locais.
    }

    if (!mounted) return;
    setState(() {
      _folderOptions = options;
      if (!_folderOptions.any(
        (option) => option.value == _selectedFolderValue,
      )) {
        _selectedFolderValue = '';
      }
    });
  }

  Future<void> _escolherArquivo() async {
    final result = await FilePicker.platform.pickFiles();
    final file = result?.files.single;
    if (file == null) {
      setState(() => _status = 'Escolha cancelada.');
      return;
    }

    setState(() {
      _selectedFile = file;
      _status = null;
    });
  }

  Future<void> _confirmarEnvio() {
    return _executar(() async {
      final file = _selectedFile;
      final path = file?.path;
      if (file == null || path == null) {
        _status = 'Escolha um arquivo antes de confirmar o envio.';
        return;
      }

      final uploaded = await _controller.enviarArquivoParaDrive(
        File(path),
        folderName: _selectedFolder?.driveFolderName,
      );
      _files = await _controller.listarArquivosDrive();
      _status = '${uploaded.name} enviado para o Google Drive.';
    });
  }

  Future<void> _renovar() {
    return _executar(() async {
      _files = await _controller.listarArquivosDrive();
      _status = 'Arquivos atualizados.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = _controller.currentAccount;

    return FolhioScaffold(
      title: 'Google Drive',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          _ContaCard(
            icon: Icons.drive_folder_upload,
            title: account == null ? 'Conectar Google Drive' : account.email,
            subtitle: account == null
                ? 'Entre para enviar e organizar arquivos.'
                : 'Conta conectada ao Folhio.',
            primaryLabel: account == null ? 'Entrar com Google' : 'Sair',
            onPrimaryTap: _busy
                ? null
                : account == null
                ? _iniciarSessao
                : _encerrarSessao,
          ),
          const SizedBox(height: 14),
          _SecaoCard(
            title: 'Enviar arquivo',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedFolderValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pasta da Biblioteca',
                ),
                items: [
                  for (final folder in _folderOptions)
                    DropdownMenuItem(
                      value: folder.value,
                      child: Text(
                        folder.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedFolderValue = value);
                      },
              ),
              const SizedBox(height: 12),
              _SecundarioButton(
                icon: Icons.attach_file,
                label: 'Escolher arquivo',
                enabled: !_busy,
                onTap: _escolherArquivo,
              ),
              const SizedBox(height: 10),
              _ArquivoSelecionadoBox(fileName: _selectedFile?.name),
              const SizedBox(height: 12),
              _PrincipalButton(
                icon: Icons.cloud_upload,
                label: 'Confirmar envio',
                enabled: !_busy && _selectedFile != null,
                onTap: _confirmarEnvio,
              ),
            ],
          ),
          _TextoStatus(message: _status),
          const TituloSecao('Arquivos recentes'),
          _LinhaAcoesPequena(
            label: 'Atualizar lista',
            enabled: !_busy,
            onTap: _renovar,
          ),
          const SizedBox(height: 8),
          if (_files.isEmpty)
            const _MensagemVazia('Nenhum arquivo carregado ainda.')
          else
            ..._files.map(
              (file) => _LinhaSimples(
                icon: _iconePorMime(file.mimeType),
                title: file.name,
                subtitle: file.createdTime == null
                    ? 'Google Drive'
                    : _formatarData(file.createdTime!),
              ),
            ),
        ],
      ),
    );
  }
}
