import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  static Widget getImageWidget(String url, {double width = 24.0, double height = 24.0}) {
    if (url == null || url.isEmpty) {
      return Container(
        width: width,
        height: height,
      );
    } else if (url.substring(url.length - 3) == 'svg') {
      return Container(
        width: width,
        height: height,
        child: SvgPicture.network(
          url,
        ),
      );
    } else {
      return CachedNetworkImage(
        width: width,
        height: height,
        imageUrl: url,
      );
    }
  }
}