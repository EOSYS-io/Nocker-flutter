import 'package:flutter/material.dart';

class DefaultLocalizations {
  final Locale locale;

  DefaultLocalizations(this.locale);

  static DefaultLocalizations of(BuildContext context) => Localizations.of(context, DefaultLocalizations);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Nocker',
    },
    'ko': {
      'app_title': '노커',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]['app_title'];
}