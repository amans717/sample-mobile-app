import 'dart:io';
import '../models/call_recording_model.dart';
import '../services/supabase_service.dart';

class RecordingRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;

  Future<List<CallRecordingModel>> getRecordings() async {
    return await _supabaseService.getCallRecordings();
  }

  Future<CallRecordingModel> uploadRecording({
    required File audioFile,
    required String contactName,
    required String phoneNumber,
    required int durationSeconds,
    required DateTime timestamp,
  }) async {
    return await _supabaseService.uploadCallRecording(
      audioFile: audioFile,
      contactName: contactName,
      phoneNumber: phoneNumber,
      durationSeconds: durationSeconds,
      timestamp: timestamp,
    );
  }

  Future<void> deleteRecording(CallRecordingModel recording) async {
    await _supabaseService.deleteRecording(recording);
  }
}
