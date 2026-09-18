import 'package:flutter/material.dart';

import '../style/estilo_folhio.dart';

class AcaoPrincipalButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AcaoPrincipalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return SizedBox(
      width: double.infinity,
      height: EstiloFolhio.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          disabledForegroundColor: colors.dim,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EstiloFolhio.buttonRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class MensagemSucessoPreenchida extends StatelessWidget {
  final String text;

  const MensagemSucessoPreenchida(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CoresFolhio.greenDeep,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check, color: CoresFolhio.cream, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CoresFolhio.cream,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeletorChip extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const SeletorChip({
    super.key,
    required this.labels,
    this.selectedIndex = 0,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (index, label) in labels.indexed)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected?.call(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: index == selectedIndex
                    ? colors.primary.withValues(alpha: 0.10)
                    : colors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: index == selectedIndex
                      ? colors.primary
                      : colors.borderSoft,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProgressoEtapas extends StatelessWidget {
  final int current;
  final int total;

  const ProgressoEtapas({super.key, required this.current, this.total = 3});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          for (var index = 1; index <= total; index++) ...[
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: index <= current ? colors.primary : colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (index < total) const SizedBox(width: 6),
          ],
          const SizedBox(width: 10),
          Text(
            '$current/$total',
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class NumeracaoStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  const NumeracaoStepper({
    super.key,
    required this.value,
    this.min = 1,
    this.max = 99,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircularButton(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged?.call(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
        _CircularButton(
          icon: Icons.add,
          onTap: value < max ? () => onChanged?.call(value + 1) : null,
        ),
      ],
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircularButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          color: onTap == null ? colors.dim : colors.text,
          size: 16,
        ),
      ),
    );
  }
}
