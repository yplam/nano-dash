import 'package:flutter/material.dart';

import 'panel_text.dart';
import 'panel_theme.dart';

/// The shared resting state for a panel page that has nothing to show: a muted
/// glyph over a one-line reason, on a small round translucent backdrop.
class PanelEmpty extends StatelessWidget {
  const PanelEmpty({
    super.key,
    required this.side,
    required this.icon,
    required this.label,
    this.hint,
  });

  /// The panel's `min(width, height)`, from the page's `LayoutBuilder`.
  final double side;
  final IconData icon;
  final String label;

  /// An optional smaller, dimmer second line telling the user what to do about
  /// it. The circle grows to accommodate it.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final diameter = side * (hint == null ? 0.48 : 0.56);
    return Center(
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        // Keeps text that wraps clear of the circle's edge.
        padding: EdgeInsets.symmetric(horizontal: side * 0.05),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface.withValues(alpha: m.cardAlpha),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: side * 0.16, color: colors.onSurfaceVariant),
            SizedBox(height: m.gap),
            // Clamped so a long label (a localized error, say) ellipsizes
            // instead of overflowing the fixed-diameter circle.
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: panelFont(
                  m.fontMd,
                  m.weightRegular,
                  colors.onSurfaceVariant,
                ),
              ),
            ),
            if (hint != null) ...[
              SizedBox(height: m.gap * 0.4),
              Flexible(
                child: Text(
                  hint!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(
                    m.fontSm,
                    m.weightRegular,
                    colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
