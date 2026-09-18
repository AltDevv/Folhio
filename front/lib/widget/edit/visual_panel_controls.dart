part of '../../screen/edit/edit_flows_screen.dart';

class _AcaoTextoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AcaoTextoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF143A31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoresFolhio.green),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: CoresFolhio.green, size: 17),
            SizedBox(width: 4),
            Text(
              'Texto',
              style: TextStyle(
                color: CoresFolhio.green,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExclusaoTextoButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ExclusaoTextoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        width: 38,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF2B1D1D) : CoresFolhio.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFE56B6B) : CoresFolhio.borderSoft,
          ),
        ),
        child: Icon(
          Icons.delete_outline,
          color: enabled ? const Color(0xFFE56B6B) : CoresFolhio.dim,
          size: 18,
        ),
      ),
    );
  }
}

class _AcaoCamadaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AcaoCamadaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF143A31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoresFolhio.green),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CoresFolhio.green, size: 17),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: CoresFolhio.green,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExclusaoCamadaButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ExclusaoCamadaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        width: 38,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF2B1D1D) : CoresFolhio.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFE56B6B) : CoresFolhio.borderSoft,
          ),
        ),
        child: Icon(
          Icons.delete_outline,
          color: enabled ? const Color(0xFFE56B6B) : CoresFolhio.dim,
          size: 18,
        ),
      ),
    );
  }
}

class _RotacaoSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _RotacaoSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label = '${value.round()}°';
    return Row(
      children: [
        const Icon(
          Icons.rotate_90_degrees_ccw,
          color: CoresFolhio.muted,
          size: 18,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: -45,
              max: 45,
              divisions: 90,
              activeColor: CoresFolhio.green,
              inactiveColor: CoresFolhio.borderSoft,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: CoresFolhio.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PontoCor extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PontoCor({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? CoresFolhio.green : CoresFolhio.borderSoft,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _MiniPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54, maxHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CoresFolhio.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoresFolhio.borderSoft),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PercentualSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _PercentualSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final percent = value >= 0 ? '+$value%' : '$value%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CoresFolhio.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              percent,
              style: const TextStyle(
                color: CoresFolhio.green,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 22,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 5,
              activeTrackColor: CoresFolhio.green,
              inactiveTrackColor: CoresFolhio.borderSoft,
              thumbColor: CoresFolhio.green,
              overlayColor: CoresFolhio.green.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: percent,
              onChanged: (next) => onChanged(next.round()),
            ),
          ),
        ),
      ],
    );
  }
}
