import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screen/ai/ia_screen.dart';
import '../screen/auth/autenticacao_screen.dart';
import '../screen/converter/conversor_screen.dart';
import '../screen/create/criacao_screen.dart';
import '../screen/edit/edicao_screen.dart';
import '../screen/home/inicio_screen.dart';
import '../screen/library/meus_arquivos_screen.dart';
import '../screen/auth/apresentacao_screen.dart';
import '../screen/auth/abertura_screen.dart';
import '../screen/tools/ferramentas_screen.dart';
import '../controller/settings/aparencia_controller.dart';
import '../config/rotas_folhio.dart';
import '../style/estilo_folhio.dart';

class FolhioApp extends StatefulWidget {
  const FolhioApp({super.key});

  @override
  State<FolhioApp> createState() => _FolhioAppState();
}

class _FolhioAppState extends State<FolhioApp> {
  final AparenciaController _appearance =
      AparenciaController.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Folhio',
          debugShowCheckedModeBanner: false,
          theme: EstiloFolhio.tema(
            brightness: Brightness.light,
            accentColor: _appearance.accentColor,
            highContrast: _appearance.highContrast,
          ),
          darkTheme: EstiloFolhio.tema(
            brightness: Brightness.dark,
            accentColor: _appearance.accentColor,
            highContrast: _appearance.highContrast,
          ),
          themeMode: _appearance.themeMode,
          builder: (context, child) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final systemStyle =
                (isDark
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(
                      statusBarColor: theme.scaffoldBackgroundColor,
                      systemNavigationBarColor: theme.scaffoldBackgroundColor,
                      statusBarIconBrightness: isDark
                          ? Brightness.light
                          : Brightness.dark,
                      systemNavigationBarIconBrightness: isDark
                          ? Brightness.light
                          : Brightness.dark,
                      systemNavigationBarContrastEnforced: false,
                    );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: systemStyle,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_appearance.textScale),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          initialRoute: RotasFolhio.splash,
          routes: {
            RotasFolhio.splash: (_) => const AberturaScreen(),
            RotasFolhio.auth: (_) => const AutenticacaoScreen(),
            RotasFolhio.home: (_) => const InicioScreen(),
            RotasFolhio.onboarding: (_) => const ApresentacaoScreen(),
            RotasFolhio.converter: (_) => const ConversorScreen(),
            RotasFolhio.edit: (_) => const EdicaoScreen(),
            RotasFolhio.tools: (_) => const FerramentasScreen(),
            RotasFolhio.ai: (_) => const IaScreen(),
            RotasFolhio.create: (_) => const CriacaoScreen(),
            RotasFolhio.library: (_) => const MeusArquivosScreen(showBack: false),
          },
        );
      },
    );
  }
}
