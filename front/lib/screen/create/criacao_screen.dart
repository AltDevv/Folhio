import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import 'rascunhos_screen.dart';
import '../materials/criacao_material_screen.dart';
import '../library/meus_arquivos_screen.dart';

class CriacaoScreen extends StatelessWidget {
  const CriacaoScreen({super.key});

  void _abrirGeradorMaterial(
    BuildContext context, {
    required String materialType,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CriacaoMaterialScreen(
          materialType: materialType,
          initialTitle: title,
        ),
      ),
    );
  }

  void _abrirModelos(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MeusArquivosScreen()));
  }

  void _abrirRascunhos(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RascunhosScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Criar',
      currentIndex: 1,
      body: FolhioCorpoPagina(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _TituloSecaoDestacado('Criar do zero'),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    height: 132,
                    child: _InicioCriacaoCard(
                      icon: Icons.assignment_outlined,
                      color: CoresFolhio.green,
                      title: 'Atividade',
                      subtitle: 'Exercícios com IA',
                      onTap: () => _abrirGeradorMaterial(
                        context,
                        materialType: 'atividade',
                        title: 'Atividade',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    height: 132,
                    child: _InicioCriacaoCard(
                      icon: Icons.quiz_outlined,
                      color: CoresFolhio.blue,
                      title: 'Prova',
                      subtitle: 'Questões + gabarito',
                      onTap: () => _abrirGeradorMaterial(
                        context,
                        materialType: 'prova',
                        title: 'Prova',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    height: 132,
                    child: _InicioCriacaoCard(
                      icon: Icons.event_note_outlined,
                      color: CoresFolhio.orange,
                      title: 'Lista',
                      subtitle: 'Questões em DOCX',
                      onTap: () => _abrirGeradorMaterial(
                        context,
                        materialType: 'lista',
                        title: 'Lista de exercícios',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    height: 132,
                    child: _InicioCriacaoCard(
                      icon: Icons.restart_alt,
                      color: CoresFolhio.violet,
                      title: 'Revisão',
                      subtitle: 'Resumo + prática',
                      onTap: () => _abrirGeradorMaterial(
                        context,
                        materialType: 'atividade',
                        title: 'Revisão',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const _TituloSecaoDestacado('Modelos prontos'),
          _DestaqueModelos(onOpenModels: () => _abrirModelos(context)),
          const _TituloSecaoDestacado('Rascunhos'),
          _RascunhosCard(onOpenDrafts: () => _abrirRascunhos(context)),
        ],
      ),
    );
  }
}

class _TituloSecaoDestacado extends StatelessWidget {
  final String text;

  const _TituloSecaoDestacado(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: CoresFolhio.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DestaqueModelos extends StatelessWidget {
  final VoidCallback onOpenModels;

  const _DestaqueModelos({required this.onOpenModels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CoresTemaFolhio>()!;
    final isDark = theme.brightness == Brightness.dark;
    return FolhioCard(
      onTap: onOpenModels,
      padding: const EdgeInsets.all(14),
      color: isDark
          ? const Color(0xFF10261F)
          : colors.primary.withValues(alpha: 0.06),
      borderColor: CoresFolhio.green.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconeArredondado(
                icon: Icons.auto_awesome,
                color: CoresFolhio.green,
                backgroundColor: Color(0x1F32D583),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modelos',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pontos de partida prontos para personalizar.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onOpenModels,
                icon: const Icon(Icons.chevron_right, size: 20),
                label: const Text('Ver modelos'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MiniChipModelo(
                Icons.assignment_outlined,
                'Atividade',
                CoresFolhio.green,
              ),
              _MiniChipModelo(Icons.quiz_outlined, 'Prova', CoresFolhio.blue),
              _MiniChipModelo(
                Icons.event_note_outlined,
                'Plano',
                CoresFolhio.orange,
              ),
              _MiniChipModelo(Icons.restart_alt, 'Revisão', CoresFolhio.violet),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChipModelo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChipModelo(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RascunhosCard extends StatelessWidget {
  final VoidCallback onOpenDrafts;

  const _RascunhosCard({required this.onOpenDrafts});

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      onTap: onOpenDrafts,
      padding: const EdgeInsets.all(16),
      color: CoresFolhio.surfaceSoft,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CoresFolhio.border),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: CoresFolhio.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continuar rascunho',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Retome materiais em edição com gabarito e exportação.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).extension<CoresTemaFolhio>()!.muted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ver rascunhos',
                onPressed: onOpenDrafts,
                icon: const Icon(
                  Icons.chevron_right,
                  color: CoresFolhio.green,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onOpenDrafts,
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Ver todos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InicioCriacaoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InicioCriacaoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).extension<CoresTemaFolhio>()!.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: CoresFolhio.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: CoresFolhio.green,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
