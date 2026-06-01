// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_strings.dart';

/// Lightweight over-the-air update check for the sideloaded APK.
///
/// On Android, looks at the latest GitHub Release; if its version is newer than
/// the installed one, prompts the user to download the new APK (opened in the
/// browser, which then installs it over the current app — no uninstall needed).
/// Any failure is swallowed: this must never block or crash the app.

const String _repo = 'Uncher1/TeamUp';

class _Release {
  final String version; // e.g. "1.1.0"
  final String? apkUrl; // arm64 APK asset, when present
  final String pageUrl; // release page fallback
  const _Release(this.version, this.apkUrl, this.pageUrl);
}

/// True once we've run the check this app session (avoids double prompts when
/// both the login screen and the home shell trigger it).
bool _promptedThisSession = false;

/// Checks once and, if a newer release exists, shows the update dialog.
Future<void> maybePromptForUpdate(BuildContext context) async {
  // Only meaningful for the installed Android app.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  if (_promptedThisSession) return;
  _promptedThisSession = true;
  try {
    final latest = await _fetchLatest();
    if (latest == null) return;
    final info = await PackageInfo.fromPlatform();
    if (!_isNewer(latest.version, info.version)) return;
    if (!context.mounted) return;
    await _showUpdateDialog(context, latest);
  } catch (_) {
    // Network/parse error: ignore silently.
  }
}

Future<_Release?> _fetchLatest() async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));
  final res = await dio.get(
    'https://api.github.com/repos/$_repo/releases/latest',
    options: Options(headers: {'Accept': 'application/vnd.github+json'}),
  );
  final data = res.data;
  if (data is! Map) return null;
  final tag = (data['tag_name'] as String?)?.trim();
  if (tag == null || tag.isEmpty) return null;
  final version = tag.startsWith('v') ? tag.substring(1) : tag;

  String? apkUrl;
  final assets = data['assets'];
  if (assets is List) {
    for (final a in assets) {
      if (a is Map &&
          (a['name'] as String? ?? '').contains('arm64-v8a')) {
        apkUrl = a['browser_download_url'] as String?;
        break;
      }
    }
  }
  final pageUrl = (data['html_url'] as String?) ??
      'https://github.com/$_repo/releases/latest';
  return _Release(version, apkUrl, pageUrl);
}

/// True when [remote] is a strictly higher version than [current].
bool _isNewer(String remote, String current) {
  List<int> parse(String v) =>
      v.split(RegExp(r'[.+]')).map((e) => int.tryParse(e) ?? 0).toList();
  final r = parse(remote);
  final c = parse(current);
  final n = r.length > c.length ? r.length : c.length;
  for (var i = 0; i < n; i++) {
    final rv = i < r.length ? r[i] : 0;
    final cv = i < c.length ? c[i] : 0;
    if (rv != cv) return rv > cv;
  }
  return false;
}

Future<void> _showUpdateDialog(BuildContext context, _Release latest) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('update.title')),
      content: Text(ctx.tr('update.body', {'version': latest.version})),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.tr('update.later')),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            _runOtaUpdate(context, latest);
          },
          child: Text(ctx.tr('update.cta')),
        ),
      ],
    ),
  );
}

/// Opens [url] in the browser (the manual download fallback).
Future<void> _openBrowser(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {/* ignore */}
}

/// Downloads the APK in-app and triggers the system installer (no manual file
/// handling). Falls back to the browser if no APK asset or on failure.
Future<void> _runOtaUpdate(BuildContext context, _Release latest) async {
  final apk = latest.apkUrl;
  if (apk == null) {
    await _openBrowser(latest.pageUrl);
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _OtaProgressDialog(apkUrl: apk, fallbackUrl: latest.pageUrl),
  );
}

/// Non-dismissible dialog that streams download progress and hands off to the
/// Android package installer. Self-closes on install or error.
class _OtaProgressDialog extends StatefulWidget {
  final String apkUrl;
  final String fallbackUrl;
  const _OtaProgressDialog({required this.apkUrl, required this.fallbackUrl});

  @override
  State<_OtaProgressDialog> createState() => _OtaProgressDialogState();
}

class _OtaProgressDialogState extends State<_OtaProgressDialog> {
  int _percent = 0;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    try {
      OtaUpdate()
          .execute(widget.apkUrl, destinationFilename: 'teamup-update.apk')
          .listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final pct = int.tryParse(event.value ?? '') ?? _percent;
              if (mounted) setState(() => _percent = pct);
              break;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              if (mounted) setState(() => _installing = true);
              _close();
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _fail(permission: true);
              break;
            default:
              _fail();
          }
        },
        onError: (_) => _fail(),
      );
    } catch (_) {
      _fail();
    }
  }

  void _close() {
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  /// On any failure, close, tell the user, and fall back to the browser.
  void _fail({bool permission = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.tr(permission ? 'update.permission' : 'update.failed');
    _close();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
    _openBrowser(widget.fallbackUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: (!_installing && _percent > 0) ? _percent / 100 : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(_installing
                ? context.tr('update.installing')
                : context.tr('update.downloading', {'percent': '$_percent'})),
          ),
        ],
      ),
    );
  }
}
