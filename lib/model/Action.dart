import 'dart:convert';

import 'package:intl/intl.dart';

class Action {
  int accountSeq;
  int blockNumber;
  DateTime blockTime;
  String transactionId;
  String account;
  String name;
  Map<String, dynamic> data;

  Action(Map<String, dynamic> json) {
    accountSeq = json['account_action_seq'];
    blockNumber = json['block_num'];
    blockTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(json['block_time']);

    Map<String, dynamic> actionTrace = json['action_trace'];
    transactionId = actionTrace['trx_id'];

    Map<String, dynamic> act = actionTrace['act'];
    account = act['account'];
    name = act['name'];
    data = act['data'];
  }

  String getBlockTimeString() => DateFormat('yyyy-MM-dd HH:mm:ss').format(blockTime.toLocal());

  String getDataString() => json.encode(data);

  String getDataFormat() {
    switch (name) {
      case 'transfer':      return '${data['from']} -> ${data['to']}\n${data['quantity']}\n${data['memo']}';
      case 'claimrewards':  return data['owner'];
      default:              return json.encode(data);
    }
  }
}