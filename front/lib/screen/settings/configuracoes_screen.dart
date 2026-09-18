import 'package:flutter/material.dart';

import '../../config/rotas_folhio.dart';
import '../../style/estilo_folhio.dart';
import '../../security/authentication/autenticacao_controller.dart';
import '../../model/settings/settings_models.dart';
import '../../controller/settings/configuracoes_acessibilidade_view_model.dart';
import '../../controller/settings/configuracoes_conta_view_model.dart';
import '../../controller/settings/configuracoes_aparencia_view_model.dart';
import '../../controller/settings/configuracoes_view_model.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import 'seguranca_backup_screen.dart';
import '../auth/verificacao_dois_fatores_screen.dart';

part 'appearance_accessibility_settings_screen.dart';
part 'account_settings_screens.dart';
part 'configuracoes_seguranca_conta_screen.dart';
part 'account_settings_widgets.dart';
part 'configuracoes_privacidade_screen.dart';
part 'plans_settings_screen.dart';
part 'configuracoes_ajuda_screen.dart';
part 'settings_shared_widgets.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _viewModel = ConfiguracoesViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
    _viewModel.carregarResumo();
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_aoVisualizacaoModeloAlterado);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _carregarResumo() async {
    await _viewModel.carregarResumo();
  }

  void _abrir(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .then((_) => _carregarResumo());
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Configurações',
      currentIndex: 0,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/folhio_icon_transparent.png',
                    width: 54,
                    height: 54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _viewModel.profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const TituloSecao('Preferências'),
          _MenuConfiguracoesTile(
            icon: Icons.palette_outlined,
            iconColor: CoresFolhio.blue,
            title: 'Aparência',
            subtitle: 'Tema e cor principal',
            onTap: () => _abrir(const ConfiguracoesAparenciaScreen()),
          ),
          _MenuConfiguracoesTile(
            icon: Icons.accessibility_new_outlined,
            iconColor: CoresFolhio.violet,
            title: 'Acessibilidade',
            subtitle: 'Fonte, contraste e conforto de leitura',
            onTap: () => _abrir(const ConfiguracoesAcessibilidadeScreen()),
          ),
          const TituloSecao('Conta e backup'),
          _MenuConfiguracoesTile(
            icon: Icons.account_circle_outlined,
            iconColor: CoresFolhio.green,
            title: 'Conta e segurança',
            subtitle: 'Nome, email, senha e verificação em duas etapas',
            onTap: () => _abrir(const ConfiguracoesPerfilContaScreen()),
          ),
          _MenuConfiguracoesTile(
            icon: Icons.shield_outlined,
            iconColor: CoresFolhio.green,
            title: 'Backup',
            subtitle: 'Sessão, proteção e exportação de dados',
            onTap: () => _abrir(const SegurancaBackupScreen()),
          ),
          _MenuConfiguracoesTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: CoresFolhio.blue,
            title: 'Privacidade',
            subtitle: 'Logs, permissões e coleta mínima',
            onTap: () => _abrir(const ConfiguracoesPrivacidadeScreen()),
          ),
          const TituloSecao('App'),
          _MenuConfiguracoesTile(
            icon: Icons.workspace_premium_outlined,
            iconColor: CoresFolhio.orange,
            title: 'Planos',
            subtitle: 'Free, Pro, Ultra e Escolar',
            onTap: () => _abrir(const PlanosScreen()),
          ),
          _MenuConfiguracoesTile(
            icon: Icons.help_outline,
            iconColor: CoresFolhio.green,
            title: 'Ajuda e sobre',
            subtitle: 'Dúvidas rápidas, versão e suporte',
            onTap: () => _abrir(const ConfiguracoesAjudaScreen()),
          ),
          _MenuConfiguracoesTile(
            icon: Icons.logout,
            iconColor: CoresFolhio.coral,
            title: 'Sair da conta',
            subtitle: 'Encerrar sessão neste aparelho',
            onTap: () async {
              await _viewModel.encerrarSessao();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(RotasFolhio.auth, (_) => false);
            },
          ),
        ],
      ),
    );
  }
}
