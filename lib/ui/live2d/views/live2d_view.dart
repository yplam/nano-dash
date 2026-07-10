import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../cubit/live2d_cubit.dart';

/// Shows the app-wide Live2D renderer ([Live2dCubit]) as an LCD page.
///
/// A [Ticker] polls the native worker for the newest RGBA frame, decodes it to a
/// [ui.Image], and paints it with [RawImage] so the enclosing `PicoView`'s
/// `RepaintBoundary` mirrors it to the panel.
class Live2dView extends StatefulWidget {
  const Live2dView({
    super.key,
    required this.modelDir,
    this.backgroundPath = '',
  });

  /// Directory holding the model's `*.model3.json`; empty means "none chosen".
  final String modelDir;

  /// Absolute path to a background image painted under the model; empty falls
  /// back to the app-wide background showing through the transparent frame.
  final String backgroundPath;

  @override
  State<Live2dView> createState() => _Live2dViewState();
}

class _Live2dViewState extends State<Live2dView>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  ui.Image? _image;
  bool _decoding = false;

  /// Cached cubit so [dispose] can reach it without a `context` lookup: when the
  /// app is backgrounded the whole subtree (including the provider above us)
  /// unmounts in one pass, and by the time our `dispose` runs the provider
  /// element is already gone, so `context.read` there throws.
  Live2dCubit? _cubit;

  /// Pointer-down position, to tell a tap (→ motion) from a drag (→ look-at).
  Offset? _downAt;

  @override
  void initState() {
    super.initState();
    // Kick the load after the first frame so the cubit is readable from context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<Live2dCubit>();
      // This page is on-screen again — resume the worker paused on the last
      // dispose (the carousel disposes/recreates the page on every swipe).
      cubit.resume();
      cubit.loadModel(widget.modelDir);
    });
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Grab the cubit while the widget is active; [dispose] uses this instead of
    // a `context.read`, which is unsafe once the provider above us has unmounted.
    _cubit = context.read<Live2dCubit>();
  }

  @override
  void didUpdateWidget(covariant Live2dView old) {
    super.didUpdateWidget(old);
    if (old.modelDir != widget.modelDir) {
      context.read<Live2dCubit>().loadModel(widget.modelDir);
    }
  }

  /// Drain at most one frame per tick: acquire → decode (async) → release in the
  /// decode callback (the native buffer stays pinned until then), with a guard so
  /// overlapping decodes never read a buffer that's been released.
  void _onTick(Duration _) {
    if (_decoding) return;
    final controller = context.read<Live2dCubit>().controller;
    if (controller == null) return;
    final frame = controller.acquireFrame();
    if (frame == null) return;
    _decoding = true;
    ui.decodeImageFromPixels(
      frame,
      controller.width,
      controller.height,
      ui.PixelFormat.rgba8888,
      (img) {
        controller.releaseFrame();
        _decoding = false;
        if (!mounted) {
          img.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = img;
        });
      },
    );
  }

  @override
  void dispose() {
    // The page is leaving the tree (carousel swipe / navigation); nothing will
    // consume frames, so park the app-scoped worker until this page returns.
    _cubit?.pause();
    _ticker?.dispose();
    _image?.dispose();
    super.dispose();
  }

  /// Normalize a local pixel position to the model's [-1, 1] space (y flipped:
  /// screen-down → model-up).
  (double, double) _normalize(Offset p, Size size) {
    final nx = (p.dx / size.width) * 2 - 1;
    final ny = -((p.dy / size.height) * 2 - 1);
    return (nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<Live2dCubit, Live2dState>(
      builder: (context, state) {
        return switch (state) {
          Live2dReady() => _buildModel(context),
          Live2dLoading() => const Center(child: CircularProgressIndicator()),
          Live2dError(:final kind) => Center(
            child: _Message(
              icon: Icons.error_outline,
              text: switch (kind) {
                Live2dErrorKind.noModelJson => l10n.live2dNoModelJson,
                Live2dErrorKind.loadFailed => l10n.live2dLoadFailed,
              },
            ),
          ),
          Live2dUnavailable() => Center(
            child: _Message(icon: Icons.block, text: l10n.live2dUnavailable),
          ),
          Live2dIdle() => Center(
            child: _Message(
              icon: Icons.face_retouching_natural,
              text: l10n.live2dPickHint,
            ),
          ),
        };
      },
    );
  }

  Widget _buildModel(BuildContext context) {
    final image = _image;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          onPointerDown: (e) {
            _downAt = e.localPosition;
            _sendDrag(context, e.localPosition, size);
          },
          onPointerMove: (e) => _sendDrag(context, e.localPosition, size),
          onPointerUp: (e) {
            final down = _downAt;
            _downAt = null;
            // A small total travel reads as a tap → trigger a motion.
            if (down != null && (e.localPosition - down).distance < 12) {
              final controller = context.read<Live2dCubit>().controller;
              if (controller != null) {
                final (nx, ny) = _normalize(e.localPosition, size);
                controller.tap(nx, ny);
              }
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.backgroundPath.isNotEmpty)
                Image.file(
                  File(widget.backgroundPath),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stack) =>
                      const ColoredBox(color: Colors.transparent),
                ),
              if (image != null)
                RawImage(
                  image: image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
            ],
          ),
        );
      },
    );
  }

  void _sendDrag(BuildContext context, Offset p, Size size) {
    final controller = context.read<Live2dCubit>().controller;
    if (controller == null) return;
    final (nx, ny) = _normalize(p, size);
    controller.setDrag(nx, ny);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 40),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
