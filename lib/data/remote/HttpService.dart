import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:nocker/util/Constants.dart';

class HttpService {
  Future<Response> getInfo(String url) => post("$url/v1/chain/get_info")
      .timeout(Duration(seconds: timeoutInterval));

  Future<Response> getProducers() => post(
      "https://rpc.eosys.io:443/v1/chain/get_producers",
      body: json.encode({
        "limit": producerCount,
        "json": "true"
      })
  );

  Future<Response> getBPInfo(String url) => get("$url/bp.json")
      .timeout(Duration(seconds: bpInfoTimeoutInterval));

  Future<Response> getActions(String name, {int lastSeq = 0, int count = 100}) {
    return post(
        'https://eos.greymass.com/v1/history/get_actions',
        body: json.encode({
          'account_name': name,
          'pos': lastSeq - 1,
          'offset': (lastSeq == 0 ? -count : 1 - count)
        })
    );
  }
}