import 'dart:convert';
import 'dart:math';

import 'package:nocker/data/model/Action.dart';
import 'package:nocker/data/remote/HttpService.dart';
import 'package:nocker/util/RemoteConfigManager.dart';
import 'package:rxdart/rxdart.dart';

class DetailPresenter {
  final String title;

  final rcManager = RemoteConfigManager();
  final service = HttpService();
  final actions = Map<int, Action>();

  final subject = BehaviorSubject<List<Action>>();

  DetailPresenter(this.title);

  void getActions() async {
    String url = await rcManager.actionEndpoint;

    int seq = actions.isNotEmpty ? actions.keys.reduce(min) : 0;
    service.getActions(url, title, lastSeq: seq)
        .then((response) => json.decode(utf8.decode(response.bodyBytes)))
        .then((body) => (body['actions'] as List).map((act) => Action(act)))
        .then((list) {
          list.forEach((act) {
            actions[act.accountSeq] = act;
          });

          subject.add(
              actions.values.toList()
                ..sort((a, b) => b.accountSeq.compareTo(a.accountSeq))
          );
        })
        .catchError((error) {
          print('getActions error: ${error.runtimeType}. $error');

          if (actions.isEmpty) {
            rcManager.increaseEndpointIndex();
          }
          getActions();
        });
  }
}