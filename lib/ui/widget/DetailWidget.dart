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

    node = mainPresenter.nodes.firstWhere((one) => one.title == this.title);
    number = node.number;
  }

  @override
  void initState() {
    super.initState();
    subscription = mainPresenter.subject.stream.listen((list) {
      if (!mounted) {
        return;
      }

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
    subscription?.cancel();
    actSub?.cancel();
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
                Container(
                  constraints: BoxConstraints(
                    minWidth: 36.0,
                  ),
                  child: CommonWidget.getText(
                    action.accountSeq.toString(),
                    fontSize: detailItemTitleSize,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 4.0),
                    child: Text(
                      action.name,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: detailItemTitleSize, fontWeight: FontWeight.bold),
                      textScaleFactor: 1.0,
                    ),
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
            buildActionContent('${action.data['from']} -> ${action.data['to']}', topMargin: false),
            buildActionContent(action.data['quantity']),
            buildActionContent(action.data['memo']),
          ],
        );
      case 'delegatebw':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildActionContent('${action.data['from']} -> ${action.data['receiver']}', topMargin: false),
            buildActionContent('Stake CPU ${action.data['stake_cpu_quantity']}'),
            buildActionContent('Stake NET ${action.data['stake_net_quantity']}'),
            buildActionContent(action.data['transfer'].toString()),
          ],
        );
      case 'buyrambytes':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildActionContent('${action.data['payer']} -> ${action.data['receiver']}', topMargin: false),
            buildActionContent('${action.data['bytes'].toString()} Bytes'),
          ],
        );
      case 'claimrewards':
        return buildActionContent(action.data['owner'], topMargin: false);
      case 'broadcast':
        return buildActionContent(action.data['message'], topMargin: false);
      default:
        return buildActionContent(action.getDataString(), topMargin: false);
    }
  }

  Widget buildActionContent(String text, {bool topMargin = true}) {
    return Container(
      margin: topMargin ? EdgeInsets.only(top: itemInnerMargin) : EdgeInsets.zero,
      child: Text(
        text,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 15,
        style: TextStyle(fontSize: 12.0),
        textScaleFactor: 1.0,
      ),
    );
  }
}