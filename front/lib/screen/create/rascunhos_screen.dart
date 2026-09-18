import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../edit/edit_flows_screen.dart';

class RascunhosScreen extends StatelessWidget {
  const RascunhosScreen({super.key});

  void _abrirEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EdicaoImagemScreen(showBack: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Rascunhos',
      currentIndex: 1,
      showBack: true,
      body: FolhioCorpoPagina(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          FolhioCard(
            onTap: () => _abrirEditor(context),
            color: CoresFolhio.greenSoft,
            borderColor: CoresFolhio.green.withValues(alpha: 0.32),
            child: Row(
              children: [
                const IconeArredondado(
                  icon: Icons.add_circle_outline,
                  color: CoresFolhio.green,
                  backgroundColor: Color(0x2432D583),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abrir editor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Comece ou continue um material editável.',
                        style: TextStyle(
                          color: CoresFolhio.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _abrirEditor(context),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: CoresFolhio.green,
                  ),
                ),
              ],
            ),
          ),
          const TituloSecao('Recentes'),
          const FolhioCard(
            color: CoresFolhio.surfaceSoft,
            child: Row(
              children: [
                IconeArredondado(
                  icon: Icons.edit_note_outlined,
                  color: CoresFolhio.green,
                  backgroundColor: CoresFolhio.surface,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nenhum rascunho ainda',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quando você salvar um material em edição, ele aparece aqui.',
                        style: TextStyle(
                          color: CoresFolhio.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
