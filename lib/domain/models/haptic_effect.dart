/// Curated DRV2605L ROM waveform effects offered as selectable "alert" buzzes.
///
/// The DRV2605L exposes 123 ROM effects (datasheet Table 12); most are subtle
/// variants unsuitable as a distinct alert, so only this handful is surfaced in
/// settings. Each [effect] id is sent verbatim as `HapticsPlay.effect`; `0`
/// means "no effect" (alerts stay silent).
///
/// Ids are stable — they are what [AppConfig.alertEffect] persists, so keep them
/// fixed even if this list is reordered.
enum AlertEffect {
  none(0),
  bump(7), // Soft Bump 100%
  pulse(54), // Pulsing Medium 1 100%
  mediumBuzz(49), // Buzz 3 (60%)
  buzz(47), // Buzz 1
  strongBuzz(14), // Strong Buzz
  alert750(15), // 750 ms Alert
  alert1000(16), // 1000 ms Alert
  pulsing(52); // Pulsing Strong 1

  const AlertEffect(this.effect);

  /// DRV2605L ROM waveform id (see datasheet Table 12); 0 = disabled.
  final int effect;

  /// The out-of-box default: a gentle bump. Short "click" effects barely move a
  /// slow-to-spin ERM, so the mid tier is bumps/pulses/buzzes, not clicks.
  static const AlertEffect fallback = bump;

  /// Resolve a persisted [effect] id back to a preset, falling back to
  /// [fallback] for an id no longer in the list.
  static AlertEffect fromEffect(int effect) {
    for (final e in values) {
      if (e.effect == effect) return e;
    }
    return fallback;
  }
}
