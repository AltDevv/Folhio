import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../style/estilo_folhio.dart';
import '../../security/authentication/autenticacao_controller.dart';

class VerificacaoDoisFatoresScreen extends StatefulWidget {
  final String token;
  final String? destination;
  final Future<Object?> Function(String code)? onVerify;

  const VerificacaoDoisFatoresScreen({
    super.key,
    required this.token,
    this.destination,
    this.onVerify,
  });

  @override
  State<VerificacaoDoisFatoresScreen> createState() =>
      _VerificacaoDoisFatoresScreenState();
}

class _VerificacaoDoisFatoresScreenState
    extends State<VerificacaoDoisFatoresScreen>
    with WidgetsBindingObserver {
  final _auth = AutenticacaoController.instance;
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _code.addListener(_renovar);
    _focus.addListener(_renovar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarFocoCodigo());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarFocoCodigo());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _code.removeListener(_renovar);
    _focus.removeListener(_renovar);
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _renovar() {
    if (mounted) setState(() {});
  }

  void _solicitarFocoCodigo() {
    if (!mounted || _busy) return;
    FocusScope.of(context).requestFocus(_focus);
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  Future<void> _confirmar() async {
    final clean = _code.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 6) {
      setState(() => _error = 'Digite os 6 dígitos do código.');
      _solicitarFocoCodigo();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = widget.onVerify == null
          ? await _auth.verificarDoisFatores(token: widget.token, code: clean)
          : await widget.onVerify!(clean);
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is FolhioAutenticacaoException
            ? error.message
            : 'Não foi possível verificar o código.';
      });
      _solicitarFocoCodigo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    final destination = widget.destination?.trim().isNotEmpty == true
        ? widget.destination!.trim()
        : 'seu email';
    final code = _code.text.replaceAll(RegExp(r'\D'), '');
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/folhio_icon_transparent.png',
                        width: 34,
                        height: 34,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Folhio',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  _IlustracaoSeguranca(color: colors.primary),
                  const SizedBox(height: 28),
                  const Text(
                    'Verificação em 2 etapas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Digite o código de 6 dígitos enviado para o seu email para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _DestinoPill(destination: destination),
                  const SizedBox(height: 26),
                  _AreaEntradaCodigo(
                    controller: _code,
                    focusNode: _focus,
                    code: code,
                    busy: _busy,
                    onTap: _solicitarFocoCodigo,
                    onSubmitted: (_) => _busy ? null : _confirmar(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _busy ? null : _confirmar,
                    child: Text(_busy ? 'Verificando...' : 'Confirmar código'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Trocar email'),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.borderSoft),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Não recebeu? Verifique a caixa de spam. O email pode levar alguns minutos para chegar.',
                              style: TextStyle(
                                color: colors.muted,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaEntradaCodigo extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String code;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<String> onSubmitted;

  const _AreaEntradaCodigo({
    required this.controller,
    required this.focusNode,
    required this.code,
    required this.busy,
    required this.onTap,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < 6; index++)
                    _CodigoBox(
                      value: index < code.length ? code[index] : '',
                      active:
                          index == code.length && !busy && focusNode.hasFocus,
                    ),
                ],
              ),
            ),
            Positioned.fill(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                enabled: !busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onTap: onTap,
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodigoBox extends StatelessWidget {
  final String value;
  final bool active;

  const _CodigoBox({required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 48,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? colors.primary : colors.border,
          width: active ? 1.4 : 1,
        ),
      ),
      child: Text(
        value.isEmpty ? (active ? '|' : '') : value,
        style: TextStyle(
          color: value.isEmpty ? colors.primary : colors.text,
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DestinoPill extends StatelessWidget {
  final String destination;

  const _DestinoPill({required this.destination});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, color: colors.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Código enviado para ',
                      style: TextStyle(color: colors.muted),
                    ),
                    TextSpan(
                      text: destination,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IlustracaoSeguranca extends StatelessWidget {
  final Color color;

  const _IlustracaoSeguranca({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 124,
        height: 124,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
            ),
            Icon(Icons.mark_email_unread_outlined, color: color, size: 58),
            Positioned(
              right: 8,
              bottom: 14,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF073D2D),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
