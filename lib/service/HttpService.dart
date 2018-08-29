import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

final int timeoutInterval = 3;

class HttpService {
  Future<Response> getInfo(String url) => post("$url/v1/chain/get_info")
      .timeout(Duration(seconds: timeoutInterval));

  Future<Response> getProducers() => post(
      "https://rpc.eosys.io:443/v1/chain/get_producers",
      body: json.encode({
        "limit": "40",
        "json": "true"
      })
  );

  Future<Response> getBPInfo(String url) => get("$url/bp.json")
      .timeout(Duration(seconds: 10));
}