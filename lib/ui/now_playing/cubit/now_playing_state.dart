part of 'now_playing_cubit.dart';

/// View state for the Now Playing page. [current] is `null` when nothing is
/// playing (or the platform can't observe media sessions).
class NowPlayingState {
  const NowPlayingState({this.current});

  final NowPlaying? current;
}
