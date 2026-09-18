part of '../../screen/auth/autenticacao_screen.dart';

class _CabecalhoAutenticacao extends StatelessWidget {
  final String title;

  const _CabecalhoAutenticacao({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Column(
      children: [
        Center(
          child: Image.asset(
            'assets/images/folhio_icon_transparent.png',
            width: 92,
            height: 92,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Acesse sua conta para criar e trabalhar com seus materiais.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.muted,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _FormularioAutenticacaoCard extends StatelessWidget {
  final _ModoAutenticacao mode;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final bool showPassword;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onTogglePassword;

  const _FormularioAutenticacaoCard({
    required this.mode,
    required this.name,
    required this.email,
    required this.password,
    required this.busy,
    required this.showPassword,
    required this.buttonLabel,
    required this.onSubmit,
    required this.onGoogle,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      child: Column(
        children: [
          if (mode == _ModoAutenticacao.register) ...[
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (mode != _ModoAutenticacao.forgot) ...[
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: !showPassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onSubmit,
              child: Text(busy ? 'Aguarde...' : buttonLabel),
            ),
          ),
          if (mode != _ModoAutenticacao.forgot) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Entrar com Google'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MensagemAutenticacao extends StatelessWidget {
  final String? message;
  final ThemeData theme;

  const _MensagemAutenticacao({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}

class _LinksModoAutenticacao extends StatelessWidget {
  final _ModoAutenticacao mode;
  final bool busy;
  final VoidCallback onToggleLoginRegister;
  final VoidCallback onForgot;

  const _LinksModoAutenticacao({
    required this.mode,
    required this.busy,
    required this.onToggleLoginRegister,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        TextButton(
          onPressed: busy ? null : onToggleLoginRegister,
          child: Text(
            mode == _ModoAutenticacao.login ? 'Criar conta' : 'Já tenho conta',
          ),
        ),
        TextButton(
          onPressed: busy ? null : onForgot,
          child: const Text('Esqueci minha senha'),
        ),
      ],
    );
  }
}
