import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediconnect/features/consultation/domain/entities/prescription.dart';

class PrescriptionModel extends Prescription {
  const PrescriptionModel({
    required super.id,
    required super.roomId,
    required super.doctorId,
    required super.doctorName,
    required super.patientId,
    required super.patientName,
    required super.diagnosis,
    required super.medications,
    required super.instructions,
    super.signatureBase64,
    required super.createdAt,
    super.isSynced,
  });

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrescriptionModel(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      medications: List<String>.from(data['medications'] ?? []),
      instructions: data['instructions'] ?? '',
      signatureBase64: data['signatureBase64'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSynced: true,
    );
  }

  factory PrescriptionModel.fromHive(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      medications: List<String>.from(map['medications'] ?? []),
      instructions: map['instructions'] ?? '',
      signatureBase64: map['signatureBase64'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isSynced: map['isSynced'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'diagnosis': diagnosis,
      'medications': medications,
      'instructions': instructions,
      'signatureBase64': signatureBase64,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toHive() {
    return {
      'id': id,
      'roomId': roomId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'diagnosis': diagnosis,
      'medications': medications,
      'instructions': instructions,
      'signatureBase64': signatureBase64,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }
}
