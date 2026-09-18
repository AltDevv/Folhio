import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/rotas_folhio.dart';
import '../../style/estilo_folhio.dart';
import '../../security/authentication/autenticacao_controller.dart';
import '../../widget/cards.dart';
import 'verificacao_dois_fatores_screen.dart';

part '../../widget/auth/auth_screen_widgets.dart';
part 'configuracao_conta_google_screen.dart';

enum _ModoAutenticacao { login, register, forgot }

class AutenticacaoScreen extends StatefulWidget {
  const AutenticacaoScreen({super.key});

  @override
  State<AutenticacaoScreen> createState() => _AutenticacaoScreenState();
}

class _AutenticacaoScreenState extends State<AutenticacaoScreen> {
  final _auth = AutenticacaoController.instance;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _ModoAutenticacao _mode = _ModoAutenticacao.login;
  bool _busy = false;
  bool _showPassword = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_mode == _ModoAutenticacao.login) {
        final result = await _auth.entrar(
          email: _email.text.trim(),
          password: _password.text,
        );
        await _concluirAutenticacao(result);
      } else if (_mode == _ModoAutenticacao.register) {
        await _auth.cadastrar(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
        _abrirInicio();
      } else {
        await _auth.esqueciSenha(_email.text.trim());
        setState(
          () => _message =
              'Se o email estiver cadastrado, enviaremos instruções de recuperação.',
        );
      }
    } catch (error) {
      setState(
        () => _message = error is FolhioAutenticacaoException
            ? error.message
            : 'Não foi possível continuar.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await _auth.entrarComGoogle();
      await _concluirAutenticacao(result);
    } catch (error) {
      setState(
        () => _message = error is FolhioAutenticacaoException
            ? error.message
            : 'Não foi possível entrar com Google.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _concluirAutenticacao(ResultadoAutenticacaoFolhio result) async {
    var completed = result;
    if (!completed.signedIn && completed.twoFactorToken != null) {
      final verified = await Navigator.of(context).push<ResultadoAutenticacaoFolhio>(
        MaterialPageRoute(
          builder: (_) => VerificacaoDoisFatoresScreen(
            token: completed.twoFactorToken!,
            destination: completed.twoFactorDestination,
          ),
        ),
      );
      if (verified == null) return;
      completed = verified;
    }
    if (completed.needsNameConfirmation) {
      if (!mounted) return;
      final setup = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ConfiguracaoContaGoogleScreen()),
      );
      if (setup != true) return;
    }
    _abrirInicio();
  }

  void _abrirInicio() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(RotasFolhio.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (_mode) {
      _ModoAutenticacao.login => 'Entrar no Folhio',
      _ModoAutenticacao.register => 'Criar conta',
      _ModoAutenticacao.forgot => 'Recuperar senha',
    };
    final button = switch (_mode) {
      _ModoAutenticacao.login => 'Entrar',
      _ModoAutenticacao.register => 'Criar conta',
      _ModoAutenticacao.forgot => 'Enviar email',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_mode != _ModoAutenticacao.login) {
          setState(() {
            _mode = _ModoAutenticacao.login;
            _message = null;
          });
          return;
        }
        SystemNavigator.pop();
      },
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
                    _CabecalhoAutenticacao(title: title),
                    _FormularioAutenticacaoCard(
                      mode: _mode,
                      name: _name,
                      email: _email,
                      password: _password,
                      busy: _busy,
                      showPassword: _showPassword,
                      buttonLabel: button,
                      onSubmit: _enviar,
                      onGoogle: _google,
                      onTogglePassword: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                    _MensagemAutenticacao(message: _message, theme: theme),
                    _LinksModoAutenticacao(
                      mode: _mode,
                      busy: _busy,
                      onToggleLoginRegister: () {
                        setState(
                          () => _mode = _mode == _ModoAutenticacao.login
                              ? _ModoAutenticacao.register
                              : _ModoAutenticacao.login,
                        );
                      },
                      onForgot: () => setState(() => _mode = _ModoAutenticacao.forgot),
                    ),
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
