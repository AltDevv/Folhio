part of 'autenticacao_screen.dart';

class ConfiguracaoContaGoogleScreen extends StatefulWidget {
  const ConfiguracaoContaGoogleScreen({super.key});

  @override
  State<ConfiguracaoContaGoogleScreen> createState() =>
      _ConfiguracaoContaGoogleScreenState();
}

class _ConfiguracaoContaGoogleScreenState extends State<ConfiguracaoContaGoogleScreen> {
  final _auth = AutenticacaoController.instance;
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = _auth.user?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    final name = _name.text.trim();
    final password = _password.text;
    final confirmation = _passwordConfirm.text;
    if (name.isEmpty) {
      setState(() => _error = 'Informe como devemos te chamar.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'A senha precisa ter pelo menos 8 caracteres.');
      return;
    }
    if (!RegExp(r'^(?=.*\p{L})(?=.*\d).+$', unicode: true).hasMatch(password)) {
      setState(() => _error = 'Use letras e números na senha.');
      return;
    }
    if (password != confirmation) {
      setState(() => _error = 'As senhas não conferem.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.atualizarConta(name: name, newPassword: password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is FolhioAutenticacaoException
            ? error.message
            : 'Não foi possível finalizar seu cadastro.';
      });
    }
  }

  Future<void> _cancelar() async {
    await _auth.encerrarSessao(localOnly: true);
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Sair',
                        onPressed: _busy ? null : _cancelar,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Image.asset(
                        'assets/images/folhio_icon_transparent.png',
                        width: 82,
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Finalize sua conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Antes de começar, escolha como devemos te chamar e crie uma senha para entrar no Folhio também sem o Google.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.muted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FolhioCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            enabled: !_busy,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 120,
                            decoration: const InputDecoration(
                              labelText: 'Como devo te chamar?',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: !_showPassword,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Senha do Folhio',
                              helperText:
                                  'Mínimo de 8 caracteres com letras e números.',
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _showPassword = !_showPassword,
                                      ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordConfirm,
                            enabled: !_busy,
                            obscureText: !_showPassword,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _busy ? null : (_) => _concluir(),
                            decoration: const InputDecoration(
                              labelText: 'Confirmar senha',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _concluir,
                              child: Text(_busy ? 'Salvando...' : 'Continuar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
