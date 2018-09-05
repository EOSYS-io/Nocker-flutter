import 'package:intl/intl.dart';

class EosNode {
  final String title;
  String url;
  final int rank;
  final double votes;
  double votePercents;
  String version;
  int number = 0;
  int lastNumber = 0;
  String id;
  DateTime time;
  String producer;

  List<String> _endpoints = <String>[];
  int _endpointIndex = -1;

  String get endpoint => _endpointIndex >= 0 ? _endpoints[_endpointIndex] : null;
  int get endpointsLength => _endpoints.length;

  EosNode(this.title, this.url, this.rank, this.votes, double totalVotes) {
    votePercents = (totalVotes > 0 ? votes / totalVotes * 100 : 0.0);
  }

  void fromJson(Map<String, dynamic> json) {
    version = json['server_version'];
    number = json['head_block_num'];
    lastNumber = json['last_irreversible_block_num'];
    id = json['head_block_id'];
    time = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(json['head_block_time'], true);
    producer = json['head_block_producer'];
  }

  void setError() {
    version = null;
    number = 0;
    lastNumber = 0;
    id = null;
    time = null;
    producer = null;

    increaseEndpointIndex();
  }

  void setEndpoints(List<String> endpoints) {
    if (endpoints == null || endpoints.isEmpty) return;

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
}