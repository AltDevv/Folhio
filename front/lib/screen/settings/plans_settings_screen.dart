part of 'configuracoes_screen.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return _ConfiguracoesPagina(
      title: 'Planos',
      children: _itensConfiguracoesEspacados([
        FolhioCard(
          color: CoresFolhio.surfaceSoft,
          child: Text(
            'Valores pensados para manter o custo de IA controlado: modelos, questões e imagens fazem a base; a IA ajuda na variação, com limites claros por plano.',
            style: TextStyle(color: colors.muted, height: 1.35),
          ),
        ),
        const _PlanoCard(
          title: 'Free',
          price: 'R\$ 0',
          badge: 'Atual',
          selected: true,
          actionLabel: 'Plano atual',
          features: [
            '5 gerações de materiais por mês',
            'Modelos gratuitos',
            'Biblioteca local com pastas e tags',
            'Organização de materiais',
            'Exportação com marca Folhio',
          ],
        ),
        const _PlanoCard(
          title: 'Pro',
          price: 'R\$ 29,90/mês',
          badge: 'Mais indicado',
          accentColor: CoresFolhio.violet,
          features: [
            '60 gerações de materiais por mês',
            'Modelos premium',
            'Banco de questões com variação por IA',
            'Banco de imagens educacionais',
            'Ferramentas de PDF',
            'Backup em nuvem',
            'Exportação sem marca Folhio',
          ],
        ),
        const _PlanoCard(
          title: 'Ultra',
          price: 'R\$ 49,90/mês',
          accentColor: CoresFolhio.blue,
          features: [
            'Tudo do Pro',
            '180 gerações de materiais por mês',
            'Mais variações por material',
            'Modelos avançados de provas e planos',
            'Mais armazenamento em nuvem',
            'Processamento prioritário',
            'Suporte prioritário',
          ],
        ),
        const _PlanoCard(
          title: 'Escolar',
          price: 'R\$ 299,90/mês',
          badge: 'Até 8 professores',
          accentColor: CoresFolhio.orange,
          features: [
            '600 gerações compartilhadas por mês',
            'Contas para até 8 professores',
            'Biblioteca e modelos da escola',
            'Banco de questões compartilhado',
            'Materiais por turma e professor',
            'Relatórios básicos de uso',
            'Professor extra: R\$ 37,49/mês',
          ],
        ),
        FolhioCard(
          child: Text(
            'Assinaturas ainda não estão ativas. Os limites podem ser ajustados depois com dados reais de uso.',
            style: TextStyle(color: colors.muted, height: 1.35),
          ),
        ),
      ]),
    );
  }
}

List<Widget> _itensConfiguracoesEspacados(List<Widget> children) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 8),
      children[index],
    ],
  ];
}
