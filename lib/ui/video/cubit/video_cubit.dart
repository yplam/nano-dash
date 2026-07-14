import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';

import '../../../data/services/ffmpeg_locator.dart';
import '../../../data/services/pico_view_service.dart';
import '../../../extensions/loggable.dart';

part 'video_state.dart';

/// The frame rate we decode video at.
const int _kFps = 25;

/// Plays a local video file onto the round panel (LCD-only), with audio on the
/// host speakers — a normal play-once player: it decodes from the current
/// position to the end and then returns to idle.
///
/// Frames bypass the [PicoView] mirror entirely: an `ffmpeg` subprocess decodes
/// the file to a raw RGBA stream scaled/cropped to the panel, and each complete
/// frame is pushed straight to the device via [PicoViewService.controller.flushRgba].
/// While a video is playing we set `controller.suspendCapture`, so the mirror
/// loop stands down and doesn't fight us for the panel.
///
/// Audio plays through a media_kit [Player] (audio-only — no GPU texture, which
/// `RepaintBoundary.toImage()` can't read anyway). The audio clock is the
/// master: decoded frames are buffered in [_queue] and a pump ([_pumpTimer])
/// presents the frame matching the current `player.stream.position` rather than
/// pushing every frame the instant it arrives. Both the audio and ffmpeg's `-re`
/// pacing run at real time, so the buffer stays small; the pump corrects the
/// slow A/V drift that would otherwise accumulate.
///
/// Pause freezes both clocks together: `SIGSTOP` halts the ffmpeg decoder while
/// the audio player pauses, so no frames arrive and the panel holds the last
/// one; `SIGCONT` + resume picks up exactly where it left off, still aligned.
///
/// Seeking ([seek]/[seekBy]) is only possible with an audio clock: the pipe is
/// paced to real time and can't fast-forward, so a seek restarts ffmpeg at the
/// target with an `-ss` input seek and moves the audio to match. It resumes
/// playback from the new position.
///
/// If the file's duration can't be determined (or the player fails to open) we
/// fall back to silent free-running frames paced only by `ffmpeg -re`, with no
/// seeking or progress bar.
class VideoCubit extends Cubit<VideoState> with Loggable {
  VideoCubit(this._pico, {required this._ffmpegPath})
    : super(const VideoState());

  final PicoViewService _pico;

  /// User-chosen `ffmpeg` command for this module (empty = auto-detect). Read
  /// once when the page is built, from the Video module's settings.
  final String _ffmpegPath;

  /// The running decoder, or null when idle.
  Process? _proc;
  StreamSubscription<List<int>>? _stdoutSub;
  StreamSubscription<List<int>>? _stderrSub;

  /// Audio playback + master clock. Null until [play] opens a file.
  Player? _player;
  StreamSubscription<Duration>? _positionSub;

  /// Presents buffered frames in step with the audio clock (sync mode only).
  Timer? _pumpTimer;

  /// Reassembles the raw RGBA byte stream into whole panel frames.
  final BytesBuilder _pending = BytesBuilder(copy: false);

  /// Decoded frames awaiting presentation (sync mode). The frame at the front
  /// has decode index [_headIndex]; each subsequent frame is one index higher.
  final Queue<Uint8List> _queue = Queue<Uint8List>();

  /// Absolute frame index of the frame at the front of [_queue]. After a seek to
  /// `t` seconds the decoder's first emitted frame is `round(t * _kFps)`, so this
  /// stays aligned with the audio-derived target across seeks.
  int _headIndex = 0;

  /// Decode index of the frame most recently pushed to the panel, so the pump
  /// doesn't re-flush an unchanged frame (e.g. while the audio is paused).
  int _lastFlushedIndex = -1;

  /// Total duration of the file, in seconds. `0` means sync is disabled and we
  /// free-run (unknown duration / player failed to open).
  double _durationSec = 0;

  /// Latest audio position, in seconds.
  double _positionSec = 0;

  /// Last position value pushed to [state], so we throttle progress-bar rebuilds
  /// rather than emit on every media_kit position tick.
  double _lastEmittedPos = -1;

  int _frames = 0;

  bool get _synced => _durationSec > 0;

  @override
  String get logIdentifier => '[VideoCubit]';

  int get _frameBytes {
    final cfg = _pico.controller.config;
    return cfg.width * cfg.height * 4;
  }

