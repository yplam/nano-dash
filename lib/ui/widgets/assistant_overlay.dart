import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'panel_theme.dart';
import 'voice_agent_button.dart';
import 'voice_dialogue.dart';

/// Where the assistant button sits on the round panel. Each anchor is inset so
/// the whole button clears the circular rim (see [AssistantOverlay]).
enum AssistantAnchor {
  bottomCenter,
  bottomLeft,
  bottomRight,
  topLeft,
  topRight,
}

/// Drops the shared voice assistant — the [VoiceAgentButton] and/or the
/// [VoiceDialogue] box — on top of any panel page, so a module can offer the
/// assistant without wiring the two widgets and their round-panel placement
/// itself. Just wrap the page content:
///
/// ```dart
/// AssistantOverlay(
///   button: AssistantAnchor.bottomCenter,
///   child: _ClockView(...),
/// )
/// ```
///
/// The button and the dialogue are independent: pass [button] to show the mic
/// (omit it to hide it) and set [dialogue] to show the conversation box (it
/// always hangs at the bottom of the panel, as [VoiceDialogue] is designed).
class AssistantOverlay extends StatelessWidget {
  const AssistantOverlay({
    super.key,
    required this.child,
    this.button,
    this.buttonDiameterRatio = _kDefaultButtonRatio,
    this.dialogue = false,
  });

  /// The page this overlay sits on top of.
  final Widget child;

  /// Where to place the mic button, or null to omit it.
  final AssistantAnchor? button;

  /// Button diameter as a fraction of the panel's `min(width, height)`.
  final double buttonDiameterRatio;

  /// Whether to show the bottom-pinned [VoiceDialogue] over the page.
  final bool dialogue;

  static const double _kDefaultButtonRatio = 0.16;

  @override
  Widget build(BuildContext context) {
    // The voice engine and LLM agent are desktop-only (see app.dart): on web
    // their cubits are never provided, so there is nothing to overlay.
    if (kIsWeb) return child;

    final safeMargin =
        (Theme.of(context).extension<PanelTheme>() ?? const PanelTheme())
            .safeMargin;
    final anchor = button;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (dialogue)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: _dialogueBottomInset(side, safeMargin, anchor),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: VoiceDialogue(side: side),
                    ),
                  ),
                ),
              ),
            if (anchor != null) _button(side, safeMargin, anchor),
          ],
        );
      },
    );
  }

  Widget _button(double side, double safeMargin, AssistantAnchor anchor) {
    final diameter = side * buttonDiameterRatio;
    final center = _anchorCenter(side, safeMargin, diameter, anchor);
    // VoiceAgentButton's footprint is kBoxScale times its diameter, centred on
    // its mic; offset by half that box so the mic lands on [center].
    final box = diameter * VoiceAgentButton.kBoxScale;
    return Positioned(
      left: center.dx - box / 2,
      top: center.dy - box / 2,
      child: VoiceAgentButton(diameter: diameter),
    );
  }

  /// How far to lift the bottom-pinned [VoiceDialogue] off the panel floor so it
  /// clears a bottom-anchored button instead of covering it.
  double _dialogueBottomInset(
    double side,
    double safeMargin,
    AssistantAnchor? anchor,
  ) {
    if (anchor == null) return 0;
    final diameter = side * buttonDiameterRatio;
    final buttonTop =
        _anchorCenter(side, safeMargin, diameter, anchor).dy - diameter / 2;
    if (buttonTop < side / 2) return 0;
    return side - buttonTop + side * 0.02;
  }

  Offset _anchorCenter(
    double side,
    double safeMargin,
    double diameter,
    AssistantAnchor anchor,
  ) {
    final r = side / 2;
    final rim = side * safeMargin;
    final inset = r - rim - diameter / 2;
    final k = inset / math.sqrt2;
    return switch (anchor) {
      AssistantAnchor.bottomCenter => Offset(r, r + inset),
      AssistantAnchor.bottomLeft => Offset(r - k, r + k),
      AssistantAnchor.bottomRight => Offset(r + k, r + k),
      AssistantAnchor.topLeft => Offset(r - k, r - k),
      AssistantAnchor.topRight => Offset(r + k, r - k),
    };
  }
}
