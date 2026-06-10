// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// On-device (offline, free) translation of post content between the app's
/// supported languages (English / French) via Google ML Kit. Models download
/// once on first use.
class PostTranslator {
  static TranslateLanguage? _lang(String code) {
    switch (code) {
      case 'en':
        return TranslateLanguage.english;
      case 'fr':
        return TranslateLanguage.french;
      default:
        return null;
    }
  }

  /// Detects the language of [text] on-device; returns 'en'/'fr' when one of the
  /// supported languages is identified with confidence, otherwise null.
  static Future<String?> detectLanguage(String text) async {
    if (text.trim().length < 3) return null;
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    try {
      final code = await identifier.identifyLanguage(text);
      return (code == 'en' || code == 'fr') ? code : null;
    } catch (_) {
      return null;
    } finally {
      await identifier.close();
    }
  }

  /// True if we can offer a translation from [sourceCode] to [targetCode].
  static bool canTranslate(String sourceCode, String targetCode) {
    final s = _lang(sourceCode);
    final t = _lang(targetCode);
    return s != null && t != null && s != t;
  }

  /// Translates [text] from [sourceCode] to [targetCode] ('en'/'fr').
  /// Returns null if unsupported or on failure (caller keeps the original).
  static Future<String?> translate(String text, String sourceCode, String targetCode) async {
    final src = _lang(sourceCode);
    final tgt = _lang(targetCode);
    if (src == null || tgt == null || src == tgt) return null;
    final manager = OnDeviceTranslatorModelManager();
    OnDeviceTranslator? translator;
    try {
      if (!await manager.isModelDownloaded(src.bcpCode)) {
        await manager.downloadModel(src.bcpCode, isWifiRequired: false);
      }
      if (!await manager.isModelDownloaded(tgt.bcpCode)) {
        await manager.downloadModel(tgt.bcpCode, isWifiRequired: false);
      }
      translator = OnDeviceTranslator(sourceLanguage: src, targetLanguage: tgt);
      return await translator.translateText(text);
    } catch (_) {
      return null;
    } finally {
      await translator?.close();
    }
  }
}
