import 'package:equatable/equatable.dart';

class Prescription extends Equatable {
  final String id;
  final String roomId;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String diagnosis;
  final List<String> medications;
  final String instructions;
  final String? signatureBase64; // Doctor's signature as base64 PNG
  final DateTime createdAt;
  final bool isSynced; // For offline support

  const Prescription({
    required this.id,
    required this.roomId,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.medications,
    required this.instructions,
    this.signatureBase64,
    required this.createdAt,
    this.isSynced = false,
  });

  bool get isSigned => signatureBase64 != null && signatureBase64!.isNotEmpty;

  Prescription copyWith({String? id, String? signatureBase64, bool? isSynced}) {
    return Prescription(
      id: id ?? this.id,
      roomId: roomId,
      doctorId: doctorId,
      doctorName: doctorName,
      patientId: patientId,
      patientName: patientName,
      diagnosis: diagnosis,
      medications: medications,
      instructions: instructions,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      createdAt: createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    doctorId,
    patientId,
    diagnosis,
    signatureBase64,
    isSynced,
  ];
}
