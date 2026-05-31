// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/app_strings.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'pressable.dart';

/// The **web** OAuth client id, used as `serverClientId` so the id_token's
/// audience matches what the backend (`/auth/google`) verifies against.
/// On Android the native client is matched automatically via the app's
/// package name + signing SHA-1 registered in Google Cloud Console.
const _kServerClientId =
    '785441494453-nf5sfmd6osimkub3j4edrdrg6563568k.apps.googleusercontent.com';

/// The official Google "G" logo (Google brand asset — 4 official colours).
const String _googleGSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

bool _gsiInitialized = false;

/// Result of [handleGoogleSignIn] so callers (e.g. the register screen) can
/// react to whether the account was newly created or already existed.
class GoogleOutcome {
  final bool signedIn;
  final bool isNew;
  const GoogleOutcome({required this.signedIn, required this.isNew});

  static const failed = GoogleOutcome(signedIn: false, isNew: false);
}

/// Runs the Google Sign-In flow.
///
/// On **Android/iOS** this opens the native Google account picker
/// (`authenticate()`), retrieves the id_token, and authenticates against the
/// TeamUp backend via `AuthProvider.loginWithGoogle`.
///
/// On **web** the platform does not support `authenticate()` (it requires the
/// GIS `renderButton`, which is incompatible with this Flutter/dart2js build),
/// so we surface a clear message instead.
Future<GoogleOutcome> handleGoogleSignIn(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final auth = context.read<AuthProvider>();
  final signIn = GoogleSignIn.instance;
  // Captured before any await so we don't touch context across async gaps.
  final noTokenMsg = context.tr('common.googleNoToken');
  final failedMsg = context.tr('common.googleFailed');
  final lang = context.read<SettingsProvider>().language;

  if (!signIn.supportsAuthenticate()) {
    messenger.showSnackBar(SnackBar(
      content: Text(context.tr('common.googleMobileOnly')),
    ));
    return GoogleOutcome.failed;
  }

  try {
    if (!_gsiInitialized) {
      await signIn.initialize(serverClientId: _kServerClientId);
      _gsiInitialized = true;
    }
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      messenger.showSnackBar(SnackBar(content: Text(noTokenMsg)));
      return GoogleOutcome.failed;
    }
    final ok = await auth.loginWithGoogle(idToken, language: lang);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(auth.error ?? failedMsg)));
      return GoogleOutcome.failed;
    }
    return GoogleOutcome(signedIn: true, isNew: auth.isNewAccount);
  } on GoogleSignInException catch (e) {
    // User dismissed the picker — not an error worth surfacing.
    if (e.code == GoogleSignInExceptionCode.canceled) return GoogleOutcome.failed;
    messenger.showSnackBar(SnackBar(content: Text('Google : ${e.code.name}')));
    return GoogleOutcome.failed;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(ApiClient.messageFromError(e))),
    );
    return GoogleOutcome.failed;
  }
}

/// Official-style "Continuer avec Google" button: white surface, hairline
/// border, the real Google "G" logo. Tapping runs [handleGoogleSignIn].
class GoogleAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleAuthButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onPressed: onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(_googleGSvg, height: 20, width: 20),
            const SizedBox(width: 10),
            Text(
              context.tr('common.google'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple "ou" separator with hairlines on each side.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.slate200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(context.tr('common.or'), style: TextStyle(fontSize: 12, color: p.textMuted)),
        ),
        Expanded(child: Divider(color: p.slate200)),
      ],
    );
  }
}
