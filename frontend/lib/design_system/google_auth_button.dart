import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'pressable.dart';

// Conditional import: on web uses GIS renderButton; elsewhere a no-op stub.
import 'google_sign_in_web_stub.dart'
    if (dart.library.html) 'google_sign_in_web_impl.dart';

const _kClientId =
    '785441494453-nf5sfmd6osimkub3j4edrdrg6563568k.apps.googleusercontent.com';

/// Initialises Google Sign-In (v7 singleton) and starts listening for
/// authentication events.  Call once — typically in the widget that owns
/// the Google button.
///
/// Returns the stream subscription so the caller can cancel it on dispose.
Stream<GoogleSignInAuthenticationEvent> googleSignInEvents() {
  // Initialise GIS with our web client id. (We don't call
  // attemptLightweightAuthentication here — the user clicks the button.)
  GoogleSignIn.instance.initialize(clientId: _kClientId).ignore();
  return GoogleSignIn.instance.authenticationEvents;
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Google Button
// ─────────────────────────────────────────────────────────────────────────────

/// On **web**: renders the official GIS button (real Google logo/branding,
/// via `google_sign_in_web`'s `renderButton()`).
///
/// The authentication result is delivered through
/// [GoogleSignIn.instance.authenticationEvents]; the hosting screen should
/// listen to that stream and call
/// `context.read<AuthProvider>().loginWithGoogle(idToken)`.
class WebGoogleSignInButton extends StatefulWidget {
  const WebGoogleSignInButton({super.key});

  @override
  State<WebGoogleSignInButton> createState() => _WebGoogleSignInButtonState();
}

class _WebGoogleSignInButtonState extends State<WebGoogleSignInButton> {
  late final Stream<GoogleSignInAuthenticationEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = googleSignInEvents();
    _events.listen(_onAuthEvent, onError: _onAuthError);
  }

  Future<void> _onAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (!mounted) return;
    if (event is GoogleSignInAuthenticationEventSignIn) {
      // authentication is not a Future in v7 — access it synchronously.
      final auth = event.user.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Google Sign-In: impossible de récupérer le token.')),
          );
        }
        return;
      }
      // Hoist both provider read and context use before the async gap.
      final authProvider = context.read<AuthProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final ok = await authProvider.loginWithGoogle(idToken);
      if (!mounted) return;
      if (!ok) {
        final err = authProvider.error ?? 'Échec de la connexion Google';
        messenger.showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  void _onAuthError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiClient.messageFromError(error))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // renderGoogleButton() is provided by the conditional import:
    //   web → google_sign_in_web_impl.dart (calls gsi_web.renderButton())
    //   other → google_sign_in_web_stub.dart (returns null)
    final gisButton = renderGoogleButton();
    if (gisButton != null) {
      // The GIS button is an HtmlElementView; bound its height so it doesn't
      // expand to fill the column (which showed a large grey placeholder).
      return SizedBox(height: 44, child: Center(child: gisButton));
    }
    // Fallback if somehow called on non-web.
    return GoogleAuthButton(onPressed: () {});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Non-web / fallback Google Button (unchanged from original design)
// ─────────────────────────────────────────────────────────────────────────────

/// "Continuer avec Google" button (Google-styled white/outlined).
///
/// On **web** the screens should use [WebGoogleSignInButton] instead so
/// Google's SDK renders its official branded button.
///
/// On non-web platforms this widget is used as-is (native flows TBD).
class GoogleAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleAuthButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelStyle = TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary);

    // Official "G" logo if present, else a neutral fallback mark.
    final logo = Image.asset(
      'assets/google_logo.png',
      height: 20,
      width: 20,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
    );

    // Official "Google" wordmark if present, else plain text.
    final wordmark = Image.asset(
      'assets/google_wordmark.png',
      height: 16,
      errorBuilder: (_, _, _) => Text('Google', style: labelStyle),
    );

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
            logo,
            const SizedBox(width: 8),
            Text('Continuer avec ', style: labelStyle),
            wordmark,
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
          child: Text('ou', style: TextStyle(fontSize: 12, color: p.textMuted)),
        ),
        Expanded(child: Divider(color: p.slate200)),
      ],
    );
  }
}
