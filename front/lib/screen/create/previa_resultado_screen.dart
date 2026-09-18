import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../widget/actions.dart';
import '../../widget/folhio_scaffold.dart';
import '../../widget/previews.dart';

class PreviaResultadoScreen extends StatelessWidget {
  const PreviaResultadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Pr�via do resultado',
      currentIndex: 2,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          const ProgressoEtapas(current: 3),
          const MensagemSucessoPreenchida('Processado! 8 p�ginas ? 4 folhas'),
          const SizedBox(height: 16),
          const Text(
            'Prova_Mat_8A_2em1.pdf',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          const Text(
            '4 p�ginas � 1.2 MB (era 2.8 MB)',
            style: TextStyle(
              color: CoresFolhio.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: MiniFolhaPreview(label: 'folha 1')),
              SizedBox(width: 8),
              Expanded(child: MiniFolhaPreview(label: 'folha 2')),
              SizedBox(width: 8),
              Expanded(child: MiniFolhaPreview(label: 'folha 3')),
            ],
          ),
          const SizedBox(height: 18),
          const AcaoPrincipalButton(
            label: 'Compartilhar (WhatsApp, Drive...)',
            icon: Icons.share,
          ),
          const SizedBox(height: 10),
          const AcaoPrincipalButton(
            label: 'Salvar no dispositivo',
            icon: Icons.download,
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Arquivo pronto na sua conta. Voc� pode baixar, compartilhar ou salvar na biblioteca.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoresFolhio.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
