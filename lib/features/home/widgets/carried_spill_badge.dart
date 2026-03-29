import 'package:flutter/material.dart';

/// Badge for tasks carried from spill-over. Teal for a single carry day; red with
/// "Carried N" when carried on more than one calendar day.
class CarriedSpillBadge extends StatelessWidget {
  /// Distinct calendar days this entity appears in [carryToToday] (minimum 1 when shown).
  final int spillDays;

  const CarriedSpillBadge({super.key, required this.spillDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final n = spillDays < 1 ? 1 : spillDays;
    final multi = n > 1;
    final bg = multi
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final fg = multi
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;
    final label = multi ? 'Carried $n' : 'Carried';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
          fontSize: 10,
        ),
      ),
    );
  }
}
