import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/rotas_folhio.dart';
import '../../style/estilo_folhio.dart';
import '../../security/authentication/autenticacao_controller.dart';
import '../../repository/local/persistencia_local_repository.dart';

class AberturaScreen extends StatefulWidget {
  const AberturaScreen({super.key});

  @override
  State<AberturaScreen> createState() => _AberturaScreenState();
}

class _AberturaScreenState extends State<AberturaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.55)),
    );
    _controller.forward();
    unawaited(_abrirProximaTela());
  }

  Future<void> _abrirProximaTela() async {
    final startedAt = DateTime.now();
    final signedIn = await AutenticacaoController.instance.restaurarSessaoArmazenada();
    unawaited(_concluirInicializacaoEmSegundoPlano());
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = const Duration(seconds: 1) - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted || _disposed) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      signedIn ? RotasFolhio.home : RotasFolhio.auth,
      (_) => false,
    );
  }

  Future<void> _concluirInicializacaoEmSegundoPlano() async {
    try {
      await Future.wait([
        AutenticacaoController.instance.restaurarSessao(),
        PersistenciaLocalRepository.instance.migrarCriptografiaLocalSeNecessario(),
      ]);
    } catch (_) {
      // Startup should not be blocked by cloud refresh or local maintenance.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return _IconeAplicativoBrilhante(progress: _controller.value);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IconeAplicativoBrilhante extends StatelessWidget {
  const _IconeAplicativoBrilhante({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const asset = 'assets/images/folhio_icon_transparent.png';
    const size = 152.0;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.contain),
            ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final center = -0.35 + (progress * 1.7);
                final start = (center - 0.18).clamp(0.0, 1.0);
                final middle = center.clamp(0.0, 1.0);
                final end = (center + 0.18).clamp(0.0, 1.0);

                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    CoresFolhio.cream.withValues(alpha: 0.92),
                    CoresFolhio.green.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: [
                    start,
                    middle,
                    (middle + ((end - middle) * 0.45)).clamp(0.0, 1.0),
                    end,
                  ],
                ).createShader(bounds);
              },
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
