import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pico_view/pico_view.dart';

import '../../../data/services/pico_view_service.dart';
import '../../../l10n/app_localizations.dart';

/// "Advanced" settings tile that streams a firmware image to the panel over the
/// USB-OTG link. The engine already does the risky part (whole-image SHA-256
/// verify, slot switch, auto-rollback of a bad image); this widget only drives
/// the flow from the app: pick a `.bin`, sanity-check it, confirm, then show
/// progress off [PicoViewService.otaEvents] until the device reboots.
class FirmwareUpdateTile extends StatefulWidget {
  const FirmwareUpdateTile({super.key, required this.service});

  final PicoViewService service;

  @override
  State<FirmwareUpdateTile> createState() => _FirmwareUpdateTileState();
}

class _FirmwareUpdateTileState extends State<FirmwareUpdateTile> {
  /// First byte of a valid ESP32 application image (`esp_image_header_t.magic`).
  static const int _espImageMagic = 0xE9;

  bool _busy = false;
  StreamSubscription<PicoLinkState>? _linkSub;

  @override
  void initState() {
    super.initState();
    // The subtitle/enabled state depends on whether a device is open, which can
    // change while Settings is on screen; rebuild on link transitions.
    _linkSub = widget.service.linkStates.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = widget.service.isOpen && !_busy;
    final version = widget.service.firmwareVersion;
    return ListTile(
      leading: const Icon(Icons.system_update_alt),
      title: Text(l10n.settingsFirmwareUpdate),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.service.isOpen
                ? l10n.settingsFirmwareUpdateHint
                : l10n.settingsFirmwareUpdateNotConnected,
          ),
          // Show the running firmware version once the panel reports it.
          if (widget.service.isOpen && version != null)
            Text(
              l10n.firmwareCurrentVersion(version),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      enabled: enabled,
      onTap: enabled ? () => _pickAndFlash(context) : null,
    );
  }

  Future<void> _pickAndFlash(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    const group = XTypeGroup(label: 'firmware', extensions: <String>['bin']);
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null || !context.mounted) return;

    final bytes = await File(file.path).readAsBytes();
    if (!context.mounted) return;

    // Cheap client-side guard against picking the wrong file. The device
    // verifies the image for real, but catching an obviously-wrong file here
    // spares the user a slow failed transfer.
    if (bytes.isEmpty || bytes.first != _espImageMagic) {
      await _showMessage(context, l10n.firmwareInvalidImage);
      return;
    }

    final confirmed = await _confirm(context, l10n);
    if (confirmed != true || !context.mounted) return;

    setState(() => _busy = true);
    try {
      widget.service.otaStart(bytes);
    } on PicoViewException catch (e) {
      if (mounted) setState(() => _busy = false);
      if (context.mounted) {
        await _showMessage(context, l10n.firmwareFailed(e.code ?? -1));
      }
      return;
    }

    if (!context.mounted) return;

    // Block on a progress dialog fed by the OTA event stream; it pops itself
    // with the terminal event (done / failed).
    final result = await showDialog<PicoOtaEvent>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtaProgressDialog(events: widget.service.otaEvents),
    );

    if (mounted) setState(() => _busy = false);

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.state == 'done'
                ? l10n.firmwareDone
                : l10n.firmwareFailed(result.err),
          ),
        ),
      );
    }
  }

  Future<bool?> _confirm(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.firmwareConfirmTitle),
        content: Text(l10n.firmwareConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.firmwareUpdate),
          ),
        ],
      ),
    );
  }

  Future<void> _showMessage(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.settingsDone),
          ),
        ],
      ),
    );
  }
}

/// Modal shown while an image streams to the panel. Subscribes to the engine's
/// OTA event stream and closes (returning the terminal event) once the update
/// finishes or fails, so the caller can report the outcome.
class _OtaProgressDialog extends StatefulWidget {
  const _OtaProgressDialog({required this.events});

  final Stream<PicoOtaEvent> events;

  @override
  State<_OtaProgressDialog> createState() => _OtaProgressDialogState();
}

class _OtaProgressDialogState extends State<_OtaProgressDialog> {
  PicoOtaEvent? _last;
  StreamSubscription<PicoOtaEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.events.listen((event) {
      if (!mounted) return;
      if (event.isTerminal) {
        Navigator.of(context).pop(event);
      } else {
        setState(() => _last = event);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = _last;
    // `verifying` has no meaningful percentage; show an indeterminate bar.
    final determinate = event != null && event.state == 'receiving';
    final label = event?.state == 'verifying'
        ? l10n.firmwareVerifying
        : l10n.firmwareReceiving;
    return AlertDialog(
      title: Text(l10n.settingsFirmwareUpdate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: determinate ? event.pct / 100 : null),
        ],
      ),
    );
  }
}
