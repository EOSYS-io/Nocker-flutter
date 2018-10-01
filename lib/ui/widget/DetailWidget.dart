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
      EosNode node = list.firstWhere((one) => one.title == this.title);
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
              height: detailHeaderHeight,
              padding: EdgeInsets.only(left: detailLogoMargin, top: detailVerticalMargin, right: defaultMargin, bottom: detailVerticalMargin),
              color: primaryColor,
              child: Row(
                children: <Widget>[
                  CommonWidget.getImageWidget(node.logoUrl),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: detailLogoMargin),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          buildDetailRow(localizations.votes, '${node.votesString} (${node.votesPercentString})'),
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
          fontSize: detailItemTitleSize,
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
    return Container(
      color: backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.only(top: defaultMargin, bottom: itemDefaultMargin),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          if (i == actions.length - 1) {
            detailPresenter.getActions();
          }
          return buildListTile(actions[i]);
        },
      ),
    );
  }

  Widget buildListTile(Action action) {
    return Card(
      margin: EdgeInsets.only(left: defaultMargin, right: defaultMargin, bottom: itemDefaultMargin),
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
                  fontSize: detailItemTitleSize,
                ),
                Expanded(
                  child: CommonWidget.getTextContainer(
                    action.name,
                    margin: EdgeInsets.only(left: 4.0),
                    textAlign: TextAlign.left,
                    fontSize: detailItemTitleSize,
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
              margin: EdgeInsets.only(top: itemDefaultMargin),
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
            buildActionContent('${action.data['from']} -> ${action.data['to']}'),
            buildActionContent(action.data['quantity'], topMargin: true),
            buildActionContent(action.data['memo'], topMargin: true),
          ],
        );
      case 'delegatebw':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildActionContent('${action.data['from']} -> ${action.data['receiver']}'),
            buildActionContent('Stake CPU ${action.data['stake_cpu_quantity']}', topMargin: true),
            buildActionContent('Stake NET ${action.data['stake_net_quantity']}', topMargin: true),
            buildActionContent(action.data['transfer'].toString(), topMargin: true),
          ],
        );
      case 'buyrambytes':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildActionContent('${action.data['payer']} -> ${action.data['receiver']}'),
            buildActionContent('${action.data['bytes'].toString()} Bytes', topMargin: true),
          ],
        );
      case 'claimrewards':
        return buildActionContent(action.data['owner']);
      case 'broadcast':
        return buildActionContent(action.data['message']);
      default:
        return buildActionContent(action.getDataString());
    }
  }

  Widget buildActionContent(String text, {bool topMargin = false}) {
    return CommonWidget.getTextContainer(
      text,
      margin: topMargin ? EdgeInsets.only(top: itemInnerMargin) : EdgeInsets.zero,
      textAlign: TextAlign.left,
    );
  }
}