part of 'video_cubit.dart';

enum VideoStatus { idle, playing, paused, error }

/// Why playback couldn't start or keep going.
enum VideoError { ffmpegMissing, unknownPanelSize, decodeEnded, unknown }

/// State of the local-file video player mirrored to the panel.
class VideoState {
  const VideoState({
    this.status = VideoStatus.idle,
    this.fileName,
    this.filePath,
    this.error,
    this.frameCount = 0,
    this.volume = 80,
    this.hasAudio = false,
    this.positionSec = 0,
    this.durationSec = 0,
  });

  final VideoStatus status;
  final String? fileName;
  final String? filePath;
  final VideoError? error;

  /// Total frames pushed to the panel so far (diagnostics).
  final int frameCount;

  /// Audio volume on media_kit's 0–100 scale.
  final double volume;

  /// Whether the current playback has an audio track driving the clock. Silent
  /// free-run playback (unknown duration) has none, so seeking and the progress
  /// bar are unavailable.
  final bool hasAudio;

  /// Current playback position within the file, in seconds. Only meaningful when
  /// [hasAudio] is true (an audio clock exists); 0 otherwise.
  final double positionSec;

  /// Total duration of the file, in seconds. `0` when unknown (free-run), which
  /// is what [hasAudio] being false implies.
  final double durationSec;

  bool get isPlaying => status == VideoStatus.playing;

  bool get isPaused => status == VideoStatus.paused;

  bool get isActive => isPlaying || isPaused;

  VideoState copyWith({
    VideoStatus? status,
    String? fileName,
    String? filePath,
    VideoError? error,
    int? frameCount,
    double? volume,
    bool? hasAudio,
    double? positionSec,
    double? durationSec,
  }) => VideoState(
    status: status ?? this.status,
    fileName: fileName ?? this.fileName,
    filePath: filePath ?? this.filePath,
    error: error,
    frameCount: frameCount ?? this.frameCount,
    volume: volume ?? this.volume,
    hasAudio: hasAudio ?? this.hasAudio,
    positionSec: positionSec ?? this.positionSec,
    durationSec: durationSec ?? this.durationSec,
  );
}
