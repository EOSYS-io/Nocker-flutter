import 'package:flutter/material.dart';

class DefaultLocalizations {
  final Locale locale;

  DefaultLocalizations(this.locale);

  static DefaultLocalizations of(BuildContext context) => Localizations.of(context, DefaultLocalizations);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Nocker',
      'time': 'Time',
      'block': 'Block',
    },
    'ko': {
      'app_title': '노커',
      'time': '시간',
      'block': '블록',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]['app_title'];
  String get time => _localizedValues[locale.languageCode]['time'];
  String get block => _localizedValues[locale.languageCode]['block'];
}