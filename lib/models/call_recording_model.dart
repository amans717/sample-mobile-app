class CallRecordingModel {
  final String id;
  final String contactName;
  final String phone;
  final String fileUrl;
  final int durationSeconds;
  final DateTime createdAt;

  CallRecordingModel({
    required this.id,
    required this.contactName,
    required this.phone,
    required this.fileUrl,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory CallRecordingModel.fromJson(Map<String, dynamic> json) {
    return CallRecordingModel(
      id: json['id'] as String? ?? '',
      contactName: json['contact_name'] as String? ?? 'Unknown Customer',
      phone: json['phone'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_name': contactName,
      'phone': phone,
      'file_url': fileUrl,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  CallRecordingModel copyWith({
    String? id,
    String? contactName,
    String? phone,
    String? fileUrl,
    int? durationSeconds,
    DateTime? createdAt,
  }) {
    return CallRecordingModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      fileUrl: fileUrl ?? this.fileUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
