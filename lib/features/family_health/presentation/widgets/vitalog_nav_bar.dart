import 'package:flutter/material.dart';

import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';

class VitalogNavItem {
  const VitalogNavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Tab row for the floating bottom tray: the selected tab sits on a soft
/// continuous-corner highlight that springs between tabs. Its radius is
/// AppRadius.lg, concentric with the tray (xl) around it.
class VitalogNavBar extends StatelessWidget {
  const VitalogNavBar(
      {super.key,
      required this.items,
      required this.selectedIndex,
      required this.onSelected});
  final List<VitalogNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    // Labels may grow with Simple mode, but not past what fits four tabs.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 58,
        child: LayoutBuilder(builder: (context, box) {
          final slot = box.maxWidth / items.length;
          return Stack(children: [
            AnimatedPositioned(
              duration:
                  still ? Duration.zero : const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              top: 0,
              bottom: 0,
              left: slot * selectedIndex,
              width: slot,
              child: DecoratedBox(
                  decoration: AppShape.decoration(
                      radius: AppRadius.lg, color: c.brandSoft)),
            ),
            Row(children: [
              for (final (i, item) in items.indexed)
                Expanded(
                    child: _Tab(
                        item: item,
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i))),
            ]),
          ]);
        }),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});
  final VitalogNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.brand : c.textMuted;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        splashFactory: NoSplash.splashFactory,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: still ? Duration.zero : const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: Icon(selected ? item.selectedIcon : item.icon,
                size: 23, color: color),
          ),
          const SizedBox(height: 4),
          Text(item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: .2,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}
