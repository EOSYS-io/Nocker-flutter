import 'dart:async';

import 'package:eos_node_checker/model/EosNode.dart';
import 'package:eos_node_checker/presenter/MainPresenter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final double detailWidgetPadding = 8.0;

class DetailWidget extends StatefulWidget {
  final String title;

  DetailWidget(this.title);

  @override
  DetailState createState() => DetailState(title);
}

class DetailState extends State<DetailWidget> {
  MainPresenter presenter = MainPresenter();
  final String title;

  StreamSubscription<List<EosNode>> subscription;

  EosNode node;
  int number;

  DetailState(this.title);

  @override
  void initState() {
    super.initState();
    print('initState');
    subscription = presenter.subject.stream.listen((list) {
      EosNode node = list.firstWhere((one) => one.title == this.title );
      if (number != node.number) {
        setState(() {
          this.node = node;
          number = node.number;
        });
      }
    });
  }

  @override
  void dispose() {
    if (subscription != null) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: buildDetail(),
    );
  }

  Widget buildDetail() {
    return Container(
        padding: EdgeInsets.all(detailWidgetPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildRow(title, isBold: true),
            buildRow('Number : ${node != null ? node.number : 'none'}'),
            buildRow('Rank : ${node != null ? node.rank : '0'}'),
            buildRow('Id : ${node != null ? node.id : 'none'}'),
            buildRow('Time : ${node != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(node.time) : 'none'}'),
            buildRow('Producer : ${node != null ? node.producer : 'none'}'),
          ],
        )
    );
  }

  Widget buildRow(String text, {bool isBold = false}) {
    return Container(
      padding: EdgeInsets.only(top: detailWidgetPadding, bottom: detailWidgetPadding),
      child: buildRowText(text, isBold: isBold)
    );
  }

  Widget buildRowText(String text, {bool isBold = false}) {
    return Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(fontSize: 14.0, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)
    );
  }
}