import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

final int TIMEOUT_INTERVAL = 3;

class HttpService {
  static final HttpService _singleton = HttpService._internal();
  factory HttpService() => _singleton;
  HttpService._internal();

  Future<Response> getInfo(String url) => post("$url/v1/chain/get_info")
      .timeout(Duration(seconds: TIMEOUT_INTERVAL));

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