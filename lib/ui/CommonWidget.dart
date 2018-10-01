import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonWidget {

  static Widget getTextContainer(
      String text, {
        double width,
        double height,
        EdgeInsets margin = EdgeInsets.zero,
        EdgeInsets padding = EdgeInsets.zero,
        TextAlign textAlign = TextAlign.center,
        double fontSize = 12.0,
        Color textColor = Colors.black,
        bool isBold = false
      }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      child: getText(text, textAlign: textAlign, fontSize: fontSize, color: textColor, isBold: isBold),
    );
  }

  static Widget getText(String text, {TextAlign textAlign = TextAlign.center, double fontSize = 12.0, Color color = Colors.black, bool isBold = false}) {
    return Text(
        text,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)
    );
  }

  static Widget getDivider({EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      margin: margin,
      height: 1.0,
      color: Colors.grey,
    );
  }

  static Widget getImageWidget(String url, {double size = 68.0}) {
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
      );
    } else if (url.substring(url.length - 3) == 'svg') {
      return Container(
        width: size,
        height: size,
        child: SvgPicture.network(
          url,
        ),
      );
    } else {
      return CachedNetworkImage(
        width: size,
        height: size,
        imageUrl: url,
        fadeInDuration: Duration.zero,
      );
    }
  }
}