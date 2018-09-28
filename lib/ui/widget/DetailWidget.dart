import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nocker/data/model/Action.dart';
import 'package:nocker/data/model/EosNode.dart';
import 'package:nocker/ui/CommonWidget.dart';
import 'package:nocker/ui/presenter/DetailPresenter.dart';
import 'package:nocker/ui/presenter/MainPresenter.dart';
import 'package:nocker/util/Constants.dart';
import 'package:nocker/util/locale/DefaultLocalizations.dart';

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
  DefaultLocalizations localizations;
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
    if (localizations == null) {
      localizations = DefaultLocalizations.of(context);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(title),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 148.0,
              padding: EdgeInsets.only(left: 40.0, top: 20.0, right: 16.0, bottom: 20.0),
              color: primaryColor,
              child: Row(
                children: <Widget>[
                  CommonWidget.getImageWidget(node.logoUrl),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          buildDetailRow(localizations.votes, '${node.votesString}(${node.votesPercentString})'),
                          buildDetailRow(localizations.time, node.timeString),
                          buildDetailRow(localizations.block, node.number > 0 ? node.number.toString() : ''),
                          buildDetailRow(localizations.producer, node.producer != null ? node.producer : ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: buildListView()),
          ],
        ),
      ),
    );
  }

  Widget buildDetailRow(String title, String content) {
    return Row(
      children: <Widget>[
        CommonWidget.getTextContainer(
          title,
          textColor: Colors.white,
          fontSize: 14.0,
          isBold: true
        ),
        Expanded(
          child: CommonWidget.getText(
            content,
            textAlign: TextAlign.right,
            color: Colors.white,
          )
        ),
      ],
    );
  }

  Widget buildListView() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        if (i == actions.length - 1) {
          detailPresenter.getActions();
        }
        return buildListTile(actions[i]);
      },
    );
  }

  Widget buildListTile(Action action) {
    return Card(
      margin: EdgeInsets.only(left: mainWidgetMargin, right: mainWidgetMargin, bottom: mainListItemMargin),
      color: Colors.white,
      elevation: itemCardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(itemBorderRadius))
      ),
      child: Container(
        padding: EdgeInsets.only(left: itemHorizontalPadding, top: itemVerticalPadding, right: itemHorizontalPadding, bottom: itemVerticalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CommonWidget.getTextContainer(
                  action.accountSeq.toString(),
                  width: 36.0,
                  fontSize: 14.0,
                ),
                Expanded(
                  child: CommonWidget.getTextContainer(
                    action.name,
                    margin: EdgeInsets.only(left: 4.0),
                    textAlign: TextAlign.left,
                    fontSize: 14.0,
                    isBold: true,
                  ),
                ),
                CommonWidget.getTextContainer(
                  action.getBlockTimeString(),
                  textColor: grayTextColor,
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 8.0),
              child: buildActionData(action),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionData(Action action) {
    switch (action.name) {
      case 'transfer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CommonWidget.getTextContainer(
              '${action.data['from']} -> ${action.data['to']}',
              textAlign: TextAlign.left,
            ),
            CommonWidget.getTextContainer(
              action.data['quantity'],
              margin: EdgeInsets.only(top: 4.0),
              textAlign: TextAlign.left,
            ),
            CommonWidget.getTextContainer(
              action.data['memo'],
              margin: EdgeInsets.only(top: 4.0),
              textAlign: TextAlign.left,
            ),
          ],
        );
      case 'claimrewards':
        return CommonWidget.getTextContainer(
          action.data['owner'],
          textAlign: TextAlign.left,
        );
      default:
        return CommonWidget.getTextContainer(
            action.getDataString(),
            textAlign: TextAlign.left,
        );
    }
  }

}