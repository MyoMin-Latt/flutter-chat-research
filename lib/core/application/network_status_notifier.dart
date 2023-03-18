import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

part 'network_status_notifier.freezed.dart';

@freezed
class NetworkState with _$NetworkState {
  const factory NetworkState.connected() = _Connected;
  const factory NetworkState.none() = _None;
}

class NetworkStatusNotifier extends StateNotifier<NetworkState> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final Connectivity _connectivity = Connectivity();

  NetworkStatusNotifier() : super(const NetworkState.none()) {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    var isDeviceConnected = false;

    if (result != ConnectivityResult.none) {
      isDeviceConnected = await InternetConnectionChecker().hasConnection;

      if (isDeviceConnected) {
        state = const NetworkState.connected();
      } else {
        state = const NetworkState.none();
      }
    } else {
      state = const NetworkState.none();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }
}
