import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:nocker/util/Constants.dart';

class RemoteConfigManager {
  static final RemoteConfigManager _singleton = RemoteConfigManager._internal();

  factory RemoteConfigManager() {
    return _singleton;
  }

  RemoteConfigManager._internal();

  RemoteConfig _remoteConfig;
  Future<RemoteConfig> get remoteConfig async {
    if (_remoteConfig == null) {
      _remoteConfig = await RemoteConfig.instance;
      await _remoteConfig.setDefaults(<String, dynamic>{
        rcActionUrlKey: json.encode(<String>[
          'https://eos.greymass.com',
          'http://api.eosnewyork.io',
          'http://mainnet.eoscannon.io'
        ])
      });
    }

    try {
      // Using default duration to force fetching from remote server.
      await _remoteConfig.fetch(expiration: const Duration(hours: 1));
      await _remoteConfig.activateFetched();
    } on FetchThrottledException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {
      print('Unable to fetch remote config. Cached or default values will be used');
    }

    return _remoteConfig;
  }

  List<String> _actionEndpoints = <String>[];
  int _actionsEndpointIndex = -1;

  Future<String> get actionEndpoint async {
    if (_actionEndpoints.isEmpty) {
      await _initRemoteConfig();
    }

    await _setEndpoints();
    return _actionsEndpointIndex >= 0 ? _actionEndpoints[_actionsEndpointIndex] : null;
  }

  Future _initRemoteConfig() async {
    _remoteConfig = await RemoteConfig.instance;

    await _remoteConfig.setDefaults(<String, dynamic>{
      rcActionUrlKey: json.encode(<String>[
        'https://eos.greymass.com',
        'http://api.eosnewyork.io',
        'http://mainnet.eoscannon.io'
      ])
    });
  }

  Future _setEndpoints() async {
    try {
      // Using default duration to force fetching from remote server.
      await _remoteConfig.fetch(expiration: const Duration(hours: 1));
      await _remoteConfig.activateFetched();
    } on FetchThrottledException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {
      print('Unable to fetch remote config. Cached or default values will be used');
    }

    String urls = _remoteConfig.getString(rcActionUrlKey);
    List<String> endpoints = List<String>.from(json.decode(urls));

    _actionEndpoints.clear();
    if (endpoints.isEmpty) {
      _actionsEndpointIndex = -1;
      return;
    }

    _actionEndpoints.addAll(endpoints);
    _actionsEndpointIndex = 0;
  }

  void increaseEndpointIndex() {
    if (_actionEndpoints.isEmpty) {
      _actionsEndpointIndex = -1;
      return;
    }

    if (++_actionsEndpointIndex >= _actionEndpoints.length) {
      _actionsEndpointIndex %= _actionEndpoints.length;
    }
  }
}