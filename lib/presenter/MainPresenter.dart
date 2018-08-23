import 'dart:async';
import 'dart:convert';

import 'package:eos_node_checker/db/ProducerProvider.dart';
import 'package:eos_node_checker/model/EosNode.dart';
import 'package:eos_node_checker/service/HttpService.dart';
import 'package:rxdart/rxdart.dart';

class MainPresenter {
  static final MainPresenter _singleton = MainPresenter._internal();
  factory MainPresenter() => _singleton;
  MainPresenter._internal();

  final service = HttpService();
  final db = ProducerProvider();

  final _nodes = <EosNode>[];
  int maxHeight = 0;

  final subject = BehaviorSubject<List<EosNode>>();
  Timer timer;

  void init() {
    db.open();

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
    service.getInfo(node.endpoint)
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
          node.setError();
          subject.add(_nodes);
        });
  }

  void getProducers() {
    service.getProducers()
        .then((response) => response.body)
        .then((body) async {
          Map map = json.decode(body);
          List rows = map['rows'];
          for (int i = 0; i < rows.length; i++) {
            Map map = rows[i];
            final node = EosNode(
                title: map['owner'],
                url: map['url'],
                rank: i + 1
            );
            node.endpoint = await db.getEndpoint(node.title);
            if (node.endpoint == null) {
              getBPInfo(node);
            } else {
              addToList(node);
            }
          }
        }).catchError((error) { print(error); });
  }

  void getBPInfo(EosNode node) {
    service.getBPInfo(node.url)
        .then((response) => response.body)
        .then((body) {
          List nodes = json.decode(body)['nodes'];
          nodes.forEach((n) {
            Map map = n;
            // TODO : eoslaomaocom 연결할 때 FormatException: Unexpected end of input (at character 1) 발생해서 우회
            // eosamsterdam 연결할 때 SSL HandshakeException: Handshake error in client 발생해서 우회
            if (map.containsKey('ssl_endpoint') && map['ssl_endpoint'].toString().isNotEmpty && node.title != 'eosamsterdam') {
              node.endpoint = map['ssl_endpoint'].toString();
              return;
            }
            if (map.containsKey('api_endpoint') && map['api_endpoint'].toString().isNotEmpty) {
              node.endpoint = map['api_endpoint'].toString();
              return;
            }
          });

          if (node.endpoint != null) {
            if (node.endpoint[node.endpoint.length - 1] == '/') {
              node.endpoint = node.endpoint.substring(0, node.endpoint.length - 1);
            }

            db.insert(node);

            addToList(node);
          }
        }).catchError((error) { print(error); });
  }

  void addToList(EosNode node) {
    _nodes.add(node);
    _nodes.sort((a, b) => a.rank.compareTo(b.rank));
    subject.add(_nodes);
  }
}