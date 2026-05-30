// Stub for non-web platforms: renderButton is never called on these platforms.
import 'package:flutter/widgets.dart';

/// Returns null on non-web platforms; the caller falls back to native UI.
Widget? renderGoogleButton() => null;
