import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity/connectivity_service.dart';

/// Simple wrapper used by Repository implementations to check connectivity
/// before attempting remote calls.
class NetworkInfo {
  final ConnectivityService _service;
  NetworkInfo(this._service);

  bool get isConnected => _service.isConnected;
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(ref.watch(connectivityServiceProvider));
});
