import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/call_recording_model.dart';
import '../repositories/recording_repository.dart';
import '../services/audio_player_service.dart';

class HistoryProvider with ChangeNotifier {
  final RecordingRepository _repository = RecordingRepository();
  final AudioPlayerService _audioPlayer = AudioPlayerService.instance;

  List<CallRecordingModel> _recordings = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  List<CallRecordingModel> get recordings => _recordings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  HistoryProvider() {
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _totalDuration = dur;
        notifyListeners();
      }
    });
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recordings = await _repository.getRecordings();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay(CallRecordingModel recording) async {
    if (_currentlyPlayingId == recording.id && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        _currentlyPlayingId = recording.id;
        _totalDuration = Duration(seconds: recording.durationSeconds);
        notifyListeners();
        await _audioPlayer.playStream(recording.fileUrl);
      } catch (e) {
        _currentlyPlayingId = null;
        notifyListeners();
      }
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> resumeAudio() async {
    await _audioPlayer.resume();
  }

  Future<void> seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _currentlyPlayingId = null;
    notifyListeners();
  }

  Future<void> downloadRecording(BuildContext context, CallRecordingModel recording) async {
    try {
      final fileName = '${recording.phone}_${recording.createdAt.millisecondsSinceEpoch}.m4a';
      final file = await _audioPlayer.downloadAudio(
        fileUrl: recording.fileUrl,
        suggestedFileName: fileName,
      );
      if (context.mounted) {
        SnackbarUtils.showSuccess(context, 'Downloaded recording to ${file.path}');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Download failed: ${e.toString()}');
      }
    }
  }

  Future<void> deleteRecording(BuildContext context, CallRecordingModel recording) async {
    try {
      if (_currentlyPlayingId == recording.id) {
        await stopAudio();
      }

      await _repository.deleteRecording(recording);
      _recordings.removeWhere((r) => r.id == recording.id);
      notifyListeners();

      if (context.mounted) {
        SnackbarUtils.showSuccess(context, 'Recording deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Failed to delete recording: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}
