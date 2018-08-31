import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:eos_node_checker/data/db/ProducerProvider.dart';
import 'package:eos_node_checker/data/model/EosNode.dart';
import 'package:eos_node_checker/data/remote/HttpService.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class MainPresenter extends WidgetsBindingObserver {
  final service = HttpService();
  final db = ProducerProvider();

  final nodes = <EosNode>[];
  int maxHeight = 0;

  final subject = BehaviorSubject<List<EosNode>>();
  Timer timer;
  Timer refreshTimer;
  bool isInit = false;
  int nodeIndex = 0;

  void init() {
    isInit = true;
    WidgetsBinding.instance.addObserver(this);

    onResume();
  }

  void dispose() {
    isInit = false;
    WidgetsBinding.instance.removeObserver(this);

    onPause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state) {
      case AppLifecycleState.resumed:
        onResume();
        break;
      case AppLifecycleState.paused:
        onPause();
        break;
    }
  }

  void onResume() async {
    cancelTimer();
    
    timer = Timer.periodic(Duration(milliseconds: 50), (t) {
      if (nodes.isEmpty) {
        return;
      }

      if (nodeIndex >= nodes.length) {
        nodeIndex %= nodes.length;
      }
      fetchNode(nodes[nodeIndex++]);
    });

    refreshTimer = Timer.periodic(Duration(milliseconds: 500), (t) {
      subject.add(nodes);
    });

    if (nodes.isEmpty) {
      await db.open();
      getProducers();
    }
  }

  void onPause() async {
    cancelTimer();
    await db.close();
  }

  void cancelTimer() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }

    if (refreshTimer != null) {
      refreshTimer.cancel();
      refreshTimer = null;
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
        })
        .catchError((error) {
          print(error.toString());
          node.setError();
        });
  }

  void getProducers() {
    service.getProducers()
        .then((response) => json.decode(response.body))
        .then((body) {
          double totalVotes = double.parse(body['total_producer_vote_weight']);
          List rows = body['rows'];
          return rows.map((row) => EosNode(
              row['owner'],
              row['url'],
              rows.indexOf(row) + 1,
              double.parse(row['total_votes']),
              totalVotes
          ));
        })
        .then((rows) {
          nodes.clear();
          nodes.addAll(rows);
          nodes.sort((a, b) => a.rank.compareTo(b.rank));

          nodes.forEach((node) async {
            node.endpoint = await db.getEndpoint(node.title);
            if (node.endpoint == null) {
              getBPInfo(node);
            }
          });

          subject.add(nodes);
        })
        .catchError((error) {
          print(error);
          if (isInit) {
            getProducers();
          }
        });
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

            fetchNode(node);
          }
        }).catchError((error) {
          print(error);
          if (isInit) {
            getBPInfo(node);
          }
        });
  }
}