import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._();
  AudioPlayerService._() {
    _initStreams();
  }

  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  String? _activeAudioUrl;
  String? get activeAudioUrl => _activeAudioUrl;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Duration get currentPosition => _player.position;
  Duration? get totalDuration => _player.duration;
  bool get isPlaying => _player.playing;

  void _initStreams() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  Future<void> playStream(String url) async {
    try {
      if (_activeAudioUrl == url && _player.processingState != ProcessingState.idle) {
        if (!_player.playing) {
          await _player.play();
        }
        return;
      }

      _activeAudioUrl = url;
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _activeAudioUrl = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _activeAudioUrl = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Downloads recording to device storage (Downloads or App Documents)
  Future<File> downloadAudio({
    required String fileUrl,
    required String suggestedFileName,
    void Function(int received, int total)? onProgress,
  }) async {
    Directory? targetDir;
    if (Platform.isAndroid) {
      targetDir = Directory('/storage/emulated/0/Download');
      if (!await targetDir.exists()) {
        targetDir = await getExternalStorageDirectory();
      }
    }
    targetDir ??= await getApplicationDocumentsDirectory();

    final savePath = p.join(targetDir.path, suggestedFileName);
    await _dio.download(
      fileUrl,
      savePath,
      onReceiveProgress: onProgress,
    );

    return File(savePath);
  }

  void dispose() {
    _player.dispose();
  }
}
