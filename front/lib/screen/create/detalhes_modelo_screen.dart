import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';

class DetalhesModelo {
  final String id;
  final String title;
  final String category;
  final String description;
  final String access;
  final IconData icon;
  final Color color;
  final List<String> previewUrls;
  final List<String> previewAssetPaths;
  final String? sourceFileUrl;

  const DetalhesModelo({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.access,
    required this.icon,
    required this.color,
    this.previewUrls = const [],
    this.previewAssetPaths = const [],
    this.sourceFileUrl,
  });
}

class DetalhesModeloScreen extends StatefulWidget {
  final DetalhesModelo template;
  final VoidCallback? onUse;

  const DetalhesModeloScreen({super.key, required this.template, this.onUse});

  @override
  State<DetalhesModeloScreen> createState() => _DetalhesModeloScreenState();
}

class _DetalhesModeloScreenState extends State<DetalhesModeloScreen> {
  final _pageController = PageController();
  int _page = 0;

  int get _pageCount {
    final count =
        widget.template.previewAssetPaths.length +
        widget.template.previewUrls.length;
    return count == 0 ? 1 : count;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final colors = context.folhioColors;
    final premium = template.access == 'Premium';
    return FolhioScaffold(
      title: 'Modelo',
      currentIndex: 2,
      showBack: true,
      body: FolhioCorpoPagina(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeArredondado(
                icon: template.icon,
                color: template.color,
                backgroundColor: template.color.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        StatusPill(
                          label: template.category,
                          tone: TomIndicador.neutral,
                        ),
                        StatusPill(
                          label: template.access,
                          tone: premium ? TomIndicador.violet : TomIndicador.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const TituloSecao('Visualização'),
          AspectRatio(
            aspectRatio: 0.76,
            child: FolhioCard(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) => _visualizarPagina(index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                onPressed: _page == 0
                    ? null
                    : () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Página ${_page + 1} de $_pageCount',
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                tooltip: 'Próxima página',
                onPressed: _page + 1 >= _pageCount
                    ? null
                    : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const TituloSecao('Sobre este modelo'),
          Text(
            template.description,
            style: TextStyle(
              color: colors.muted,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onUse,
              icon: Icon(
                widget.onUse == null ? Icons.schedule : Icons.edit_outlined,
              ),
              label: Text(
                widget.onUse == null
                    ? 'Modelo disponível em breve'
                    : 'Usar modelo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visualizarPagina(int index) {
    final assets = widget.template.previewAssetPaths;
    if (index < assets.length) {
      return Image.asset(
        assets[index],
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            _ModeloExemploPreview(template: widget.template),
      );
    }
    final urlIndex = index - assets.length;
    if (urlIndex < widget.template.previewUrls.length) {
      return Image.network(
        widget.template.previewUrls[urlIndex],
        headers: FolhioApiGateway.apiHeaders,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) =>
            _ModeloExemploPreview(template: widget.template),
      );
    }
    return _ModeloExemploPreview(template: widget.template);
  }
}

class _ModeloExemploPreview extends StatelessWidget {
  final DetalhesModelo template;

  const _ModeloExemploPreview({required this.template});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return ColoredBox(
      color: colors.surfaceSoft,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 420,
              height: 640,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(template.icon, color: template.color, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              template.title,
                              style: const TextStyle(
                                color: Color(0xFF203F36),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 3, color: template.color),
                      const SizedBox(height: 22),
                      for (var item = 1; item <= 5; item++)
                        _LinhaQuestaoExemplo(item: item),
                      const Spacer(),
                      const Center(
                        child: Text(
                          'EXEMPLO DE VISUALIZAÇÃO',
                          style: TextStyle(
                            color: Color(0xFF82958E),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaQuestaoExemplo extends StatelessWidget {
  final int item;

  const _LinhaQuestaoExemplo({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$item.  Questão de exemplo do modelo',
            style: const TextStyle(
              color: Color(0xFF203F36),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFFE5ECE9),
          ),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: 0.72,
            child: Container(height: 6, color: const Color(0xFFE5ECE9)),
          ),
        ],
      ),
    );
  }
}
