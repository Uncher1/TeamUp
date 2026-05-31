// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_strings.dart';

/// Opens [raw] in the matching native app when installed (e.g. the GitHub or
/// LinkedIn app), otherwise falls back to the browser — Instagram-style.
/// Shows a snackbar if the link can't be opened.
Future<void> openExternalLink(BuildContext context, String raw) async {
  final messenger = ScaffoldMessenger.of(context);
  final failMsg = context.tr('common.linkFailed');
  var url = raw.trim();
  if (url.isEmpty) return;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
    return;
  }
  // externalApplication lets Android hand the link to the installed app
  // (GitHub, LinkedIn, X…) via its intent filters, and to the browser otherwise.
  var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  // Some configurations reject externalApplication for plain web links → retry
  // with the platform default so the browser still opens.
  if (!ok) ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failMsg)));
}
