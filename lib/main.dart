import 'package:nocker/ui/widget/MainWidget.dart';
import 'package:nocker/util/Constants.dart';
import 'package:nocker/util/locale/DefaultLocalizationsDelegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

final String appTitle = 'Nocker';

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primaryColor: primaryColor,
      ),
      //home: new MyHomePage(title: 'Eos Node Checker'),
      navigatorObservers: <NavigatorObserver>[observer],
      home: MainWidget(analytics),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        DefaultLocalizationsDelegate(),
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('ko', 'KR'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
        final String localeName = Intl.canonicalizedLocale(name);
        Intl.defaultLocale = localeName;

        return locale;
      },
    );
  }
}
