import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/pico_view_service.dart';
import '../../../domain/models/haptic_effect.dart';
import '../../../domain/models/now_playing.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_empty.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/now_playing_cubit.dart';
import 'art_image.dart';

/// The Now Playing page: the host's current track mirrored to the round panel —
/// cover art filling the glass, a progress ring hugging the rim, and large
/// touch transport controls that buzz the panel's haptic driver on tap.
class NowPlayingView extends StatelessWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : constraints.maxHeight,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : constraints.maxWidth,
        );
        return BlocBuilder<NowPlayingCubit, NowPlayingState>(
          builder: (context, state) => _body(context, side, state.current),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, NowPlaying? np) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);

    if (np == null || (np.title == null && np.artist == null)) {
      return PanelEmpty(
        side: side,
        icon: Icons.music_note_outlined,
        label: AppLocalizations.of(context).nowPlayingIdle,
      );
    }

    final art = np.artBytes != null
        ? MemoryImage(np.artBytes!)
        : artImageProvider(np.artUri);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (art != null) _Backdrop(art: art),
        // Progress ring near the rim, outside the inscribed content square.
        if (np.progress != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _RingPainter(
                fraction: np.progress!,
                progress: colors.primary,
                track: colors.onSurface.withValues(alpha: 0.15),
                strokeWidth: side * 0.018,
                inset: side * 0.02,
              ),
            ),
          ),
        Padding(
          padding: m.pageInset,
          child: _Content(side: side, m: m, np: np, art: art),
        ),
      ],
    );
  }
}

/// The blurred, dimmed cover art filling the whole panel behind the content.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.art});

  final ImageProvider art;

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).brightness == Brightness.dark ? 0.55 : 0.35;
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Image(
          image: art,
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: dim),
          colorBlendMode: BlendMode.darken,
          // A missing/failed backdrop just leaves the panel background.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Foreground: cover thumbnail, title/artist, and the transport row, stacked in
/// the panel's inscribed square on a translucent card for legibility over art.
class _Content extends StatelessWidget {
  const _Content({
    required this.side,
    required this.m,
    required this.np,
    required this.art,
  });

  final double side;
  final PanelMetrics m;
  final NowPlaying np;
  final ImageProvider? art;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final artSize = side * 0.22;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: side * 0.028,
          vertical: side * 0.03,
        ),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: m.cardAlpha),
          borderRadius: BorderRadius.circular(m.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(m.cardRadius * 0.6),
              child: SizedBox(
                width: artSize,
                height: artSize,
                child: art != null
                    ? Image(
                        image: art!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _ArtPlaceholder(size: artSize),
                      )
                    : _ArtPlaceholder(size: artSize),
              ),
            ),
            SizedBox(height: m.gap),
            Text(
              np.title ?? np.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: panelFont(m.fontMd, m.weightBold, colors.onSurface),
            ),
            if (np.artist != null) ...[
              SizedBox(height: side * 0.008),
              Text(
                np.artist!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: panelFont(
                  m.fontSm,
                  m.weightRegular,
                  colors.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: m.gap),
            _Transport(side: side, m: m, np: np),
          ],
        ),
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.album_outlined,
        size: size * 0.5,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

/// Previous / play-pause / next. Each tap buzzes the panel (DRV2605L) before
/// forwarding the intent to the player, so controls feel physical.
class _Transport extends StatelessWidget {
  const _Transport({required this.side, required this.m, required this.np});

  final double side;
  final PanelMetrics m;
  final NowPlaying np;

  void _tap(BuildContext context, VoidCallback action) {
    context.read<PicoViewService>().playHaptic(AlertEffect.tick.effect);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NowPlayingCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TransportButton(
          icon: Icons.skip_previous,
          size: side * 0.08,
          enabled: np.canPrevious,
          onTap: () => _tap(context, cubit.previous),
        ),
        SizedBox(width: side * 0.03),
        _TransportButton(
          icon: np.playing ? Icons.pause : Icons.play_arrow,
          size: side * 0.105,
          primary: true,
          onTap: () => _tap(context, cubit.playPause),
        ),
        SizedBox(width: side * 0.03),
        _TransportButton(
          icon: Icons.skip_next,
          size: side * 0.08,
          enabled: np.canNext,
          onTap: () => _tap(context, cubit.next),
        ),
      ],
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fg = !enabled
        ? colors.onSurfaceVariant.withValues(alpha: 0.4)
        : primary
        ? colors.onPrimary
        : colors.onSurface;
    final diameter = size * 1.6;
    return Material(
      color: primary ? colors.primary : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Icon(icon, size: size, color: fg),
        ),
      ),
    );
  }
}

/// Paints the playhead as an arc that starts at 12 o'clock and sweeps clockwise,
/// sitting just inside the panel rim (outside the content square).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.progress,
    required this.track,
    required this.strokeWidth,
    required this.inset,
  });

  final double fraction;
  final Color progress;
  final Color track;
  final double strokeWidth;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2 - inset - strokeWidth / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = progress;
    // Start at top (−90°), sweep clockwise by the played fraction.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.progress != progress ||
      old.track != track ||
      old.strokeWidth != strokeWidth ||
      old.inset != inset;
}
