import 'dart:ui';

// param
final int bpInfoTimeoutInterval = 10;
final int infoTimerDuration = 50;
final int uiTimerDuration = 500;
final int producerCount = 30;
final int timeoutInterval = infoTimerDuration * producerCount;
final int warningOffset = (timeoutInterval ~/ 500) * 2;

// widget
final double defaultMargin = 16.0;
final double itemDefaultMargin = 8.0;
final double headerHeight = 136.0;
final double detailHeaderHeight = 148.0;
final double detailLogoMargin = 40.0;
final double detailVerticalMargin = 20.0;
final double itemVerticalPadding = 20.0;
final double itemHorizontalPadding = 24.0;
final double itemCardElevation = 2.0;
final double itemBorderRadius = 8.0;
final double itemInnerMargin = 4.0;

// text
final double listItemTitleSize = 20.0;
final double detailItemTitleSize = 14.0;

// color
final Color primaryColor = Color.fromARGB(255, 0, 55, 171);
final Color backgroundColor = Color.fromARGB(255, 242, 242, 242);
final Color errorColor = Color.fromARGB(255, 255, 0, 26);
final Color warningColor = Color.fromARGB(255, 255, 242, 0);
final Color grayTextColor = Color.fromARGB(255, 102, 102, 102);