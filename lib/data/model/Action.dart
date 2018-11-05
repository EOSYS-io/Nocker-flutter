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
    blockTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(json['block_time'], true);

    Map<String, dynamic> actionTrace = json['action_trace'];
    transactionId = actionTrace['trx_id'];

    Map<String, dynamic> act = actionTrace['act'];
    account = act['account'];
    name = act['name'];
    data = act['data'] is String ? {'data': act['data'].toString()} : act['data'];
  }

  String getBlockTimeString() => DateFormat('yyyyMMdd HH:mm:ss').format(blockTime.toLocal());

  String getDataString() => json.encode(data);
}