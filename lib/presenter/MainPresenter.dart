import 'dart:async';
import 'dart:convert';

import 'package:eos_node_checker/model/EosNode.dart';
import 'package:eos_node_checker/service/HttpService.dart';
import 'package:rxdart/rxdart.dart';

class MainPresenter {
  static final MainPresenter _singleton = MainPresenter._internal();
  factory MainPresenter() => _singleton;
  MainPresenter._internal();

  final service = HttpService();

  final _nodes = <EosNode>[];
  int maxHeight = 0;

  final subject = BehaviorSubject<List<EosNode>>();
  Timer timer;

  void init() {
    if (_nodes.isEmpty) {
      getProducers();
    } else {
      subject.add(_nodes);
    }

    setTimer();
  }

  List<EosNode> getNodes() => _nodes;

  int getMaxHeight() => maxHeight;

  BehaviorSubject<List<EosNode>> getSubject() => subject;

  void setTimer() {
    timer = Timer.periodic(Duration(seconds: 3), (Timer t) {
      fetchNodes();
    });
  }

  void cancelTimer() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  void fetchNodes() {
    for (EosNode node in _nodes) {
      fetchNode(node);
    }
  }

  void fetchNode(EosNode node) {
    service.getInfo(node.url)
        .then((response) => response.body)
        .then((body) {
          node.fromJson(json.decode(body));

          if (node.number > maxHeight) {
            maxHeight = node.number;
          }
          subject.add(_nodes);
        })
        .catchError((error) {
          print(error.toString());
          print('getInfo error. ${node.title}, ${node.url}');
          node.setError();
          subject.add(_nodes);
        });
  }

  void getProducers() {
    service.getProducers()
        .then((response) => response.body)
        .then((body) {
          Map map = json.decode(body);
          List rows = map['rows'];
          for (int i = 0; i < rows.length; i++) {
            Map map = rows[i];
            final node = EosNode(
                title: map['owner'],
                url: map['url'],
                rank: i + 1
            );
            getBPInfo(node);
          }
        }).catchError((error) { print(error); });
  }

  void getBPInfo(EosNode node) {
    service.getBPInfo(node.url)
        .then((response) => response.body)
        .then((body) {
          node.url = null;    // To make sure there are no endpoints
          List nodes = json.decode(body)['nodes'];
          nodes.forEach((n) {
            Map map = n;
            // TODO : eoslaomaocom 연결할 때 FormatException: Unexpected end of input (at character 1) 발생해서 우회
            // eosamsterdam 연결할 때 SSL HandshakeException: Handshake error in client 발생해서 우회
            // && node.title != 'eoslaomaocom'
            if (map.containsKey('ssl_endpoint') && map['ssl_endpoint'].toString().isNotEmpty && node.title != 'eosamsterdam') {
              node.url = map['ssl_endpoint'].toString();
              return;
            }
            if (map.containsKey('api_endpoint') && map['api_endpoint'].toString().isNotEmpty) {
              node.url = map['api_endpoint'].toString();
              return;
            }
          });

          if (node.url != null) {
            if (node.url[node.url.length - 1] == '/') {
              node.url = node.url.substring(0, node.url.length - 1);
            }
            _nodes.add(node);
            _nodes.sort((a, b) => a.rank.compareTo(b.rank));
            subject.add(_nodes);
          }
        }).catchError((error) { print(error); });
  }
}