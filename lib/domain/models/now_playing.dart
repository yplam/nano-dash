import 'dart:typed_data';

/// A snapshot of the host's currently-playing media session.
class NowPlaying {
  const NowPlaying({
    required this.playerName,
    this.title,
    this.artist,
    this.album,
    this.artUri,
    this.artBytes,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.canNext = false,
    this.canPrevious = false,
  });

  /// Human-readable source, e.g. `Spotify` or `Firefox` (the MPRIS identity).
  final String playerName;

  final String? title;
  final String? artist;
  final String? album;

  /// Cover art location: a `file://`, `http(s)://`, or `data:` URI, or `null`.
  /// Used on Linux (MPRIS). Mutually exclusive with [artBytes] in practice.
  final Uri? artUri;

  /// Cover art as raw image bytes (Windows/SMTC thumbnails, which have no URI),
  /// or `null` when art is a [artUri] or absent.
  final Uint8List? artBytes;

  /// Playhead position and total length. `duration == Duration.zero` means the
  /// player reported no length (live streams), so no progress ring is shown.
  final Duration position;
  final Duration duration;

  final bool playing;
  final bool canNext;
  final bool canPrevious;

  double? get progress {
    if (duration <= Duration.zero) return null;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.playerName == playerName &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.artUri == artUri &&
      other.artBytes == artBytes &&
      other.position == position &&
      other.duration == duration &&
      other.playing == playing &&
      other.canNext == canNext &&
      other.canPrevious == canPrevious;

  @override
  int get hashCode => Object.hash(
    playerName,
    title,
    artist,
    album,
    artUri,
    artBytes,
    position,
    duration,
    playing,
    canNext,
    canPrevious,
  );
}
