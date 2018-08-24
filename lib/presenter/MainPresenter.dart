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

  final nodes = <EosNode>[];
  int maxHeight = 0;

  final subject = BehaviorSubject<List<EosNode>>();
  Timer timer;
  int nodeIndex = 0;

  void init() {
    db.open();

    if (nodes.isEmpty) {
      getProducers();
    } else {
      subject.add(nodes);
    }

    setTimer();
  }

  void setTimer() {
    timer = Timer.periodic(Duration(milliseconds: 50), (Timer t) {
      if (nodes.isEmpty) {
        return;
      }

      if (nodeIndex >= nodes.length) {
        nodeIndex %= nodes.length;
      }
      fetchNode(nodes[nodeIndex++]);
    });
  }

  void cancelTimer() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  void fetchNode(EosNode node) {
    String endpoint = node.endpoint;
    if (endpoint == null || endpoint.isEmpty) {
      return;
    }

    service.getInfo(endpoint)
        .then((response) => response.body)
        .then((body) {
          node.fromJson(json.decode(body));

          if (node.number > maxHeight) {
            maxHeight = node.number;
          }
          subject.add(nodes);
        })
        .catchError((error) {
          print(error.toString());
          node.setError();
          subject.add(nodes);
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
            }

            nodes.add(node);
          }

          nodes.sort((a, b) => a.rank.compareTo(b.rank));
          subject.add(nodes);
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

            subject.add(nodes);
          }
        }).catchError((error) {
          print(error);
          node.setError();
          subject.add(nodes);
        });
  }
}