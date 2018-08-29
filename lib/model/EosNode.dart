import 'package:intl/intl.dart';

class EosNode {
  EosNode({this.title, this.url, this.rank});

  final String title;
  String url;
  final int rank;
  String endpoint;
  String version;
  int number = 0;
  int lastNumber = 0;
  String id;
  DateTime time;
  String producer;

  void fromJson(Map<String, dynamic> json) {
    version = json['server_version'];
    number = json['head_block_num'];
    lastNumber = json['last_irreversible_block_num'];
    id = json['head_block_id'];
    time = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(json['head_block_time']);
    producer = json['head_block_producer'];
  }

  void setError() {
    version = null;
    number = 0;
    lastNumber = 0;
    id = null;
    time = null;
    producer = null;
  }
}