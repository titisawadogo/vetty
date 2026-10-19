import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/consultation.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<Consultation>> watchConsultations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('consultations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Consultation.fromFirestore).toList(),
        );
  }

  Future<void> addConsultation({
    required User user,
    required Consultation consultation,
  }) async {
    final userDocument = _firestore.collection('users').doc(user.uid);
    final consultationDocument = userDocument
        .collection('consultations')
        .doc(consultation.id);
    final batch = _firestore.batch();

    batch.set(userDocument, {
      'id': user.uid,
      'name': user.displayName,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(consultationDocument, consultation.toFirestore());

    await batch.commit();
  }

  Future<void> updateConsultation(Consultation consultation) {
    return _firestore
        .collection('users')
        .doc(consultation.userId)
        .collection('consultations')
        .doc(consultation.id)
        .update(consultation.toFirestore());
  }

  Future<void> deleteConsultation(Consultation consultation) {
    return _firestore
        .collection('users')
        .doc(consultation.userId)
        .collection('consultations')
        .doc(consultation.id)
        .delete();
  }

  Future<Consultation?> getConsultation(Consultation consultation) async {
    final document = await _firestore
        .collection('users')
        .doc(consultation.userId)
        .collection('consultations')
        .doc(consultation.id)
        .get();

    if (!document.exists) return null;
    return Consultation.fromFirestore(document);
  }

  Future<AiNotes> generateAiNotes(String consultationId) async {
    final callable = _functions.httpsCallable('generateConsultationNotes');
    final result = await callable.call<Map<String, dynamic>>({
      'consultationId': consultationId,
    });

    return AiNotes.fromFirestore(result.data);
  }
}
