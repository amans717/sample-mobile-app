import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/contact_model.dart';
import '../repositories/recording_repository.dart';
import '../services/call_service.dart';
import '../services/recording_service.dart';

enum CallStatus {
  idle,
  dialing,
  inCall,
  processingRecording,
  uploading,
  completed,
}

class CallProvider with ChangeNotifier {
  final CallService _callService = CallService.instance;
  final RecordingService _recordingService = RecordingService.instance;
  final RecordingRepository _recordingRepository = RecordingRepository();

  CallStatus _status = CallStatus.idle;
  ContactModel? _activeContact;
  DateTime? _callInitiatedAt;
  StreamSubscription? _callStateSubscription;
  BuildContext? _currentContext;

  CallStatus get status => _status;
  ContactModel? get activeContact => _activeContact;
  bool get isCallInProgress => _status == CallStatus.dialing || _status == CallStatus.inCall;
  bool get isUploading => _status == CallStatus.uploading;

  CallProvider() {
    _initCallStateSubscription();
  }

  void setContext(BuildContext context) {
    _currentContext = context;
  }

  void _initCallStateSubscription() {
    _callStateSubscription = _callService.callStateStream.listen((state) {
      _handleCallStateTransition(state);
    });
  }

  Future<void> initiateCall(BuildContext context, ContactModel contact) async {
    _currentContext = context;
    _activeContact = contact;
    _callInitiatedAt = DateTime.now();
    _status = CallStatus.dialing;
    notifyListeners();

    // 1. Start background/in-app recording engine before launching dialer
    await _recordingService.startAppRecording(contact.phoneNumber);

    // 2. Launch native Android phone call
    final launched = await _callService.launchPhoneCall(contact.phoneNumber);
    if (!launched) {
      _status = CallStatus.idle;
      _activeContact = null;
      notifyListeners();
      if (_currentContext != null) {
        SnackbarUtils.showError(_currentContext!, 'Could not launch phone call for ${contact.displayName}');
      }
    }
  }

  Future<void> _handleCallStateTransition(CallState state) async {
    switch (state) {
      case CallState.active:
        _status = CallStatus.inCall;
        notifyListeners();
        break;
      case CallState.completed:
        await _handleCallEnded();
        break;
      case CallState.idle:
        if (_status != CallStatus.processingRecording && _status != CallStatus.uploading) {
          _status = CallStatus.idle;
          notifyListeners();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _handleCallEnded() async {
    if (_activeContact == null || _callInitiatedAt == null) {
      _status = CallStatus.idle;
      notifyListeners();
      return;
    }

    final contact = _activeContact!;
    final callStartTime = _callInitiatedAt!;

    _status = CallStatus.processingRecording;
    notifyListeners();

    // Wait 1.5 seconds for device file buffers/dialer to flush audio file to disk
    await Future.delayed(const Duration(milliseconds: 1500));

    // Detect recorded audio file from either mic recording or device storage scan
    final recordingResult = await _recordingService.stopAndDetectRecording(
      phoneNumber: contact.phoneNumber,
      callInitiatedAt: callStartTime,
    );

    if (recordingResult != null && await recordingResult.file.exists()) {
      // 6. Upload automatically to Supabase
      _status = CallStatus.uploading;
      notifyListeners();

      try {
        await _recordingRepository.uploadRecording(
          audioFile: recordingResult.file,
          contactName: contact.displayName,
          phoneNumber: contact.phoneNumber,
          durationSeconds: recordingResult.durationSeconds,
          timestamp: callStartTime,
        );

        // 7. Show success snackbar
        if (_currentContext != null && _currentContext!.mounted) {
          SnackbarUtils.showSuccess(
            _currentContext!,
            'Call recording for ${contact.displayName} uploaded successfully!',
          );
        }
      } catch (e) {
        if (_currentContext != null && _currentContext!.mounted) {
          SnackbarUtils.showError(
            _currentContext!,
            'Failed to upload call recording: ${e.toString()}',
          );
        }
      }
    } else {
      // If recording not found: Display required message without crashing
      if (_currentContext != null && _currentContext!.mounted) {
        SnackbarUtils.showRecordingNotice(_currentContext!);
      }
    }

    _status = CallStatus.idle;
    _activeContact = null;
    _callInitiatedAt = null;
    notifyListeners();
  }

  /// Allows manually completing call from in-app overlay if needed
  void completeCallManually() {
    _callService.markCallEndedManually();
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    super.dispose();
  }
}