  /// Prompt for a local video file and start playing it on the panel.
  Future<void> pickAndPlay() async {
    const group = XTypeGroup(
      label: 'Video',
      extensions: ['mp4', 'mkv', 'mov', 'webm', 'avi', 'm4v'],
      mimeTypes: ['video/*'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return; // cancelled
    await play(file.path);
  }

  /// Start decoding [path] from the beginning and pushing its frames to the
  /// panel.
  Future<void> play(String path) async {
    await _teardownDecoder();
    _frames = 0;
    _pending.clear();
    _resetSync();

    final cfg = _pico.controller.config;
    if (cfg.width == 0 || cfg.height == 0) {
      emit(
        state.copyWith(
          status: VideoStatus.error,
          error: VideoError.unknownPanelSize,
        ),
      );
      return;
    }

    await _startAudio(path);

    // Take the panel away from the mirror loop for the duration of playback.
    _pico.controller.suspendCapture = true;

    if (!await _spawnDecoder(path, atSec: 0)) {
      await _stopAudio();
      _pico.controller.suspendCapture = false;
      emit(
        state.copyWith(
          status: VideoStatus.error,
          error: VideoError.ffmpegMissing,
        ),
      );
      return;
    }

    // Drive presentation off the audio clock. In free-run mode _onBytes flushes
    // frames directly instead.
    if (_synced) {
      _pumpTimer = Timer.periodic(const Duration(milliseconds: 16), _pump);
      unawaited(_player?.play());
    }

    emit(
      state.copyWith(
        status: VideoStatus.playing,
        filePath: path,
        fileName: _basename(path),
        frameCount: 0,
        hasAudio: _synced,
        positionSec: 0,
        durationSec: _durationSec,
      ),
    );
  }

  /// Pause playback: freeze the decoder and the audio clock together so the
  /// panel holds the current frame and A/V stays aligned on resume.
  Future<void> pause() async {
    if (!state.isPlaying) return;
    _proc?.kill(ProcessSignal.sigstop);
    await _player?.pause();
    if (!isClosed) emit(state.copyWith(status: VideoStatus.paused));
  }

  /// Resume from a [pause]: unfreeze the decoder and restart audio.
  Future<void> resume() async {
    if (!state.isPaused) return;
    _proc?.kill(ProcessSignal.sigcont);
    unawaited(_player?.play());
    if (!isClosed) emit(state.copyWith(status: VideoStatus.playing));
  }

  Future<void> togglePause() {
    if (state.isPaused) return resume();
    if (state.isPlaying) return pause();
    return Future.value();
  }

  /// Jump [delta] from the current position (negative to rewind). No-op without
  /// an audio clock.
  Future<void> seekBy(Duration delta) {
    final ms = delta.inMicroseconds / Duration.microsecondsPerSecond;
    return seek(_positionSec + ms);
  }

  /// Seek to [sec] seconds and resume playback there. Restarts the ffmpeg
  /// decoder with an `-ss` input seek and moves the audio to match. No-op
  /// without an audio clock (the pipe can't fast-forward) or when idle.
  Future<void> seek(double sec) async {
    final path = state.filePath;
    if (!_synced || path == null || !state.isActive) return;
    final target = sec.clamp(0.0, _durationSec).toDouble();

    if (!await _restartDecoder(path, atSec: target)) {
      await _teardownDecoder();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: VideoStatus.error,
            error: VideoError.decodeEnded,
          ),
        );
      }
      return;
    }

