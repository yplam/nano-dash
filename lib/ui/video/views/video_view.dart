import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_empty.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/video_cubit.dart';

/// The Video page. The panel itself shows the decoded frames ; this on-screen
/// page carries the controls.
class VideoView extends StatelessWidget {
  const VideoView({super.key});

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
        return BlocBuilder<VideoCubit, VideoState>(
          builder: (context, state) => _body(context, side, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, VideoState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<VideoCubit>();

    switch (state.status) {
      case VideoStatus.idle:
        // Nothing is remembered across sessions: the whole page opens the
        // picker so the user always chooses a file to play.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cubit.pickAndPlay,
          child: PanelEmpty(
            side: side,
            icon: Icons.movie_outlined,
            label: l10n.videoIdle,
            hint: l10n.videoPickHint,
          ),
        );
      case VideoStatus.error:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cubit.pickAndPlay,
          child: PanelEmpty(
            side: side,
            icon: Icons.error_outline,
            label: _errorText(l10n, state.error),
            hint: l10n.videoPickHint,
          ),
        );
      case VideoStatus.playing:
      case VideoStatus.paused:
        return _Playing(side: side, state: state, cubit: cubit);
    }
  }

  static String _errorText(AppLocalizations l10n, VideoError? error) {
    switch (error) {
      case VideoError.ffmpegMissing:
        return l10n.videoErrorFfmpeg;
      case VideoError.unknownPanelSize:
        return l10n.videoErrorPanel;
      case VideoError.decodeEnded:
        return l10n.videoErrorDecode;
      case VideoError.unknown:
      case null:
        return l10n.videoError;
    }
  }
}

class _Playing extends StatefulWidget {
  const _Playing({
    required this.side,
    required this.state,
    required this.cubit,
  });

  final double side;
  final VideoState state;
  final VideoCubit cubit;

  @override
  State<_Playing> createState() => _PlayingState();
}

class _PlayingState extends State<_Playing> {
  double? _dragSec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = widget.cubit;
    final state = widget.state;
    final side = widget.side;
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final paused = state.isPaused;
    final seekable = state.hasAudio;

    final big = side * 0.15;
    final small = side * 0.115;
    final btnGap = side * 0.03;

    final transport = <Widget>[
      if (seekable) ...[
        _RoundButton(
          size: small,
          icon: Icons.replay_10,
          tooltip: l10n.videoRewind,
          onPressed: () => cubit.seekBy(const Duration(seconds: -10)),
        ),
        SizedBox(width: btnGap),
      ],
      _RoundButton(
        size: big,
        icon: paused ? Icons.play_arrow : Icons.pause,
        tooltip: paused ? l10n.videoResume : l10n.videoPause,
        onPressed: cubit.togglePause,
      ),
      SizedBox(width: btnGap),
      if (seekable) ...[
        _RoundButton(
          size: small,
          icon: Icons.forward_10,
          tooltip: l10n.videoForward,
          onPressed: () => cubit.seekBy(const Duration(seconds: 10)),
        ),
        SizedBox(width: btnGap),
      ],
      _RoundButton(
        size: small,
        icon: Icons.stop,
        tooltip: l10n.videoStop,
        onPressed: cubit.stop,
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cubit.togglePause,
          onLongPress: cubit.stop,
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side * 0.12),
                child: Text(
                  state.fileName ?? l10n.videoPlaying,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelFont(
                    m.fontSm,
                    m.weightMedium,
                    colors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: m.gap),
              Row(mainAxisSize: MainAxisSize.min, children: transport),
              if (seekable) ...[
                SizedBox(height: m.gap * 0.5),
                _Progress(
                  side: side,
                  metrics: m,
                  positionSec: _dragSec ?? state.positionSec,
                  durationSec: state.durationSec,
                  onChanged: (v) => setState(() => _dragSec = v),
                  onChangeEnd: (v) {
                    cubit.seek(v);
                    setState(() => _dragSec = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The scrubbable progress bar plus elapsed / total time labels.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.side,
    required this.metrics,
    required this.positionSec,
    required this.durationSec,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double side;
  final PanelMetrics metrics;
  final double positionSec;
  final double durationSec;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dur = math.max(durationSec, 0.001);
    final pos = positionSec.clamp(0.0, dur);
    return SizedBox(
      width: side * 0.74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: side * 0.012,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: side * 0.022,
              ),
              overlayShape: RoundSliderOverlayShape(overlayRadius: side * 0.04),
            ),
            child: Slider(
              value: pos,
              max: dur,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: side * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(pos),
                  style: panelFont(
                    metrics.fontSm,
                    metrics.weightRegular,
                    colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  _fmt(durationSec),
                  style: panelFont(
                    metrics.fontSm,
                    metrics.weightRegular,
                    colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double sec) {
    final total = sec.isFinite && sec > 0 ? sec.round() : 0;
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// A translucent round icon button sized for the panel.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.5, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}
