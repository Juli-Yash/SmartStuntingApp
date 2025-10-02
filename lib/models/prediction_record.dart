// lib/models/prediction_record.dart
import 'package:smart_stunting_app/models/child.dart';
import 'package:smart_stunting_app/models/antropometry_record.dart';

class PredictionRecord {
  final int? id;
  final int anakId;
  final int antropometryRecordId;
  final String statusStunting;
  final String statusUnderweight;
  final String statusWasting;
  final String recommendation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Child? anak;
  final AntropometryRecord? antropometryRecord;

  PredictionRecord({
    this.id,
    required this.anakId,
    required this.antropometryRecordId,
    required this.statusStunting,
    required this.statusUnderweight,
    required this.statusWasting,
    required this.recommendation,
    this.createdAt,
    this.updatedAt,
    this.anak,
    this.antropometryRecord,
  });

  factory PredictionRecord.fromJson(Map<String, dynamic> json) {
    return PredictionRecord(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      anakId: (json['anak_id'] as num).toInt(),
      antropometryRecordId: (json['antropometry_record_id'] as num).toInt(),
      statusStunting: json['status_stunting'] as String,
      statusUnderweight: json['status_underweight'] as String,
      statusWasting: json['status_wasting'] as String,
      recommendation: json['recommendation'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'anak_id': anakId,
      'antropometry_record_id': antropometryRecordId,
      'status_stunting': statusStunting,
      'status_underweight': statusUnderweight,
      'status_wasting': statusWasting,
      'recommendation': recommendation,
    };
  }
}