    _positionSec = target;
    _lastEmittedPos = target;
    unawaited(
      _player?.seek(
        Duration(
          microseconds: (target * Duration.microsecondsPerSecond).round(),
        ),
      ),
    );
    unawaited(_player?.play());
    if (!isClosed) {
      emit(state.copyWith(status: VideoStatus.playing, positionSec: target));
    }
  }

  /// Stop playback and hand the panel back to the mirror loop.
  Future<void> stop() async {
    await _teardownDecoder();
    if (!isClosed) {
      // Preserve the volume across the reset to idle.
      emit(VideoState(volume: state.volume));
    }
  }

  /// Start an ffmpeg decoder for [path] beginning at [atSec] and wire up its
  /// stdout/stderr + exit handling. Resets the frame reassembly + pump indices
  /// so the queue is aligned to the seek point. Returns false if the process
  /// can't be spawned.
  Future<bool> _spawnDecoder(String path, {required double atSec}) async {
    final cfg = _pico.controller.config;
    final w = cfg.width;
    final h = cfg.height;

    // -ss before -i seeks the input (fast, keyframe-accurate). -re paces output
    // to real time. The filter fits the whole frame inside the panel square
    // (letterbox) and caps to _kFps. rawvideo/rgba on stdout is exactly w*h*4
    // bytes per frame, in order.
    //
    // The panel is round, so we fit ("contain") rather than fill-and-crop
    // ("cover"): the entire video is scaled to fit the w×h square and centered
    // on a black pad. This keeps most of the frame visible — only the four
    // corners of the square spill past the circular bezel and get clipped —
    // instead of cropping ~44% off the sides of a landscape video to fill it.
    final args = <String>[
      '-loglevel',
      'error',
      if (atSec > 0) ...['-ss', atSec.toStringAsFixed(3)],
      '-re',
      '-i',
      path,
      '-an',
      '-vf',
      'scale=$w:$h:force_original_aspect_ratio=decrease,'
          'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:color=black,fps=$_kFps',
      '-f',
      'rawvideo',
      '-pix_fmt',
      'rgba',
      'pipe:1',
    ];

    final ffmpeg = FfmpegLocator.resolve(_ffmpegPath);
    logInfo(
      'starting ffmpeg ($ffmpeg) for $path (${w}x$h, '
      'synced=$_synced, ss=${atSec.toStringAsFixed(3)})',
    );
    final Process proc;
    try {
      proc = await Process.start(ffmpeg, args);
    } catch (e, s) {
      logError('ffmpeg failed to start', error: e, stackTrace: s);
      return false;
    }
    _proc = proc;

    _pending.clear();
    _queue.clear();
    _headIndex = (atSec * _kFps).round();
    _lastFlushedIndex = -1;

    _stdoutSub = proc.stdout.listen(
      _onBytes,
      onError: (Object e, StackTrace s) =>
          logError('stdout error', error: e, stackTrace: s),
    );
    _stderrSub = proc.stderr.listen((bytes) {
      final msg = String.fromCharCodes(bytes).trim();
      if (msg.isNotEmpty) logWarning('ffmpeg: $msg');
    });
    _watchExit(proc);
    return true;
  }

  /// Kill the running decoder and start a fresh one at [atSec], keeping the panel
  /// and audio in place (used for seeking). Returns false if the new decoder
  /// can't be spawned.
  Future<bool> _restartDecoder(String path, {required double atSec}) async {
    final old = _proc;
    // Null it first so the old process's exit handler bails (see [_watchExit]).
    _proc = null;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    // A paused decoder is SIGSTOP'd; SIGKILL still reaps it.
    old?.kill();
    return _spawnDecoder(path, atSec: atSec);
  }

  /// Handle the decoder process exiting. A clean exit (code 0) is the file
  /// reaching its end → return to idle; a non-zero exit while we still think
  /// we're active means it died → surface an error. Exits from a superseded
  /// process (killed by a seek-restart or teardown) are ignored.
  void _watchExit(Process proc) {
    unawaited(
      proc.exitCode.then((code) async {
        if (_proc != proc) return; // superseded by a seek-restart or teardown
        logInfo('ffmpeg exited: $code');
        if (isClosed || !state.isActive) return;
        final reachedEnd = code == 0;
        await _teardownDecoder();
        if (isClosed) return;
        if (reachedEnd) {
          // Natural end → back to idle.
          emit(VideoState(volume: state.volume));
        } else {
          emit(
            state.copyWith(
              status: VideoStatus.error,
              error: VideoError.decodeEnded,
            ),
          );
        }
      }),
    );
  }

  /// Reassemble incoming bytes into whole frames. In sync mode each frame is
  /// buffered for the pump; in free-run mode it's flushed to the panel at once.
  void _onBytes(List<int> chunk) {
    final frameBytes = _frameBytes;
    _pending.add(chunk);
    if (_pending.length < frameBytes) return;

    final buf = _pending.takeBytes();
    var offset = 0;
    while (buf.length - offset >= frameBytes) {
      final frame = Uint8List.sublistView(buf, offset, offset + frameBytes);
      offset += frameBytes;
      if (_synced) {
        _enqueue(frame);
      } else {
        _flush(frame);
      }
    }
    // Carry any partial trailing frame into the next round.
    if (offset < buf.length) {
      _pending.add(Uint8List.sublistView(buf, offset));
    }
  }

  /// Buffer a decoded frame for the audio-driven pump, bounding memory if the
  /// audio ever stalls far behind the decoder.
  void _enqueue(Uint8List frame) {
    _queue.add(frame);
    // With `-re` this cap is never hit in steady state; it only guards against
    // the audio clock stalling (buffering/pause) while ffmpeg keeps decoding.
    const maxBuffered = _kFps * 3;
    while (_queue.length > maxBuffered) {
      _queue.removeFirst();
      _headIndex++;
    }
  }

  /// Present the buffered frame whose timestamp matches the audio clock.
  void _pump(Timer _) {
    if (isClosed || !_synced || _queue.isEmpty) return;
    final target = (_positionSec * _kFps).floor();
    // Advance past frames older than the target, always keeping at least one so
    // the panel holds a frame when the audio is paused or the decoder is behind.
    while (_queue.length > 1 && _headIndex < target) {
      _queue.removeFirst();
      _headIndex++;
    }
    if (_headIndex != _lastFlushedIndex) {
      _flush(_queue.first);
      _lastFlushedIndex = _headIndex;
    }
  }

  void _flush(Uint8List frame) {
    final cfg = _pico.controller.config;
    // flushRgba copies the bytes synchronously, so a view into the pipe buffer
    // is safe to hand it.
    _pico.controller.flushRgba(frame, cfg.width, cfg.height);
    _frames++;
    // Only the panel consumes frames; the on-screen page stays static. Emit a
    // coarse counter for diagnostics, never per frame.
    if (_frames % 25 == 0 && !isClosed) {
      emit(state.copyWith(frameCount: _frames));
    }
  }

  /// Open [path] in an audio-only [Player] and latch its duration, which enables
  /// audio-clock sync + seeking. Best-effort: any failure leaves [_durationSec]
  /// at 0 so playback free-runs silently.
  Future<void> _startAudio(String path) async {
    try {
      final player = Player();
      _player = player;
      await player.setVolume(state.volume);
      // Open paused; play() is called once ffmpeg is up so audio and video start
      // together (keeps their clocks aligned from frame 0).
      await player.open(Media(path), play: false);

      var dur = player.state.duration;
      if (dur <= Duration.zero) {
        dur = await player.stream.duration
            .firstWhere((d) => d > Duration.zero)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => Duration.zero,
            );
      }
      if (dur <= Duration.zero) {
        logWarning('no audio duration for $path; free-running silently');
        return; // _durationSec stays 0 → free-run
      }
      _durationSec = dur.inMicroseconds / Duration.microsecondsPerSecond;

      _positionSub = player.stream.position.listen((pos) {
        final p = pos.inMicroseconds / Duration.microsecondsPerSecond;
        _positionSec = p;
        // Throttle progress-bar rebuilds — the pump reads _positionSec directly,
        // so state only needs a coarse update for the on-screen scrubber.
        if (!isClosed && state.isActive && (p - _lastEmittedPos).abs() >= 0.2) {
          _lastEmittedPos = p;
          emit(state.copyWith(positionSec: p.clamp(0.0, _durationSec)));
        }
      });
    } catch (e, s) {
      logWarning('audio playback unavailable; free-running silently: $e');
      logDebug('audio open failure', error: e, stackTrace: s);
      await _stopAudio();
      _durationSec = 0;
    }
  }

  Future<void> _stopAudio() async {
    await _positionSub?.cancel();
    _positionSub = null;
    final player = _player;
    _player = null;
    await player?.dispose();
  }

  void _resetSync() {
    _pumpTimer?.cancel();
    _pumpTimer = null;
    _queue.clear();
    _headIndex = 0;
    _lastFlushedIndex = -1;
    _durationSec = 0;
    _positionSec = 0;
    _lastEmittedPos = -1;
  }

  Future<void> _teardownDecoder() async {
    _pico.controller.suspendCapture = false;
    _pumpTimer?.cancel();
    _pumpTimer = null;
    final proc = _proc;
    _proc = null;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _pending.clear();
    _queue.clear();
    await _stopAudio();
    // A paused decoder is SIGSTOP'd; SIGKILL still reaps it.
    proc?.kill();
  }

  static String _basename(String path) {
    final i = path.lastIndexOf(Platform.pathSeparator);
    return i >= 0 ? path.substring(i + 1) : path;
  }

  @override
  Future<void> close() async {
    await _teardownDecoder();
    return super.close();
  }
}
