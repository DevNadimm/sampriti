import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

mixin NetworkMonitorMixin<T extends StatefulWidget> on State<T> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pingTimer;

  bool isOnline = true;

  /// Ping interval (change if needed)
  Duration pingInterval = const Duration(seconds: 5);

  /// Override in your screen
  void onNetworkLost() {}

  void onNetworkRestored() {}

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(result);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final hasNetwork = !results.contains(ConnectivityResult.none) && results.isNotEmpty;

    if (!hasNetwork) {
      _updateStatus(false);
      _stopPing();
      return;
    }

    /// Network available → verify internet
    await _verifyInternet();

    /// Start periodic ping
    _startPing();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      _verifyInternet();
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
  }

  Future<void> _verifyInternet() async {
    final wasOnline = isOnline;

    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));

      isOnline = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      isOnline = false;
    }

    if (wasOnline != isOnline) {
      if (isOnline) {
        onNetworkRestored();
      } else {
        onNetworkLost();
      }
    }

    if (mounted) setState(() {});
  }

  void _updateStatus(bool status) {
    final wasOnline = isOnline;
    isOnline = status;

    if (wasOnline != isOnline) {
      if (isOnline) {
        onNetworkRestored();
      } else {
        onNetworkLost();
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }
}
