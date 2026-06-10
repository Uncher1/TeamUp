// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/services.dart';

/// Forces a text field to the `XXXX-XXXX` shape: uppercase letters + digits,
/// a dash auto-inserted after the 4th character, max 8 alphanumerics.
/// Shared by the sign-up verification screen and the e-mail/password
/// change-confirmation screens.
class CodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    var raw = next.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (raw.length > 8) raw = raw.substring(0, 8);
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i == 4) buf.write('-');
      buf.write(raw[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
