import 'dart:async';

import 'package:flutter/foundation.dart';

/// Drives [GoRouter.refreshListenable] so [redirect] re-runs when auth state changes
/// (e.g. after sign-out). Without this, the UI can stay on a protected route on Android.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
