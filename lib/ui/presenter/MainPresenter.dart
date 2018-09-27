import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:nocker/data/db/ProducerProvider.dart';
import 'package:nocker/data/model/EosNode.dart';
import 'package:nocker/data/remote/HttpService.dart';
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
      default:
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

    await db.open();
    getProducers();
    maxHeight = 0;
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
          if (node.endpointsLength == 1) {
            getBPInfo(node);
          }
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
            )
          );
        })
        .then((rows) {
          nodes.clear();
          nodes.addAll(rows);
          nodes.sort((a, b) => a.rank.compareTo(b.rank));

          nodes.forEach((node) async {
            node.logoUrl = await db.getLogoUrl(node.title);
            node.setEndpoints(await db.getEndpoints(node.title));
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
          Map obj = json.decode(body);
          if (obj['org'] != null && obj['org']['branding'] != null) {
            String logoUrl = obj['org']['branding']['logo_256'];
            if (logoUrl == null || logoUrl.isEmpty) {
              logoUrl = obj['org']['branding']['logo_1024'];
            }
            if (logoUrl == null || logoUrl.isEmpty) {
              logoUrl = obj['org']['branding']['logo_svg'];
            }
            node.logoUrl = logoUrl;
          }

          List nodes = obj['nodes'];
          List<String> endpoints = <String>[];
          nodes.forEach((nodeMap) {
            String endpoint = getEndpoint(nodeMap, 'ssl_endpoint');
            if (endpoint != null) {
              endpoints.add(endpoint);
            }

            endpoint = getEndpoint(nodeMap, 'api_endpoint');
            if (endpoint != null) {
              endpoints.add(endpoint);
            }
          });

          if (endpoints.isNotEmpty) {
            node.setEndpoints(endpoints);
            endpoints.forEach((endpoint) {
              db.insert(node.title, node.url, endpoint, node.logoUrl);
            });

            fetchNode(node);
          }
        }).catchError((error) {
          print(error);
          if (isInit) {
            List<String> splits = node.url.split('://');
            if (splits[0] == 'http') {
              node.url = 'https://${splits[1]}';
            } else {
              node.url = 'http://${splits[1]}';
            }
            getBPInfo(node);
          }
        });
  }

  String getEndpoint(Map map, String key) {
    String endpoint = map[key];
    if (endpoint == null || endpoint.isEmpty) return null;

    if (endpoint[endpoint.length - 1] == '/') {
      endpoint = endpoint.substring(0, endpoint.length - 1);
    }
    return endpoint;
  }
}