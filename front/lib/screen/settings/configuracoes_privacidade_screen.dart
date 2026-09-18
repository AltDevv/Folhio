part of 'configuracoes_screen.dart';

class ConfiguracoesPrivacidadeScreen extends StatelessWidget {
  const ConfiguracoesPrivacidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ConfiguracoesPagina(
      title: 'Privacidade',
      children: [
        _DocumentoPrivacidade(
          chapters: [
            const _DadosCapituloPrivacidade(
              icon: Icons.backup_outlined,
              iconColor: CoresFolhio.green,
              title: 'Backup e exportação',
              subtitle: 'Você controla quando criar cópias ou exportar dados.',
              bullets: [
                'Backups servem para guardar uma cópia dos seus materiais e configurações.',
                'Exportações só acontecem quando você escolhe gerar ou salvar um arquivo.',
                'O Folhio não envia backup automaticamente para terceiros.',
              ],
            ),
            const _DadosCapituloPrivacidade(
              icon: Icons.folder_open,
              iconColor: CoresFolhio.orange,
              title: 'Arquivos e permissões',
              subtitle: 'O app usa apenas os arquivos que você escolher.',
              bullets: [
                'O Folhio não varre suas pastas automaticamente.',
                'Arquivos entram no app quando você importa, edita ou converte.',
                'Materiais salvos ficam na biblioteca local do aparelho.',
              ],
            ),
            const _DadosCapituloPrivacidade(
              icon: Icons.history_toggle_off,
              iconColor: CoresFolhio.blue,
              title: 'Logs por 10 dias',
              subtitle:
                  'Registros curtos ajudam a encontrar falhas sem expor conteúdo.',
              bullets: [
                'Logs guardam eventos técnicos, como falha de login, upload ou conversão.',
                'O app evita registrar o conteúdo dos seus arquivos e materiais.',
                'Esses registros são temporários e servem para diagnóstico do sistema.',
              ],
            ),
            const _DadosCapituloPrivacidade(
              icon: Icons.mic_none,
              iconColor: CoresFolhio.violet,
              title: 'Microfone',
              subtitle: 'Usado somente quando você escolhe ditar algo.',
              bullets: [
                'O microfone não fica ativo em segundo plano.',
                'Ele só é solicitado em recursos de ditado ou comando por voz.',
                'Você pode negar essa permissão no sistema se não quiser usar voz.',
              ],
            ),
            const _DadosCapituloPrivacidade(
              icon: Icons.delete_forever_outlined,
              iconColor: CoresFolhio.coral,
              title: 'Apagar dados ou conta',
              subtitle: 'Remoção de conta e dados locais é uma ação manual.',
              bullets: [
                'A exclusão da conta remove dados associados ao seu perfil no servidor.',
                'Arquivos salvos no aparelho dependem do armazenamento local do celular.',
                'Antes de apagar, vale exportar ou baixar o que você deseja guardar.',
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DadosCapituloPrivacidade {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> bullets;

  const _DadosCapituloPrivacidade({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });
}

class _DocumentoPrivacidade extends StatelessWidget {
  final List<_DadosCapituloPrivacidade> chapters;

  const _DocumentoPrivacidade({required this.chapters});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < chapters.length; index++) ...[
            _CapituloPrivacidade(chapter: chapters[index]),
            if (index < chapters.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Divider(color: colors.borderSoft, height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _CapituloPrivacidade extends StatelessWidget {
  final _DadosCapituloPrivacidade chapter;

  const _CapituloPrivacidade({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconeArredondado(
              icon: chapter.icon,
              color: chapter.iconColor,
              backgroundColor: chapter.iconColor.withValues(alpha: 0.14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.subtitle,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final bullet in chapter.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: chapter.iconColor, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(color: colors.muted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
