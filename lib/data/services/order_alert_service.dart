import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

/// Singleton service that listens for newly arrived orders and plays a high alert sound
/// for 30 seconds or until stopped by the admin.
/// Specifically scoped to the Admin Panel.
class OrderAlertService {
  static final OrderAlertService _instance = OrderAlertService._internal();
  factory OrderAlertService() => _instance;
  OrderAlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _knownOrderIds = {};
  bool _isInitialized = false;
  bool _isSoundEnabled = true;
  bool _isAlertActive = false;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;
  OrderModel? _currentAlertOrder;

  final ValueNotifier<bool> isSoundEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isAlertActiveNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(30);
  final ValueNotifier<OrderModel?> currentAlertOrderNotifier = ValueNotifier<OrderModel?>(null);

  bool get isSoundEnabled => _isSoundEnabled;
  set isSoundEnabled(bool value) {
    _isSoundEnabled = value;
    isSoundEnabledNotifier.value = value;
    if (!value && _isAlertActive) {
      _audioPlayer.stop();
    }
  }

  bool get isAlertActive => _isAlertActive;
  int get remainingSeconds => _remainingSeconds;
  OrderModel? get currentAlertOrder => _currentAlertOrder;

  void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
  }

  /// Callback when a new order arrives
  void Function(OrderModel newOrder)? onNewOrder;

  /// Initialize and configure audio player
  Future<void> init() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('OrderAlertService audio init: $e');
    }
  }

  /// Manually test the high-alert sound (loops for 30s or until stopped)
  Future<void> playTestAlert() async {
    await startAlert(order: null, isTest: true);
  }

  /// Starts the 30-second high-alert alarm
  Future<void> startAlert({OrderModel? order, bool isTest = false}) async {
    _countdownTimer?.cancel();

    _currentAlertOrder = order;
    currentAlertOrderNotifier.value = order;
    _isAlertActive = true;
    isAlertActiveNotifier.value = true;
    _remainingSeconds = 30;
    remainingSecondsNotifier.value = 30;

    // Start playing looping alarm sound
    if (_isSoundEnabled) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(1.0);
        if (kIsWeb) {
          // On Web, use absolute root-relative URL to avoid routing path resolution issues
          await _audioPlayer.play(UrlSource('/assets/assets/sounds/soundreality-siren-a-248662.mp3'));
        } else {
          await _audioPlayer.play(AssetSource('sounds/soundreality-siren-a-248662.mp3'));
        }
      } catch (e) {
        debugPrint('Failed to play primary order alert sound: $e');
        try {
          if (kIsWeb) {
            await _audioPlayer.play(UrlSource('/sounds/soundreality-siren-a-248662.mp3'));
          } else {
            await _audioPlayer.play(AssetSource('sounds/order_alert.wav'));
          }
        } catch (e2) {
          debugPrint('Fallback play failed: $e2');
          SystemSound.play(SystemSoundType.alert);
        }
      }
    }

    HapticFeedback.heavyImpact();

    // 30-second countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      remainingSecondsNotifier.value = _remainingSeconds;

      if (_remainingSeconds % 3 == 0) {
        HapticFeedback.heavyImpact();
      }

      if (_remainingSeconds <= 0) {
        stopAlert();
      }
    });
  }

  /// Stops the alarm immediately
  void stopAlert() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remainingSeconds = 0;
    remainingSecondsNotifier.value = 0;
    _isAlertActive = false;
    isAlertActiveNotifier.value = false;

    try {
      _audioPlayer.stop();
      _audioPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('Failed to stop alert audio: $e');
    }
  }

  /// Evaluates incoming orders from the admin orders stream.
  /// Skips past orders on first load, and alarms on any newly arriving order.
  void processOrders(List<OrderModel> orders) {
    if (orders.isEmpty) return;

    if (!_isInitialized) {
      // First time loading orders: record current order IDs so past orders don't ring the alarm
      for (final order in orders) {
        _knownOrderIds.add(order.id);
      }
      _isInitialized = true;
      return;
    }

    // Subsequent updates: check for any order ID not previously seen
    final newOrders = <OrderModel>[];
    for (final order in orders) {
      if (!_knownOrderIds.contains(order.id)) {
        _knownOrderIds.add(order.id);
        newOrders.add(order);
      }
    }

    if (newOrders.isNotEmpty) {
      final newestOrder = newOrders.first;
      // Start 30-second high-alert alarm
      startAlert(order: newestOrder);

      // Trigger callback
      onNewOrder?.call(newestOrder);
    }
  }

  void dispose() {
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
  }
}
