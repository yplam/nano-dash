import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pico_view/pico_view.dart';

import '../../../data/services/pico_view_service.dart';
import '../../../domain/models/now_playing.dart';
import '../../../extensions/loggable.dart';

part 'now_playing_state.dart';

/// Mirrors the host's media session into the Now Playing page and forwards the
/// panel's transport taps back to the player.
class NowPlayingCubit extends Cubit<NowPlayingState> with Loggable {
  NowPlayingCubit(this._pico) : super(const NowPlayingState()) {
    _sub = _pico.mediaEvents.listen(_onSnapshot);
    _pico.startMedia();
  }

  final PicoViewService _pico;
  late final StreamSubscription<PicoMediaSnapshot?> _sub;

  String? _artKey;
  Uri? _artUri;
  Uint8List? _artBytes;

  @override
  String get logIdentifier => '[NowPlayingCubit]';

  void playPause() => _pico.mediaControl(PicoMediaCommand.playPause);

  void next() => _pico.mediaControl(PicoMediaCommand.next);

  void previous() => _pico.mediaControl(PicoMediaCommand.previous);

  void _onSnapshot(PicoMediaSnapshot? m) {
    if (isClosed) return;
    if (m == null) {
      _artKey = null;
      _artUri = null;
      _artBytes = null;
      emit(const NowPlayingState());
      return;
    }

    final key = '${m.playerName} ${m.title} ${m.artist} ${m.album}';
    if (key != _artKey) {
      _artKey = key;
      _artUri = null;
      _artBytes = null;
    }
    if (m.artBytes != null) {
      _artBytes = m.artBytes;
      _artUri = null;
    } else if (m.artUri.isNotEmpty) {
      _artUri = Uri.tryParse(m.artUri);
      _artBytes = null;
    }

    emit(
      NowPlayingState(
        current: NowPlaying(
          playerName: m.playerName,
          title: m.title.isEmpty ? null : m.title,
          artist: m.artist.isEmpty ? null : m.artist,
          album: m.album.isEmpty ? null : m.album,
          artUri: _artUri,
          artBytes: _artBytes,
          position: m.position,
          duration: m.duration,
          playing: m.playing,
          canNext: m.canNext,
          canPrevious: m.canPrevious,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    _pico.stopMedia();
    return super.close();
  }
}
