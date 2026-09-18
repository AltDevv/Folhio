part of 'configuracoes_screen.dart';

class _AcaoContaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onCollapse;

  const _AcaoContaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return FolhioItemLista(
      icon: icon,
      iconColor: CoresFolhio.green,
      iconBackground: colors.surfaceSoft,
      title: title,
      subtitle: subtitle,
      trailing: expanded
          ? IconButton(
              tooltip: 'Cancelar edição',
              onPressed: onCollapse ?? onTap,
              icon: Icon(Icons.expand_less, color: colors.muted),
            )
          : Icon(Icons.chevron_right, color: colors.muted),
      onTap: onTap,
    );
  }
}

class _FormularioContaIntegrado extends StatelessWidget {
  final List<Widget> children;

  const _FormularioContaIntegrado({required this.children});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _BotoesFormularioConta extends StatelessWidget {
  final bool saving;
  final String savingLabel;
  final String actionLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _BotoesFormularioConta({
    required this.saving,
    required this.savingLabel,
    required this.actionLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : onCancel,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: saving ? null : onSubmit,
            child: Text(saving ? savingLabel : actionLabel),
          ),
        ),
      ],
    );
  }
}

class _SecaoDoisFatoresConta extends StatefulWidget {
  const _SecaoDoisFatoresConta();

  @override
  State<_SecaoDoisFatoresConta> createState() =>
      _SecaoDoisFatoresContaState();
}

class _SecaoDoisFatoresContaState extends State<_SecaoDoisFatoresConta> {
  final _auth = AutenticacaoController.instance;
  bool _twoFactorEnabled = false;
  bool _emailAvailable = false;
  bool _loading = true;
  bool _saving = false;
  String? _savingMessage;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!_auth.isSignedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final settings = await _auth.configuracoesDoisFatores();
      if (!mounted) return;
      setState(() {
        _twoFactorEnabled = settings.enabled;
        _emailAvailable = settings.emailAvailable;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _avisar(context, 'Não foi possível carregar a segurança da conta.');
    }
  }

  Future<void> _definirDoisFatores(bool value) async {
    if (value && !_emailAvailable) {
      _avisar(
        context,
        'O envio de email de segurança ainda não está configurado no servidor.',
      );
      return;
    }
    String? currentPassword;
    if (!value && _twoFactorEnabled) {
      currentPassword = await _solicitarSenhaAtual();
      if (currentPassword == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
    }
    setState(() {
      _saving = true;
      _savingMessage = value
          ? 'Ativando verificação em duas etapas...'
          : 'Enviando código de confirmação para seu email...';
    });
    try {
      var settings = await _auth.atualizarConfiguracoesDoisFatores(
        enabled: value,
        currentPassword: currentPassword,
      );
      if (!mounted) return;
      if (settings.twoFactorRequired && settings.twoFactorToken != null) {
        setState(() {
          _saving = false;
          _savingMessage = null;
        });
        await Future<void>.delayed(const Duration(milliseconds: 160));
        if (!mounted) return;
        final verified = await Navigator.of(context)
            .push<FolhioConfiguracoesDoisFatores>(
              MaterialPageRoute(
                builder: (_) => VerificacaoDoisFatoresScreen(
                  token: settings.twoFactorToken!,
                  destination: settings.twoFactorDestination,
                  onVerify: (code) => _auth.atualizarConfiguracoesDoisFatores(
                    enabled: value,
                    currentPassword: currentPassword,
                    twoFactorToken: settings.twoFactorToken,
                    twoFactorCode: code,
                  ),
                ),
              ),
            );
        if (verified == null) {
          throw const FolhioAutenticacaoException(
            'Confirmação em duas etapas cancelada.',
          );
        }
        settings = verified;
      }
      if (!mounted) return;
      setState(() {
        _twoFactorEnabled = settings.enabled;
        _emailAvailable = settings.emailAvailable;
        _savingMessage = null;
      });
      _avisar(
        context,
        settings.enabled
            ? 'Verificação em duas etapas ativada.'
            : 'Verificação em duas etapas desativada.',
      );
    } catch (error) {
      if (!mounted) return;
      _avisar(
        context,
        error is FolhioAutenticacaoException
            ? error.message
            : 'Não foi possível salvar a segurança da conta.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _savingMessage = null;
        });
      }
    }
  }

  Future<String?> _solicitarSenhaAtual() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar senha'),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(dialogContext).unfocus();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              FocusScope.of(dialogContext).unfocus();
              Navigator.of(dialogContext).pop(controller.text);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    controller.dispose();
    return result?.trim().isEmpty == true ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConfiguracaoAlternancia(
            title: 'Verificação em duas etapas por email',
            value: _twoFactorEnabled,
            onChanged: _saving ? null : _definirDoisFatores,
          ),
          if (_savingMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _savingMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _twoFactorEnabled
                ? 'Ao entrar novamente, o Folhio vai pedir um código enviado para ${_auth.user?.email ?? 'seu email'}.'
                : _emailAvailable
                ? 'Ative para exigir um código por email antes de liberar a sessão.'
                : 'O servidor precisa de SMTP configurado para enviar códigos por email.',
            style: TextStyle(color: colors.muted, height: 1.35, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
