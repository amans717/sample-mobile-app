import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/call_recording_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient get client {
    return Supabase.instance.client;
  }

  Future<bool> initialize() async {
    try {
      if (!SupabaseConstants.isConfigured) {
        _isInitialized = false;
        return false;
      }

      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Uploads audio recording file to Supabase Storage bucket: call-recordings
  /// Structure: year/month/day/phone_timestamp.m4a
  /// Then inserts metadata row into call_recordings table
  Future<CallRecordingModel> uploadCallRecording({
    required File audioFile,
    required String contactName,
    required String phoneNumber,
    required int durationSeconds,
    required DateTime timestamp,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase is not initialized. Please verify your credentials.');
    }

    // 1. Generate path: year/month/day/phone_timestamp.m4a
    final storagePath = DateFormatter.generateStoragePath(phoneNumber, timestamp);

    // 2. Upload file to Storage Bucket
    final storage = client.storage.from(SupabaseConstants.storageBucket);
    await storage.upload(
      storagePath,
      audioFile,
      fileOptions: const FileOptions(
        contentType: 'audio/m4a',
        upsert: true,
      ),
    );

    // 3. Get Public URL for streaming
    final publicUrl = storage.getPublicUrl(storagePath);

    // 4. Save metadata in Supabase Database: call_recordings
    final insertData = {
      'contact_name': contactName,
      'phone': phoneNumber,
      'file_url': publicUrl,
      'duration_seconds': durationSeconds,
      'created_at': timestamp.toUtc().toIso8601String(),
    };

    final response = await client
        .from(SupabaseConstants.recordingsTable)
        .insert(insertData)
        .select()
        .single();

    return CallRecordingModel.fromJson(response);
  }

  /// Fetches all uploaded call recordings ordered by creation time (latest first)
  Future<List<CallRecordingModel>> getCallRecordings() async {
    if (!_isInitialized) return [];

    final response = await client
        .from(SupabaseConstants.recordingsTable)
        .select()
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => CallRecordingModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Deletes a recording row and its underlying audio file from storage
  Future<void> deleteRecording(CallRecordingModel recording) async {
    if (!_isInitialized) return;

    // 1. Delete from database
    await client
        .from(SupabaseConstants.recordingsTable)
        .delete()
        .eq('id', recording.id);

    // 2. Extract path from public URL and delete from storage
    try {
      final uri = Uri.parse(recording.fileUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(SupabaseConstants.storageBucket);
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await client.storage.from(SupabaseConstants.storageBucket).remove([filePath]);
      }
    } catch (_) {
      // Continue even if storage object was already removed
    }
  }
}
