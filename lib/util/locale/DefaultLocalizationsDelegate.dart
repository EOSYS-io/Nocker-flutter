import 'dart:async';

import 'package:nocker/util/locale/DefaultLocalizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DefaultLocalizationsDelegate extends LocalizationsDelegate<DefaultLocalizations> {
  const DefaultLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(LocalizationsDelegate<DefaultLocalizations> old) => false;

  @override
  Future<DefaultLocalizations> load(Locale locale) => SynchronousFuture<DefaultLocalizations>(DefaultLocalizations(locale));
}