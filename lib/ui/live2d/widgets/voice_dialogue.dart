import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../agent/agent.dart';
import '../../voice/cubit/voice_cubit.dart';
import 'dialogue_box.dart';

/// A [DialogueBox] over the conversation: it shows the last thing the user
/// said, the assistant's reply as it streams in, and then gets out of the way —
/// each side fades out [dwell] after it last changed.
///
/// A reply that is still streaming always wins; otherwise whichever side spoke
/// more recently is shown. Closing the engine (or an engine error) clears the
/// box at once — dialogue that outlives the microphone reads as if the avatar
/// were still listening.
///
/// Dwells are measured from the utterance/reply's own timestamps, not from the
/// moment this widget saw them, so a page remounted over an already-running
/// engine (the LCD carousel disposes a page's subtree on every swipe) shows an
/// entry for the remainder of its life and never resurrects a stale one.
///
/// Text too long to fit is the exception: [DialogueBox] auto-scrolls it, so its
/// dwell can't start ticking against the clock while it is still scrolling.
/// [DialogueBox] reports its reveal state as a level (see
/// [DialogueBox.onRevealingChanged]); while an entry is revealing, this widget
/// suspends the timestamp dwell entirely and instead lingers [revealLinger] from
/// the moment the scroll reaches the bottom — the reply stays up until it has
/// been read in full, and then only briefly, since the reader has just followed
/// the whole thing down.
class VoiceDialogue extends StatefulWidget {
  const VoiceDialogue({
    super.key,
    required this.side,
    this.dwell = _kDwell,
    this.revealLinger = _kRevealLinger,
  });

  /// The panel's `min(width, height)`, forwarded to [DialogueBox].
  final double side;

  /// How long an entry that fits stays on screen after it last changed.
  final Duration dwell;

  /// How long an entry that had to scroll lingers after its reveal reaches the
  /// bottom. Shorter than [dwell]: the reader has just watched the whole reply
  /// glide past, so it only needs a beat to rest on the last lines.
  final Duration revealLinger;

  static const Duration _kDwell = Duration(seconds: 10);
  static const Duration _kRevealLinger = Duration(seconds: 4);

  @override
  State<VoiceDialogue> createState() => _VoiceDialogueState();
}

/// One thing the box can show: either the user's utterance or the assistant's
/// (possibly still streaming) reply.
class _Entry {
  const _Entry({
    required this.key,
    required this.text,
    required this.isUser,
    required this.time,
    this.remaining,
    this.streaming = false,
  });

  /// Stable per utterance/reply, so the switcher cross-fades between entries
  /// but updates a streaming reply's text in place.
  final Object key;

  final String text;
  final bool isUser;

  /// When this entry last changed — what its dwell is measured from.
  final DateTime time;

  /// Time left before this entry expires, or null while it is still growing.
  final Duration? remaining;

  /// A still-streaming reply: it never expires and its dwell is irrelevant.
  final bool streaming;
}

class _VoiceDialogueState extends State<VoiceDialogue> {
  /// Timestamp-based hide: fires [dwell] after the entry last changed.
  Timer? _timer;

  /// Reveal-based hide: for text long enough to scroll, dismissal waits until
  /// [DialogueBox] reports it has scrolled to the bottom, then lingers
  /// [VoiceDialogue.revealLinger] from there.
  Timer? _revealTimer;

  /// True while the shown entry's reveal owns its dismissal: set the moment
  /// [DialogueBox] reports it is scrolling, cleared only when [_revealTimer]
  /// finally retires the entry (or when a different entry takes over). While
  /// set, the timestamp dwell is suspended and the entry is kept alive
  /// regardless of the clock, so a long reply is never cut off mid-scroll —
  /// including across the streaming→done handoff, where the finished reply
  /// carries the same text and so never rebuilds the box.
  bool _revealOwned = false;

  _Entry? _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  /// Recompute what to show. [expiredThrough] is set when the shown entry's
  /// dwell timer fired: that entry — and anything older — is expired no matter
  /// what the wall clock says, because a test's fake clock (or a suspended
  /// machine) may leave `DateTime.now()` behind the timers.
  void _sync([DateTime? expiredThrough]) {
    if (!mounted) return;
    final next = _pick(
      context.read<VoiceCubit>().state,
      context.read<AgentCubit>().state,
      expiredThrough,
    );
    // A different entry (or none) retires the old one's reveal lifecycle.
    if (_shown?.key != next?.key) {
      _revealOwned = false;
      _revealTimer?.cancel();
      _revealTimer = null;
    }
    // (Re)arm the timestamp-based hide, unless a reveal owns dismissal (a held
    // entry carries no remaining, and streaming replies never carry one).
    _timer?.cancel();
    _timer = null;
    final remaining = next?.remaining;
    if (remaining != null && !_revealOwned) {
      _timer = Timer(remaining, () => _sync(next!.time));
    }
    if (_shown?.key == next?.key && _shown?.text == next?.text) {
      _shown = next;
      return;
    }
    setState(() => _shown = next);
  }

