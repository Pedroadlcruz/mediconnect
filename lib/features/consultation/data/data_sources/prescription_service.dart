import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/models/prescription_model.dart';
import 'package:mediconnect/features/consultation/domain/entities/prescription.dart';

abstract class PrescriptionService {
  Future<String> savePrescription(PrescriptionModel prescription);
  Future<List<Prescription>> getPrescriptions(String patientId);
  Future<void> savePrescriptionLocally(PrescriptionModel prescription);
  Future<List<Prescription>> getLocalPrescriptions();
  Future<void> syncPendingPrescriptions();
}

@LazySingleton(as: PrescriptionService)
class PrescriptionServiceImpl implements PrescriptionService {
  final FirebaseFirestore _db;

  PrescriptionServiceImpl(this._db);

  CollectionReference get _prescriptionsRef => _db.collection('prescriptions');

  static const String _hiveBoxName = 'prescriptions_offline';

  @override
  Future<String> savePrescription(PrescriptionModel prescription) async {
    final docRef = await _prescriptionsRef.add(prescription.toFirestore());
    // Also save locally as synced
    final syncedPrescription = PrescriptionModel(
      id: docRef.id,
      roomId: prescription.roomId,
      doctorId: prescription.doctorId,
      doctorName: prescription.doctorName,
      patientId: prescription.patientId,
      patientName: prescription.patientName,
      diagnosis: prescription.diagnosis,
      medications: prescription.medications,
      instructions: prescription.instructions,
      signatureBase64: prescription.signatureBase64,
      createdAt: prescription.createdAt,
      isSynced: true,
    );
    await savePrescriptionLocally(syncedPrescription);
    return docRef.id;
  }

  @override
  Future<List<Prescription>> getPrescriptions(String patientId) async {
    final snapshot = await _prescriptionsRef
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PrescriptionModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> savePrescriptionLocally(PrescriptionModel prescription) async {
    final box = await Hive.openBox<Map>(_hiveBoxName);
    await box.put(
      prescription.id.isNotEmpty
          ? prescription.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      prescription.toHive(),
    );
  }

  @override
  Future<List<Prescription>> getLocalPrescriptions() async {
    final box = await Hive.openBox<Map>(_hiveBoxName);
    return box.values
        .map(
          (map) => PrescriptionModel.fromHive(Map<String, dynamic>.from(map)),
        )
        .toList();
  }

  @override
  Future<void> syncPendingPrescriptions() async {
    final box = await Hive.openBox<Map>(_hiveBoxName);
    final pendingEntries = box.toMap().entries.where((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      return data['isSynced'] != true;
    });

    for (final entry in pendingEntries) {
      try {
        final prescription = PrescriptionModel.fromHive(
          Map<String, dynamic>.from(entry.value),
        );
        final docRef = await _prescriptionsRef.add(prescription.toFirestore());

        // Update locally as synced
        final synced =
            prescription.copyWith(id: docRef.id, isSynced: true)
                as PrescriptionModel;
        await box.put(
          entry.key,
          PrescriptionModel(
            id: synced.id,
            roomId: synced.roomId,
            doctorId: synced.doctorId,
            doctorName: synced.doctorName,
            patientId: synced.patientId,
            patientName: synced.patientName,
            diagnosis: synced.diagnosis,
            medications: synced.medications,
            instructions: synced.instructions,
            signatureBase64: synced.signatureBase64,
            createdAt: synced.createdAt,
            isSynced: true,
          ).toHive(),
        );
      } catch (_) {
        // Will retry next sync
      }
    }
  }
}
