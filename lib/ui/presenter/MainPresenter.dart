import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:nocker/data/model/EosNode.dart';
import 'package:nocker/data/remote/HttpService.dart';
import 'package:nocker/util/Constants.dart';
import 'package:rxdart/rxdart.dart';

class MainPresenter extends WidgetsBindingObserver {
  final FirebaseAnalytics analytics;

  final service = HttpService();

  final nodes = <EosNode>[];
  int maxHeight = 0;

  final subject = BehaviorSubject<List<EosNode>>();
  Timer timer;
  Timer refreshTimer;
  bool isResumed = false;
  int nodeIndex = 0;

  MainPresenter(this.analytics);

  void init() {
    WidgetsBinding.instance.addObserver(this);
    onResume();
  }

  void dispose() {
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

  void onResume() {
    isResumed = true;
    cancelTimer();
    
    timer = Timer.periodic(Duration(milliseconds: infoTimerDuration), (t) {
      if (nodes.isEmpty) {
        return;
      }

      if (nodeIndex >= nodes.length) {
        nodeIndex %= nodes.length;
      }
      fetchNode(nodes[nodeIndex++]);
    });

    refreshTimer = Timer.periodic(Duration(milliseconds: uiTimerDuration), (t) {
      subject.add(nodes);
    });

    getProducers();
    maxHeight = 0;
  }

  void onPause() {
    isResumed = false;
    cancelTimer();
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
        .then((response) => json.decode(response.body))
        .then((body) {
          node.fromJson(body);

          if (node.number > maxHeight) {
            maxHeight = node.number;
          }

          if (0 < node.number && node.number < maxHeight - warningOffset) {
            _logWarningEvent(node.title, maxHeight - node.number);
          }
        })
        .catchError((error) {
          print('${node.title}. ${node.endpoint}');
          print(error);
          _logExceptionEvent(node.title, node.endpoint, error.runtimeType.toString());

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
            )
          );
        })
        .then((rows) {
          nodes.clear();
          nodes.addAll(rows);
          nodes.sort((a, b) => a.rank.compareTo(b.rank));

          nodes.forEach((node) {
            getBPInfo(node);
          });

          subject.add(nodes);
        })
        .catchError((error) {
          print(error);
          if (isResumed) {
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
            fetchNode(node);
          } else {
            node.setError();
          }
        }).catchError((error) {
          print('${node.title}. $error');
          if (isResumed) {
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

  Future _logExceptionEvent(String name, String endpoint, String exception) async {
    return await analytics.logEvent(
      name: 'exception',
      parameters: {
        'bp_name': name,
        'endpoint': endpoint,
        'exception': exception,
      }
    );
  }

  Future _logWarningEvent(String name, int differ) async {
    return await analytics.logEvent(
        name: 'warning',
        parameters: {
          'bp_name': name,
          'difference': differ,
        }
    );
  }
}