  /// [DialogueBox] reports whether the shown entry is mid-reveal. The [key]
  /// guards against a stale, still-fading box reporting for the entry that
  /// replaced it.
  ///
  /// `revealing` true — the text is too tall and hasn't reached the bottom:
  /// suspend the timestamp dwell and let the reveal own dismissal, so the text
  /// is never hidden mid-scroll. Set even for a still-streaming reply, so the
  /// hold is already in place when it finishes (the done reply reuses the same
  /// text and so never rebuilds the box to re-announce itself).
  ///
  /// `revealing` false — the scroll reached the bottom (ignored for text that
  /// simply fits and never claimed the reveal): the reply is fully shown, so
  /// linger [VoiceDialogue.revealLinger] from this moment before retiring it.
  void _onRevealingChanged(Object key, bool revealing) {
    final shown = _shown;
    if (shown == null || shown.key != key) return;
    if (revealing) {
      _revealOwned = true;
      _timer?.cancel();
      _timer = null;
      // A restarted reveal (streaming appended more text) cancels a linger that
      // an earlier bottom may have armed.
      _revealTimer?.cancel();
      _revealTimer = null;
    } else if (_revealOwned) {
      _revealTimer?.cancel();
      _revealTimer = Timer(widget.revealLinger, () {
        _revealOwned = false;
        _sync(shown.time);
      });
    }
  }

  /// The entry worth showing right now, or null to hide the box.
  _Entry? _pick(VoiceState voice, AgentState agent, DateTime? expiredThrough) {
    if (!voice.status.isOpen) return null;
    final now = DateTime.now();
    bool expired(DateTime time) =>
        expiredThrough != null && !time.isAfter(expiredThrough);

    // While a scrolling entry's reveal owns dismissal its timestamp dwell is
    // suspended, so keep whichever entry we are holding alive regardless of the
    // clock; [_revealTimer] retires it once fully shown and lingered.
    bool held(Object key) => _revealOwned && _shown?.key == key;

    final reply = agent.reply;
    _Entry? replyEntry;
    if (reply != null && reply.text.trim().isNotEmpty) {
      if (!reply.done) {
        // Still streaming: always on top, expiry irrelevant.
        return _Entry(
          key: reply.started,
          text: reply.text,
          isUser: false,
          time: reply.updated,
          streaming: true,
        );
      }
      final left = widget.dwell - now.difference(reply.updated);
      final keep = held(reply.started);
      if (keep || (left > Duration.zero && !expired(reply.updated))) {
        replyEntry = _Entry(
          key: reply.started,
          text: reply.text,
          isUser: false,
          time: reply.updated,
          remaining: keep ? null : left,
        );
      }
    }

    final transcript = voice.lastTranscript;
    _Entry? userEntry;
    if (transcript != null && transcript.text.trim().isNotEmpty) {
      final left = widget.dwell - now.difference(transcript.time);
      final keep = held(transcript);
      if (keep || (left > Duration.zero && !expired(transcript.time))) {
        userEntry = _Entry(
          key: transcript,
          text: transcript.text,
          isUser: true,
          time: transcript.time,
          remaining: keep ? null : left,
        );
      }
    }

    if (replyEntry == null) return userEntry;
    if (userEntry == null) return replyEntry;
    // Both alive: show whichever side of the exchange spoke last.
    return userEntry.time.isAfter(replyEntry.time) ? userEntry : replyEntry;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = _shown;
    return MultiBlocListener(
      listeners: [
        BlocListener<VoiceCubit, VoiceState>(
          listenWhen: (prev, curr) =>
              !identical(prev.lastTranscript, curr.lastTranscript) ||
              prev.status != curr.status,
          listener: (context, state) => _sync(),
        ),
        BlocListener<AgentCubit, AgentState>(
          listenWhen: (prev, curr) => !identical(prev.reply, curr.reply),
          listener: (context, state) => _sync(),
        ),
      ],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: shown == null
            ? const SizedBox.shrink()
            : DialogueBox(
                key: ValueKey(shown.key),
                side: widget.side,
                text: shown.text,
                speaker: shown.isUser
                    ? l10n.voiceSpeakerYou
                    : l10n.agentSpeakerName,
                onRevealingChanged: (revealing) =>
                    _onRevealingChanged(shown.key, revealing),
              ),
      ),
    );
  }
}
