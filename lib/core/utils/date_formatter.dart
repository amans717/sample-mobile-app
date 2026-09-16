import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _fullFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  static String formatDateTime(DateTime dateTime) {
    return _fullFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Generates the storage file path following the exact requirement:
  /// year/month/day/phone_timestamp.m4a
  /// Example: 2026/09/16/9876543210_1726500000.m4a
  static String generateStoragePath(String rawPhone, DateTime timestamp) {
    final year = timestamp.year.toString();
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final phoneSegment = cleanPhone.isEmpty ? 'unknown' : cleanPhone;
    final epochSeconds = timestamp.millisecondsSinceEpoch ~/ 1000;

    return '$year/$month/$day/${phoneSegment}_$epochSeconds.m4a';
  }
}
