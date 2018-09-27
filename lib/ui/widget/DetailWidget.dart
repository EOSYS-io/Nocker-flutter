import 'dart:async';

import 'package:nocker/data/model/Action.dart';
import 'package:nocker/data/model/EosNode.dart';
import 'package:nocker/ui/CommonWidget.dart';
import 'package:nocker/ui/presenter/DetailPresenter.dart';
import 'package:nocker/ui/presenter/MainPresenter.dart';
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
    final double padding = detailWidgetPadding * 2;
    final textPadding = EdgeInsets.only(top: detailWidgetPadding, bottom: detailWidgetPadding);
    return Container(
        padding: EdgeInsets.only(left: padding, top: padding, right: padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CommonWidget.getTextContainer(
              'Number : ${node != null ? node.number : ''}',
              padding: textPadding,
            ),
            CommonWidget.getTextContainer(
              'Id : ${node != null ? node.id : ''}',
              padding: textPadding,
              textAlign: TextAlign.start,
            ),
            CommonWidget.getTextContainer(
              'Time : ${node != null && node.time != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(node.time.toLocal()) : ''}',
              padding: textPadding,
            ),
            CommonWidget.getTextContainer(
              'Producer : ${node != null ? node.producer : ''}',
              padding: textPadding,
            ),
            Expanded(child: buildListView()),
          ],
        )
    );
  }

  Widget buildListView() {
    return ListView.builder(
      itemCount: actions.length * 2,
      itemBuilder: (context, i) {
        if (i.isOdd) return CommonWidget.getDivider();

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
              CommonWidget.getTextContainer(
                action.accountSeq.toString(),
                width: 60.0,
              ),
              Expanded(child: CommonWidget.getText(
                action.name,
                textAlign: TextAlign.start,
              )),
              CommonWidget.getTextContainer(
                action.getBlockTimeString(),
                width: 160.0,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(top: detailWidgetPadding / 2),
            child: Row(
              children: <Widget>[
                Expanded(child: CommonWidget.getText(
                  action.getDataFormat(),
                  textAlign: TextAlign.start,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

}