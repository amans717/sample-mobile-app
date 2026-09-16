import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class CallRecordingResult {
  final File file;
  final int durationSeconds;
  final String source; // 'app_mic' or 'device_dialer'

  CallRecordingResult({
    required this.file,
    required this.durationSeconds,
    required this.source,
  });
}

class RecordingService {
  static final RecordingService instance = RecordingService._();
  RecordingService._();

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentAppRecordingPath;
  DateTime? _recordingStartTime;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Starts the app-level audio recording workflow before the call connects
  Future<void> startAppRecording(String phoneNumber) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
        final fileName = 'rec_${cleanPhone}_$timestamp.m4a';
        final filePath = p.join(tempDir.path, fileName);

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        _currentAppRecordingPath = filePath;
        _recordingStartTime = DateTime.now();
        _isRecording = true;
      }
    } catch (e) {
      // Gracefully continue even if mic cannot be bound during call initiation
      _isRecording = false;
      _currentAppRecordingPath = null;
    }
  }

  /// Stops recording and checks both the in-app recorded file and device directories
  Future<CallRecordingResult?> stopAndDetectRecording({
    required String phoneNumber,
    required DateTime callInitiatedAt,
  }) async {
    File? resolvedFile;
    int duration = 0;
    String source = 'none';

    // 1. Stop app recorder if active
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        _isRecording = false;

        if (_recordingStartTime != null) {
          duration = DateTime.now().difference(_recordingStartTime!).inSeconds;
        }

        if (path != null) {
          final file = File(path);
          if (await file.exists() && await file.length() > 2048) {
            resolvedFile = file;
            source = 'app_mic';
          }
        }
      } catch (_) {
        _isRecording = false;
      }
    }

    // 2. Scan standard Android device call recording directories for native dialer files
    try {
      final dialerFile = await _scanDeviceRecordingDirectories(phoneNumber, callInitiatedAt);
      if (dialerFile != null) {
        resolvedFile = dialerFile;
        source = 'device_dialer';
        // If duration was 0 or unknown, estimate from file size or set default
        if (duration <= 0) {
          final sizeBytes = await dialerFile.length();
          duration = (sizeBytes / (16000)).clamp(3, 3600).toInt();
        }
      }
    } catch (_) {
      // Ignore directory scan errors gracefully
    }

    if (resolvedFile != null && await resolvedFile.exists()) {
      return CallRecordingResult(
        file: resolvedFile,
        durationSeconds: duration > 0 ? duration : 5,
        source: source,
      );
    }

    return null;
  }

  /// Scans device storage for call recordings created by the native Motorola/Google dialer
  Future<File?> _scanDeviceRecordingDirectories(
    String phoneNumber,
    DateTime callStartTime,
  ) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final List<String> candidatePaths = [
      '/storage/emulated/0/Recordings/Call',
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Music/Recordings/Call',
      '/storage/emulated/0/Music/Recordings',
      '/storage/emulated/0/Sounds',
    ];

    for (final path in candidatePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final entities = dir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (ext == '.m4a' || ext == '.mp3' || ext == '.aac' || ext == '.wav' || ext == '.amr') {
                final lastMod = await entity.lastModified();
                // Check if file was modified around or after call start time (within 10 minutes)
                final diff = lastMod.difference(callStartTime).inSeconds;
                final fileName = p.basename(entity.path).toLowerCase();

                final matchesPhone = cleanPhone.isNotEmpty && fileName.contains(cleanPhone);
                final matchesTime = diff >= -10 && diff <= 600;

                if (matchesPhone || matchesTime) {
                  return entity;
                }
              }
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
