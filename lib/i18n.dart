import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:open2fa/main.dart';

final t = I18n.get;

class I18n {
  static final Map<String, String> _i18n = {};
  static final Map<String, String> languages = {};
  static String currentLanguage = 'en';

  static String get(String key, {List<dynamic> args = const []}) {
    if (_i18n.containsKey(key)) {
      String value = _i18n[key]!;
      final matches = RegExp(r't\$\{([^}]+)\}').allMatches(value);
      for (final match in matches) {
        final key = match.group(1);
        if (key != null) {
          value = value.replaceAll(match.group(0)!, get(key));
        }
      }
      for (int i = 0; i < args.length; i++) {
        value = value.replaceAll('\$$i', args[i].toString());
      }
      return value;
    }
    return key;
  }

  static Future loadLanguageManifest() async {
    final manifest = await rootBundle
        .load('i18n/manifest.json')
        .then((data) {
          return json.decode(utf8.decode(data.buffer.asUint8List()));
        })
        .onError((error, stackTrace) {
          logger.w(
            'Failed to load i18n manifest',
            error: error,
            stackTrace: stackTrace,
          );
          return {};
        });
    languages.clear();
    manifest.forEach((key, value) {
      languages[key] = value;
    });
  }

  static Future<void> load(String langCode) async {
    if (languages.isEmpty) {
      await loadLanguageManifest();
    }
    if (!languages.containsKey(langCode)) {
      throw ArgumentError('Language $langCode not found in manifest');
    }
    if (langCode != 'en_gb') {
      // Load english, then load the requested language on top of it, so that any missing keys will default to english
      // We should always re-load english to ensure that we have a clean slate, just in case the user changes their language
      await load('en_gb');
    }
    currentLanguage = langCode;
    final langFile = 'i18n/$langCode.json';
    final i18n = await rootBundle
        .load(langFile)
        .then((data) {
          return json.decode(utf8.decode(data.buffer.asUint8List()));
        })
        .onError((error, stackTrace) {
          logger.w(
            'Failed to load i18n file $langFile',
            error: error,
            stackTrace: stackTrace,
          );
          return {};
        });
    _i18n.clear();
    i18n.forEach((key, value) {
      _i18n[key] = value;
    });
    return Future.value();
  }
}
