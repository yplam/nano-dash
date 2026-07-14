import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'panel_text.dart';
import 'panel_theme.dart';

/// An anime / visual-novel style talking text box: a translucent rounded panel
/// pinned near the bottom of the panel, carrying an optional speaker name tag
/// and dialogue that auto-scrolls vertically when it doesn't fit. Meant to be
/// stacked on top of the Live2D character so it overlaps the lower part of the
/// model.
///
/// Colours are deliberately not themed: the box sits over whatever the model and
/// background happen to be, so it needs its own contrast.
class DialogueBox extends StatelessWidget {
  const DialogueBox({
    super.key,
    required this.side,
    required this.text,
    this.speaker,
    this.scrollSpeed,
    this.onRevealingChanged,
  });

  /// The panel's `min(width, height)`, from the page's `LayoutBuilder`.
  final double side;

  final String text;

  /// Name tag above the dialogue; omitted when null.
  final String? speaker;

  /// Reports the reveal state of overflowing dialogue, as a level rather than an
  /// edge so an owner can never miss it: `true` while the text is too tall to
  /// fit and has not yet been scrolled to the bottom, then `false` once the
  /// bottom is reached (or straight away for text that already fits). Lets an
  /// owner that dismisses the box on a timer (see [VoiceDialogue]) keep it up
  /// until the reader has seen the whole thing and only then start its linger,
  /// instead of hiding the text mid-scroll. When provided, the reveal holds at
  /// the bottom for the owner to dismiss instead of looping back to the top.
  final ValueChanged<bool>? onRevealingChanged;

  /// Auto-scroll speed, in logical pixels per second. The scroll runs at this
  /// constant glide speed, so a longer line simply takes proportionally longer
  /// to reveal rather than whizzing past. When null a default is derived from
  /// the font size (see [_kDefaultLinesPerSecond]) so the reading cadence stays
  /// consistent across differently sized panels.
  final double? scrollSpeed;

  /// Visible dialogue height, in lines. Anything taller scrolls; anything
  /// shorter just sits still.
  static const int _kVisibleLines = 3;
  static const double _kLineHeight = 1.35;

  /// Default scroll pacing when [scrollSpeed] is null, expressed in text lines
  /// per second and converted to pixels/second against the actual line height.
  static const double _kDefaultLinesPerSecond = 0.6;

  @override
  Widget build(BuildContext context) {
    final m = PanelTheme.metricsOf(context, side);
    // The box hangs near the bottom of the round panel, so its lower corners are
    // the ones at risk of leaving the glass. Solve the circle for the half-chord
    // at the box's bottom edge and inset horizontally to match.
    final r = side / 2;
    final bottom = side * 0.10;
    final dy = r - bottom;
    final halfChord = math.sqrt(math.max(r * r - dy * dy, 0));
    final hMargin = r - halfChord;

    return Container(
      margin: EdgeInsets.only(left: hMargin, right: hMargin, bottom: bottom),
      padding: m.cardPaddingLg,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(m.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (speaker != null) ...[
            Text(
              speaker!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: panelFont(m.fontSm, m.weightBold, Colors.white),
            ),
            SizedBox(height: m.gap * 0.6),
          ],
          SizedBox(
            height: m.fontMd * _kLineHeight * _kVisibleLines,
            width: double.infinity,
            child: _AutoScrollText(
              text: text,
              speed:
                  scrollSpeed ??
                  m.fontMd * _kLineHeight * _kDefaultLinesPerSecond,
              onRevealingChanged: onRevealingChanged,
              style:
                  panelFont(
                    m.fontMd,
                    m.weightRegular,
                    Colors.white,
                    height: _kLineHeight,
                  ).copyWith(
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 4),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text inside a fixed-height viewport that auto-scrolls vertically: it holds at
/// the top briefly, eases down to reveal the rest, then holds at the bottom.
/// With no [onRevealingChanged] it jumps back to the top and repeats; with one
/// it stops at the bottom and reports, leaving the owner to dismiss it. Touch is
/// intentionally not wired up — on the LCD the dialogue box sits over the
/// character, where pointers belong to the carousel pager, so the scroll has to
/// drive itself.
class _AutoScrollText extends StatefulWidget {
  const _AutoScrollText({
    required this.text,
    required this.style,
    required this.speed,
    this.onRevealingChanged,
  });

  final String text;
  final TextStyle style;

  /// Constant scroll speed in logical pixels per second; the reveal duration is
  /// this divided into the scroll extent, so speed stays fixed as text grows.
  final double speed;

  /// See [DialogueBox.onRevealingChanged].
  final ValueChanged<bool>? onRevealingChanged;

  @override
  State<_AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<_AutoScrollText> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  /// The last value handed to [DialogueBox.onRevealingChanged]; the reveal
  /// state is a level, so re-reporting the same value (a streaming update
  /// restarting the cycle, a loop returning to the top) is suppressed. Starts
  /// null so the first report always lands.
  bool? _reported;

  // Hold at each end before moving.
  static const Duration _kHold = Duration(seconds: 1);

  // Floor/ceiling on the reveal so a one-line overflow still eases gently and a
  // wall of text can't animate for minutes on end.
  static const int _kMinScrollMs = 600;
  static const int _kMaxScrollMs = 600000;

  @override
  void initState() {
    super.initState();
    // Wait for the first layout so the scroll extent is known, then start the
    // cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCycle());
  }

  @override
  void didUpdateWidget(_AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      if (_controller.hasClients) _controller.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCycle());
    }
  }

  /// Report the reveal state, but only on a genuine change — a growing
  /// streaming reply restarts the cycle on every delta, and we must not flap the
  /// owner's dwell each time.
  void _report(bool revealing) {
    if (_reported == revealing) return;
    _reported = revealing;
    widget.onRevealingChanged?.call(revealing);
  }

  void _startCycle() {
    if (!mounted || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    // Nothing to scroll: the text already fits. Leave it pinned at the top and
    // tell the owner it can govern dismissal with its plain dwell.
    if (max <= 0) {
      _report(false);
      return;
    }

    final atTop = _controller.offset <= 0.5;
    // Reveal duration scales with the scroll extent so the glide speed is
    // constant regardless of how much text there is.
    final scrollMs = (max / widget.speed * 1000).round().clamp(
      _kMinScrollMs,
      _kMaxScrollMs,
    );
    // Announce the reveal before the opening hold so an owner timing our
    // dismissal keeps us up until the bottom rather than hiding us mid-scroll.
    _report(true);
    // Hold at each end before moving; instant snap when returning to the top so
    // only the downward reveal animates.
    _timer = Timer(_kHold, () {
      if (!mounted || !_controller.hasClients) return;
      if (atTop) {
        _controller
            .animateTo(
              max,
              duration: Duration(milliseconds: scrollMs),
              curve: Curves.easeInOut,
            )
            .whenComplete(() {
              if (!mounted) return;
              // Reached the bottom: the whole text has now been shown.
              _report(false);
              // Driven: hold at the bottom and let the owner dismiss us. Only
              // loop back to the top when nobody is listening for the reveal.
              if (widget.onRevealingChanged == null) _startCycle();
            });
      } else {
        _controller.jumpTo(0);
        _startCycle();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      // Self-driven; swallow user drags so they don't fight the carousel pager.
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style),
    );
  }
}
