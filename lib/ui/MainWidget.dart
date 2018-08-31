import 'package:eos_node_checker/model/EosNode.dart';
import 'package:eos_node_checker/presenter/MainPresenter.dart';
import 'package:eos_node_checker/ui/DetailWidget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final double mainWidgetPadding = 8.0;

class MainWidget extends StatefulWidget {
  @override
  MainState createState() => MainState();
}

class MainState extends State<MainWidget> {
  MainPresenter presenter = MainPresenter();
  List<EosNode> nodes = <EosNode>[];

  @override
  void initState() {
    super.initState();
    presenter.init();
    presenter.subject.stream.listen((list) {
      setState(() {
        nodes = list;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    presenter.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('EOS Node Monitor'),
      ),
      body: buildNodes(),
    );
  }

  Widget buildNodes() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: mainWidgetPadding, bottom: mainWidgetPadding),
          child: buildListRow('R', 'Title', 'Number', 'Time', isBold: true),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: nodes.length,
                itemBuilder: (context, i) => buildListTile(nodes[i]),
            )
        )
      ],
    );
  }

  Widget buildListTile(EosNode node) {
    String time = 'none';
    if (node != null && node.time != null) {
      time = DateFormat('yyMMdd\nHH:mm:ss').format(node.time);
    }

    Color color;
    if (node.id == null) {
      color = Color.fromARGB(128, 255, 0, 0);
    } else if (node.number < presenter.maxHeight - 10) {
      color = Color.fromARGB(128, 255, 255, 0);
    } else {
      color = Colors.white;
    }

    return GestureDetector(
      onTap: () { onItemClicked(node); },
      child: buildListRow(node.rank, '${node.title}\n${node.votePercents.toStringAsFixed(3)}%', node.number, time, color: color),
    );
  }

  Widget buildListRow(final rank, final title, final number, final time, {Color color = Colors.white, bool isBold = false}) {
    return Container(
      color: color,
      padding: EdgeInsets.only(top: mainWidgetPadding, bottom: mainWidgetPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 30.0,
            child: buildRowText('$rank', isBold: isBold),
          ),
          Expanded(child: buildRowText(title, isBold: isBold)),
          Container(
            width: 110.0,
            child: buildRowText('$number', isBold: isBold),
          ),
          Container(
            width: 100.0,
            child: buildRowText(time, isBold: isBold),
          ),
        ],
      ),
    );
  }

  Widget buildRowText(String text, {bool isBold = false}) {
    return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14.0, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)
    );
  }

  void onItemClicked(EosNode node) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailWidget(presenter, node.title),
      )
    );
  }
}