import 'dart:math';

import 'package:intl/intl.dart';

class EosNode {
  final String title;
  String url;
  final int rank;
  final double _votes;
  double _votesWithoutWeight;
  double _votePercents;
  String logoUrl;
  String version;
  int number = 0;
  int lastNumber = 0;
  String id;
  DateTime time;
  String producer;

  bool _isError = false;

  List<String> _endpoints = <String>[];
  int _endpointIndex = -1;

  String get votesString {
    double votes = _votesWithoutWeight;

    List<String> unitText = ['', 'K', 'M'];
    double unit = 1000.0;
    int i;
    for (i = 0; i < unitText.length; i++) {
      if (votes < unit * unit) {
        break;
      }
      votes /= unit;
    }
    if (i == unitText.length) {
      i--;
    }
    return '${NumberFormat.decimalPattern().format(votes.toInt())}${unitText[i]}';
  }

  String get votesPercentString => '${_votePercents.toStringAsFixed(3)}%';

  String get endpoint => _endpointIndex >= 0 ? _endpoints[_endpointIndex] : null;
  int get endpointsLength => _endpoints.length;

  String get timeString => time != null ? DateFormat('yyyyMMdd HH:mm:ss').format(time.toLocal()) : '';

  EosNode(this.title, this.url, this.rank, this._votes, double totalVotes) {
    _votesWithoutWeight = _votes / _calculateVoteWeight() / 10000;
    _votePercents = (totalVotes > 0 ? _votes / totalVotes * 100 : 0.0);
  }

  void fromJson(Map<String, dynamic> json) {
    version = json['server_version'];
    number = json['head_block_num'];
    lastNumber = json['last_irreversible_block_num'];
    id = json['head_block_id'];
    time = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(json['head_block_time'], true);
    producer = json['head_block_producer'];

    _isError = false;
  }

  bool isError() => _isError;

  void setError() {
    version = null;
    number = 0;
    lastNumber = 0;
    id = null;
    time = null;
    producer = null;

    _isError = true;

    increaseEndpointIndex();
  }

  void setEndpoints(List<String> endpoints) {
    if (endpoints == null || endpoints.isEmpty) {
      return;
    }

    _endpoints.clear();
    _endpoints.addAll(endpoints);
    _endpointIndex = 0;
  }

  void increaseEndpointIndex() {
    if (_endpoints.isEmpty) {
      _endpointIndex = -1;
      return;
    }

    if (++_endpointIndex >= _endpoints.length) {
      _endpointIndex %= _endpoints.length;
    }
  }

  double _calculateVoteWeight() {
    int e = 946684800000;
    double t = DateTime.now().millisecondsSinceEpoch / 1000 - e / 1000;
    double n = (t ~/ 604800) / 52;
    return pow(2.0, n);
  }
}