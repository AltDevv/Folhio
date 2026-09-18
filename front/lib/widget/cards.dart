import 'package:flutter/material.dart';

import '../controller/settings/aparencia_controller.dart';
import '../style/estilo_folhio.dart';

class FolhioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;
  final VoidCallback? onTap;

  const FolhioCard({
    super.key,
    required this.child,
    this.padding = EstiloFolhio.cardPadding,
    this.borderColor,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folhio = theme.extension<CoresTemaFolhio>()!;
    final resolvedColor = _corAdaptadaAoTema(color, folhio);
    final resolvedBorder = _corAdaptadaAoTema(borderColor, folhio);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            resolvedColor ?? theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(EstiloFolhio.cardRadius),
        border: Border.all(
          color:
              resolvedBorder ?? theme.dividerTheme.color ?? folhio.borderSoft,
        ),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(EstiloFolhio.cardRadius),
      onTap: onTap,
      child: card,
    );
  }

  Color? _corAdaptadaAoTema(Color? value, CoresTemaFolhio colors) {
    if (value == null) return null;
    if (value == CoresFolhio.surfaceSoft) return colors.surfaceSoft;
    if (value == CoresFolhio.surface) return colors.surface;
    if (value == CoresFolhio.background) return colors.background;
    if (value == CoresFolhio.input) return colors.input;
    if (value == CoresFolhio.border) return colors.border;
    if (value == CoresFolhio.borderSoft) return colors.borderSoft;
    return value;
  }
}

class FerramentaCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const FerramentaCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).textTheme.bodySmall?.color ?? CoresFolhio.muted;
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;

    return FolhioCard(
      onTap: onTap,
      borderColor: badge == null ? null : CoresFolhio.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    StatusPill(label: badge!, tone: TomIndicador.violet),
                  ],
                ],
              ),
              if (showDescriptions && subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class FolhioItemLista extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String? badge;
  final List<String> badges;
  final VoidCallback? onTap;
  final Widget? trailing;

  const FolhioItemLista({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badges = const [],
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color ?? CoresFolhio.muted;
    final showDescriptions =
        AparenciaController.instance.extraDescriptions;
    final allBadges = [?badge, ...badges];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? CoresFolhio.borderSoft,
          ),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        leading: IconeArredondado(
          icon: icon,
          color: iconColor,
          backgroundColor: iconBackground,
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final label in allBadges)
                  StatusPill(label: label, tone: TomIndicador.green),
              ],
            );
          },
        ),
        subtitle: !showDescriptions || subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: muted),
      ),
    );
  }
}

class IconeArredondado extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const IconeArredondado({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final folhio = Theme.of(context).extension<CoresTemaFolhio>()!;
    final resolvedColor = color == CoresFolhio.green
        ? folhio.secondary
        : color;
    final resolvedBackground = backgroundColor == CoresFolhio.greenSoft
        ? folhio.secondary.withValues(alpha: 0.14)
        : backgroundColor == CoresFolhio.surfaceSoft
        ? folhio.surfaceSoft
        : backgroundColor == CoresFolhio.surface
        ? folhio.surface
        : backgroundColor;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: resolvedColor, size: 21),
    );
  }
}

enum TomIndicador { green, violet, neutral }

class StatusPill extends StatelessWidget {
  final String label;
  final TomIndicador tone;

  const StatusPill({
    super.key,
    required this.label,
    this.tone = TomIndicador.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = switch (tone) {
      TomIndicador.green => (
        theme.colorScheme.secondary,
        theme.colorScheme.secondary.withValues(alpha: 0.20),
      ),
      TomIndicador.violet => (CoresFolhio.violet, const Color(0xFF302D4E)),
      TomIndicador.neutral => (
        theme.colorScheme.onSurface,
        theme.colorScheme.surfaceContainerHighest,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$1,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
