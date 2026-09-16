import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum CallState {
  idle,
  dialing,
  active,
  completed,
}

class CallService {
  static final CallService instance = CallService._();
  CallService._() {
    _initCallStateChannel();
  }

  static const EventChannel _eventChannel =
      EventChannel('com.example.crm_call_sample/call_state');

  final StreamController<CallState> _callStateController =
      StreamController<CallState>.broadcast();

  Stream<CallState> get callStateStream => _callStateController.stream;

  StreamSubscription? _nativeSubscription;
  bool _isCallInitiatedByApp = false;
  CallState _currentState = CallState.idle;
  CallState get currentState => _currentState;

  void _initCallStateChannel() {
    _nativeSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final stateStr = event.toString();
        _handleNativeState(stateStr);
      },
      onError: (dynamic error) {
        // Log error silently, never crash
      },
    );
  }

  void _handleNativeState(String stateStr) {
    switch (stateStr) {
      case 'OFFHOOK':
        if (_isCallInitiatedByApp) {
          _updateState(CallState.active);
        }
        break;
      case 'RINGING':
        // Incoming call, keep idle for CRM outgoing call
        break;
      case 'IDLE':
        if (_isCallInitiatedByApp && (_currentState == CallState.active || _currentState == CallState.dialing)) {
          _updateState(CallState.completed);
          _isCallInitiatedByApp = false;
        }
        break;
      default:
        break;
    }
  }

  void _updateState(CallState state) {
    _currentState = state;
    _callStateController.add(state);
  }

  Future<bool> launchPhoneCall(String rawPhoneNumber) async {
    final cleanNumber = rawPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);

    _isCallInitiatedByApp = true;
    _updateState(CallState.dialing);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          _isCallInitiatedByApp = false;
          _updateState(CallState.idle);
          return false;
        }
        return true;
      } else {
        _isCallInitiatedByApp = false;
        _updateState(CallState.idle);
        return false;
      }
    } catch (e) {
      _isCallInitiatedByApp = false;
      _updateState(CallState.idle);
      return false;
    }
  }

  void markCallEndedManually() {
    if (_isCallInitiatedByApp) {
      _updateState(CallState.completed);
      _isCallInitiatedByApp = false;
    } else {
      _updateState(CallState.idle);
    }
  }

  void dispose() {
    _nativeSubscription?.cancel();
    _callStateController.close();
  }
}
