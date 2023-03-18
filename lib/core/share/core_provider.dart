import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../application/network_status_notifier.dart';

final networkStatusNotifierProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkState>(
  (ref) => NetworkStatusNotifier(),
);

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => ref.watch(networkStatusNotifierProvider).when(
        connected: () => NetworkStatus.connected,
        none: () => NetworkStatus.none,
      ),
);

enum NetworkStatus {
  connected,
  none,
}
