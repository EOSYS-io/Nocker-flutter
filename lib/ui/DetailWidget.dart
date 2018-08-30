import 'dart:async';

import 'package:eos_node_checker/model/Action.dart';
import 'package:eos_node_checker/model/EosNode.dart';
import 'package:eos_node_checker/presenter/DetailPresenter.dart';
import 'package:eos_node_checker/presenter/MainPresenter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final double detailWidgetPadding = 8.0;

class DetailWidget extends StatefulWidget {
  final MainPresenter presenter;
  final String title;

  DetailWidget(this.presenter, this.title);

  @override
  DetailState createState() => DetailState(presenter, title);
}

class DetailState extends State<DetailWidget> {
  final MainPresenter mainPresenter;
  final String title;

  DetailPresenter detailPresenter;
  StreamSubscription<List<EosNode>> subscription;
  StreamSubscription<List<Action>> actSub;

  EosNode node;
  int number;
  List<Action> actions = <Action>[];

  DetailState(this.mainPresenter, this.title) {
    detailPresenter = DetailPresenter(title);
  }

  @override
  void initState() {
    super.initState();
    subscription = mainPresenter.subject.stream.listen((list) {
      EosNode node = list.firstWhere((one) => one.title == this.title );
      if (number != node.number) {
        setState(() {
          this.node = node;
          number = node.number;
        });
      }
    });

    actSub = detailPresenter.subject.stream.listen((list) {
      setState(() {
        actions.clear();
        actions.addAll(list);
      });
    });
    detailPresenter.getActions();
  }

  @override
  void dispose() {
    if (subscription != null) {
      subscription.cancel();
    }
    if (actSub != null) {
      actSub.cancel();
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
    double padding = detailWidgetPadding * 2;
    return Container(
        padding: EdgeInsets.only(left: padding, top: padding, right: padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildRow('Number : ${node != null ? node.number : 'none'}'),
            buildRow('Id : ${node != null ? node.id : 'none'}'),
            buildRow('Time : ${node != null && node.time != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(node.time) : 'none'}'),
            buildRow('Producer : ${node != null ? node.producer : 'none'}'),
            Expanded(child: buildListView()),
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

  Widget buildListView() {
    return ListView.builder(
      itemCount: actions.length * 2,
      itemBuilder: (context, i) {
        if (i.isOdd) return buildDivider();

        int index = i ~/ 2;
        if (index == actions.length - 1) {
          detailPresenter.getActions();
        }
        return buildListTile(actions[index]);
      },
    );
  }

  Widget buildListTile(Action action) {
    return Container(
      padding: EdgeInsets.only(top: detailWidgetPadding, bottom: detailWidgetPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 50.0,
                child: buildRowText(action.accountSeq.toString()),
              ),
              Container(
                width: 180.0,
                child: buildRowText(action.getBlockTimeString()),
              ),
              Expanded(child: buildRowText(action.name)),
            ],
          ),
          Container(
            padding: EdgeInsets.only(top: detailWidgetPadding / 2),
            child: Row(
              children: <Widget>[
                Expanded(child: buildRowText(action.getDataFormat())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return Container(
      height: 1.0,
      color: Colors.grey,
    );
  }

}