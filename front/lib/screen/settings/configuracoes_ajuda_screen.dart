part of 'configuracoes_screen.dart';

class ConfiguracoesAjudaScreen extends StatelessWidget {
  const ConfiguracoesAjudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    final topics = _topicosAjuda(context);
    return _ConfiguracoesPagina(
      title: 'Ajuda',
      children: [
        for (final topic in topics)
          _MenuConfiguracoesTile(
            icon: topic.icon,
            iconColor: topic.color,
            title: topic.title,
            subtitle: topic.subtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _TopicoAjudaScreen(topic: topic),
              ),
            ),
          ),
        FolhioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Folhio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text('Versão 1.0.0', style: TextStyle(color: colors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

List<_TopicoAjuda> _topicosAjuda(BuildContext context) {
  return [
    _TopicoAjuda(
      icon: Icons.rocket_launch_outlined,
      color: CoresFolhio.green,
      title: 'Primeiros passos',
      subtitle: 'Crie, salve e compartilhe seu primeiro material.',
      bullets: const [
        'Comece pela aba Criar para gerar uma atividade, prova ou plano.',
        'Revise o resultado antes de salvar ou exportar.',
        'Compartilhe o arquivo salvo quando quiser entregar materiais para alunos.',
      ],
      actions: [
        _AcaoAjuda(
          label: 'Abrir Criar',
          icon: Icons.auto_awesome_outlined,
          onTap: (context) =>
              Navigator.of(context).pushNamed(RotasFolhio.create),
        ),
      ],
    ),
    _TopicoAjuda(
      icon: Icons.folder_open_outlined,
      color: CoresFolhio.blue,
      title: 'Biblioteca e arquivos',
      subtitle: 'Importe, organize e encontre seus materiais.',
      bullets: const [
        'A Biblioteca guarda materiais criados, importados e convertidos.',
        'Use pastas para separar turmas, disciplinas ou projetos.',
        'Favoritos ajudam a deixar materiais frequentes mais fáceis de achar.',
      ],
      actions: [
        _AcaoAjuda(
          label: 'Abrir Biblioteca',
          icon: Icons.local_library_outlined,
          onTap: (context) =>
              Navigator.of(context).pushNamed(RotasFolhio.library),
        ),
      ],
    ),
    _TopicoAjuda(
      icon: Icons.verified_user_outlined,
      color: CoresFolhio.green,
      title: 'Conta e segurança',
      subtitle: 'Proteja login, backup e sincronização.',
      bullets: const [
        'Ative verificação em duas etapas para reforçar o acesso.',
        'Mantenha backup e sincronização revisados antes de trocar aparelho.',
        'Exporte seus dados quando quiser uma cópia local de segurança.',
      ],
      actions: [
        _AcaoAjuda(
          label: 'Abrir Backup',
          icon: Icons.shield_outlined,
          onTap: (context) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SegurancaBackupScreen(),
            ),
          ),
        ),
        _AcaoAjuda(
          label: 'Conta',
          icon: Icons.account_circle_outlined,
          onTap: (context) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ConfiguracoesPerfilContaScreen(),
            ),
          ),
        ),
      ],
    ),
    _TopicoAjuda(
      icon: Icons.build_circle_outlined,
      color: CoresFolhio.orange,
      title: 'Problemas comuns',
      subtitle: 'O que fazer quando algo não abre ou demora.',
      bullets: const [
        'Se um arquivo não abrir, tente baixar novamente pela Biblioteca.',
        'Se a IA demorar, mantenha o app aberto até o progresso terminar.',
        'Se login ou código falhar, confira email, senha e conexão.',
      ],
      actions: [
        _AcaoAjuda(
          label: 'Ferramentas',
          icon: Icons.construction_outlined,
          onTap: (context) =>
              Navigator.of(context).pushNamed(RotasFolhio.tools),
        ),
      ],
    ),
    _TopicoAjuda(
      icon: Icons.support_agent_outlined,
      color: CoresFolhio.coral,
      title: 'Falar com suporte',
      subtitle: 'Envie feedback, reporte bug ou sugira recurso.',
      bullets: const [
        'Conte o que aconteceu e em qual tela estava.',
        'Se for erro em arquivo, inclua o tipo do material.',
        'Sugestões de recursos ajudam a priorizar o que entra nas próximas versões.',
      ],
      actions: [
        _AcaoAjuda(
          label: 'Enviar feedback',
          icon: Icons.feedback_outlined,
          onTap: (context) => _avisar(context, 'Feedback preparado.'),
        ),
      ],
    ),
  ];
}

class _TopicoAjudaScreen extends StatelessWidget {
  final _TopicoAjuda topic;

  const _TopicoAjudaScreen({required this.topic});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return _ConfiguracoesPagina(
      title: topic.title,
      children: [
        FolhioCard(
          borderColor: topic.color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeArredondado(
                icon: topic.icon,
                color: topic.color,
                backgroundColor: topic.color.withValues(alpha: 0.14),
              ),
              const SizedBox(height: 12),
              Text(
                topic.subtitle,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              for (final bullet in topic.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: topic.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bullet,
                          style: const TextStyle(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        for (final action in topic.actions)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => action.onTap(context),
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
          ),
      ],
    );
  }
}

class _TopicoAjuda {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final List<_AcaoAjuda> actions;

  const _TopicoAjuda({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.actions,
  });
}

class _AcaoAjuda {
  final String label;
  final IconData icon;
  final void Function(BuildContext context) onTap;

  const _AcaoAjuda({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
