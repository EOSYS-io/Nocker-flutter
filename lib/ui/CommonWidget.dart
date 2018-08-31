import 'package:flutter/material.dart';

class CommonWidget {

  static Widget getTextContainer(
      String text, {
        double width,
        double height,
        EdgeInsets padding = EdgeInsets.zero,
        TextAlign textAlign = TextAlign.center,
        double fontSize = 14.0,
        bool isBold = false
      }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      child: getText(text, textAlign: textAlign, fontSize: fontSize, isBold: isBold),
    );
  }

  static Widget getText(String text, {TextAlign textAlign = TextAlign.center, double fontSize = 14.0, bool isBold = false}) {
    return Text(
        text,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)
    );
  }

  static Widget getDivider({EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      margin: margin,
      height: 1.0,
      color: Colors.grey,
    );
  }
}