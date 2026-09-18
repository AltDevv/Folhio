part of 'configuracoes_screen.dart';

class ConfiguracoesPerfilContaScreen extends StatefulWidget {
  const ConfiguracoesPerfilContaScreen({super.key});

  @override
  State<ConfiguracoesPerfilContaScreen> createState() =>
      _ConfiguracoesPerfilContaScreenState();
}

class _ConfiguracoesPerfilContaScreenState
    extends State<ConfiguracoesPerfilContaScreen> {
  final _viewModel = ConfiguracoesContaViewModel();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _emailPassword = TextEditingController();
  final _passwordCurrent = TextEditingController();
  final _passwordNew = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
    _sincronizarCamposConta();
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  void _sincronizarCamposConta() {
    _name.text = _viewModel.name;
    _email.text = _viewModel.email;
  }

  @override
  void dispose() {
    _viewModel.removeListener(_aoVisualizacaoModeloAlterado);
    _viewModel.dispose();
    _name.dispose();
    _email.dispose();
    _emailPassword.dispose();
    _passwordCurrent.dispose();
    _passwordNew.dispose();
    super.dispose();
  }

  bool get _isSaving => _viewModel.isSaving;

  void _iniciarEdicao(ModoEdicaoConta mode) {
    if (_isSaving) return;
    _viewModel.iniciarEdicao(mode);
    if (mode == ModoEdicaoConta.name) {
      _name.text = _viewModel.name;
    }
    if (mode == ModoEdicaoConta.email) {
      _email.text = _viewModel.email;
      _emailPassword.clear();
    }
    if (mode == ModoEdicaoConta.password) {
      _passwordCurrent.clear();
      _passwordNew.clear();
    }
  }

  void _cancelarEdicao() {
    if (_isSaving) return;
    _viewModel.cancelarEdicao();
    _sincronizarCamposConta();
    _limparCamposSensiveis();
  }

  void _limparCamposSensiveis() {
    _emailPassword.clear();
    _passwordCurrent.clear();
    _passwordNew.clear();
  }

  Future<void> _salvarNome() async {
    try {
      final message = await _viewModel.salvarNome(_name.text);
      if (!mounted) return;
      _sincronizarCamposConta();
      _avisar(context, message);
    } catch (error) {
      if (!mounted) return;
      _avisar(
        context,
        _mensagemErro(error, 'Não foi possível atualizar o nome.'),
      );
    }
  }

  Future<void> _salvarEmail() async {
    try {
      final message = await _viewModel.salvarEmail(
        email: _email.text,
        currentPassword: _emailPassword.text,
        confirmTwoFactor: (result, onCode) =>
            _confirmarCodigoConta(result: result, onCode: onCode),
      );
      if (!mounted) return;
      _sincronizarCamposConta();
      _emailPassword.clear();
      _avisar(context, message);
    } catch (error) {
      if (!mounted) return;
      _avisar(
        context,
        _mensagemErro(error, 'Não foi possível atualizar o email.'),
      );
    }
  }

  Future<void> _salvarSenha() async {
    try {
      final message = await _viewModel.salvarSenha(
        currentPassword: _passwordCurrent.text,
        newPassword: _passwordNew.text,
        confirmTwoFactor: (result, onCode) =>
            _confirmarCodigoConta(result: result, onCode: onCode),
      );
      if (!mounted) return;
      _limparCamposSensiveis();
      _avisar(context, message);
    } catch (error) {
      if (!mounted) return;
      _avisar(
        context,
        _mensagemErro(error, 'Não foi possível atualizar a senha.'),
      );
    }
  }

  Future<void> _solicitarRedefinicaoSenha() async {
    try {
      final message = await _viewModel.solicitarRedefinicaoSenha();
      if (!mounted) return;
      _avisar(context, message);
    } catch (error) {
      if (!mounted) return;
      _avisar(
        context,
        _mensagemErro(error, 'Não foi possível enviar o email de recuperação.'),
      );
    }
  }

  Future<void> _excluirConta() async {
    final currentPassword = await _confirmarExclusaoConta();
    if (currentPassword == null) return;
    try {
      final message = await _viewModel.excluirConta(
        currentPassword: currentPassword,
        confirmTwoFactor: (result, onCode) =>
            _confirmarCodigoConta(result: result, onCode: onCode),
      );
      if (!mounted) return;
      _avisar(context, message);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RotasFolhio.auth, (_) => false);
    } catch (error) {
      if (!mounted) return;
      _avisar(context, _mensagemErro(error, 'Não foi possível apagar a conta.'));
    }
  }

  Future<String?> _confirmarExclusaoConta() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Isso apaga sua conta Folhio, encerra suas sessões e remove seus dados sincronizados na nuvem. Essa ação não pode ser desfeita.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              decoration: const InputDecoration(labelText: 'Senha atual'),
              onSubmitted: (_) {
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(controller.text);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(dialogContext).unfocus();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () {
              FocusScope.of(dialogContext).unfocus();
              Navigator.of(dialogContext).pop(controller.text);
            },
            child: const Text('Apagar conta'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    controller.dispose();
    return result;
  }

  Future<FolhioResultadoAtualizacaoConta> _confirmarCodigoConta({
    required FolhioResultadoAtualizacaoConta result,
    required Future<FolhioResultadoAtualizacaoConta> Function(String code) onCode,
  }) async {
    final verified = await Navigator.of(context)
        .push<FolhioResultadoAtualizacaoConta>(
          MaterialPageRoute(
            builder: (_) => VerificacaoDoisFatoresScreen(
              token: result.twoFactorToken!,
              destination: result.twoFactorDestination,
              onVerify: (code) => onCode(code),
            ),
          ),
        );
    if (verified == null) {
      throw const FolhioAutenticacaoException('Confirmação em duas etapas cancelada.');
    }
    return verified;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    final displayName = _viewModel.displayName;
    final displayEmail = _viewModel.displayEmail;

    return _ConfiguracoesPagina(
      title: 'Conta e segurança',
      children: [
        FolhioCard(
          child: Row(
            children: [
              IconeArredondado(
                icon: Icons.person_outline,
                color: CoresFolhio.green,
                backgroundColor: CoresFolhio.greenSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _GrupoConfiguracoes(
          children: [
            _AcaoContaTile(
              icon: Icons.badge_outlined,
              title: 'Nome',
              subtitle: displayName,
              expanded: _viewModel.editMode == ModoEdicaoConta.name,
              onTap: () => _iniciarEdicao(ModoEdicaoConta.name),
              onCollapse: _cancelarEdicao,
            ),
            if (_viewModel.editMode == ModoEdicaoConta.name)
              _FormularioContaIntegrado(
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Como devo te chamar?',
                    ),
                  ),
                  _BotoesFormularioConta(
                    saving: _viewModel.savingName,
                    savingLabel: 'Salvando...',
                    actionLabel: 'Salvar nome',
                    onCancel: _cancelarEdicao,
                    onSubmit: _salvarNome,
                  ),
                ],
              ),
            _AcaoContaTile(
              icon: Icons.alternate_email,
              title: 'Email',
              subtitle: displayEmail,
              expanded: _viewModel.editMode == ModoEdicaoConta.email,
              onTap: () => _iniciarEdicao(ModoEdicaoConta.email),
              onCollapse: _cancelarEdicao,
            ),
            if (_viewModel.editMode == ModoEdicaoConta.email)
              _FormularioContaIntegrado(
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Novo email'),
                  ),
                  TextField(
                    controller: _emailPassword,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(labelText: 'Senha atual'),
                  ),
                  _BotoesFormularioConta(
                    saving: _viewModel.savingEmail,
                    savingLabel: 'Salvando...',
                    actionLabel: 'Trocar email',
                    onCancel: _cancelarEdicao,
                    onSubmit: _salvarEmail,
                  ),
                ],
              ),
            _AcaoContaTile(
              icon: Icons.lock_outline,
              title: 'Senha',
              subtitle: 'Altere a senha usada para entrar no Folhio.',
              expanded: _viewModel.editMode == ModoEdicaoConta.password,
              onTap: () => _iniciarEdicao(ModoEdicaoConta.password),
              onCollapse: _cancelarEdicao,
            ),
            if (_viewModel.editMode == ModoEdicaoConta.password)
              _FormularioContaIntegrado(
                children: [
                  TextField(
                    controller: _passwordCurrent,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(labelText: 'Senha atual'),
                  ),
                  TextField(
                    controller: _passwordNew,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                  ),
                  _BotoesFormularioConta(
                    saving: _viewModel.savingPassword,
                    savingLabel: 'Salvando...',
                    actionLabel: 'Trocar senha',
                    onCancel: _cancelarEdicao,
                    onSubmit: _salvarSenha,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _viewModel.sendingPasswordReset
                          ? null
                          : _solicitarRedefinicaoSenha,
                      icon: const Icon(Icons.lock_reset),
                      label: Text(
                        _viewModel.sendingPasswordReset
                            ? 'Enviando email...'
                            : 'Esqueci a senha',
                      ),
                    ),
                  ),
                ],
              ),
            const _SecaoDoisFatoresConta(),
          ],
        ),
        FolhioCard(
          borderColor: CoresFolhio.coral,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconeArredondado(
                    icon: Icons.delete_forever_outlined,
                    color: CoresFolhio.coral,
                    backgroundColor: colors.surfaceSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Apagar conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remove sua conta, sessões e dados sincronizados na nuvem. Use só se tiver certeza.',
                          style: TextStyle(color: colors.muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: _viewModel.savingDelete ? null : _excluirConta,
                  child: Text(
                    _viewModel.savingDelete
                        ? 'Apagando...'
                        : 'Apagar minha conta',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
