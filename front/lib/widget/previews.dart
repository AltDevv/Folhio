import 'package:flutter/material.dart';

import '../style/estilo_folhio.dart';
import '../service/api/folhio_api_gateway.dart';
import 'cards.dart';

class FaixaArquivos extends StatelessWidget {
  final String name;
  final String detail;
  final IconData icon;

  const FaixaArquivos({
    super.key,
    required this.name,
    required this.detail,
    this.icon = Icons.picture_as_pdf,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: CoresFolhio.coral, size: 18),
          const SizedBox(width: 10),
          Flexible(
            flex: 5,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 4,
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniaturaPagina extends StatelessWidget {
  final String label;
  final String? previewUrl;
  final bool selected;
  final VoidCallback? onTap;

  const MiniaturaPagina({
    super.key,
    required this.label,
    this.previewUrl,
    this.selected = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 58,
        height: 72,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: previewUrl == null
                      ? const _PaginaPlaceholder()
                      : Image.network(
                          previewUrl!,
                          headers: FolhioApiGateway.apiHeaders,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, _, _) => const _PaginaPlaceholder(),
                        ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                left: 6,
                top: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xCC203F36),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF42D5AE),
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaginaPlaceholder extends StatelessWidget {
  const _PaginaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Container(color: colors.surfaceSoft, child: LinhasPosicionadas());
  }
}

class LinhasPosicionadas extends StatelessWidget {
  const LinhasPosicionadas({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _Linha(widthFactor: .55),
          SizedBox(height: 5),
          _Linha(widthFactor: .38),
        ],
      ),
    );
  }
}

class MiniFolhaPreview extends StatelessWidget {
  final String label;

  const MiniFolhaPreview({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Linha(widthFactor: .55),
          const SizedBox(height: 5),
          const _Linha(widthFactor: .38),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final double widthFactor;

  const _Linha({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: colors.dim,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
