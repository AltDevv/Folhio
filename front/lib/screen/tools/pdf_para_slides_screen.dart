import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';

class PdfParaSlidesScreen extends StatelessWidget {
  const PdfParaSlidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioScaffold(
      title: 'PDF para slides',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          Text(
            'Transforme um PDF em uma apresentação organizada. O Folhio usará OCR para reconhecer o conteúdo e montar slides editáveis.',
            style: TextStyle(
              color: colors.muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          FolhioCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              children: [
                IconeArredondado(
                  icon: Icons.picture_as_pdf_outlined,
                  color: CoresFolhio.coral,
                  backgroundColor: CoresFolhio.coral.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escolha o PDF de origem',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  'Seleção de arquivo disponível em breve',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SimuladoEtapa(
            icon: Icons.document_scanner_outlined,
            title: 'Reconhecer texto',
            subtitle: 'OCR para PDFs digitais ou escaneados.',
          ),
          const _SimuladoEtapa(
            icon: Icons.auto_awesome_outlined,
            title: 'Organizar apresentação',
            subtitle: 'Títulos, tópicos e imagens distribuídos em slides.',
          ),
          const _SimuladoEtapa(
            icon: Icons.slideshow_outlined,
            title: 'Gerar PPTX',
            subtitle: 'Apresentação editável pronta para revisar.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.schedule),
              label: const Text('Disponível em breve'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Este recurso será ativado depois que o fluxo Criar estiver funcional.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimuladoEtapa extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SimuladoEtapa({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconeArredondado(
            icon: icon,
            color: colors.primary,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    height: 1.3,
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
