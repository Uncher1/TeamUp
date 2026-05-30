// Web implementation: delegates to google_sign_in_web's official GIS button.
import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Returns the official GIS-rendered Google Sign-In button widget.
Widget? renderGoogleButton() => gsi_web.renderButton();
