import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/consultation.dart';
import '../services/firebase_service.dart';

class ConsultationViewModel {
  ConsultationViewModel(this._firebaseService);

  final FirebaseService _firebaseService;

  Future<void> createConsultation({
    required String petName,
    required String species,
    required String age,
    required String details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final consultation = Consultation(
      id: const Uuid().v4(),
      userId: user.uid,
      petName: petName.trim(),
      species: species.trim(),
      age: age.trim(),
      details: details.trim(),
      createdAt: DateTime.now(),
    );

    await _firebaseService.addConsultation(
      user: user,
      consultation: consultation,
    );
  }

  Future<void> updateConsultation({
    required Consultation consultation,
    required String petName,
    required String species,
    required String age,
    required String details,
  }) {
    return _firebaseService.updateConsultation(
      consultation.copyWith(
        petName: petName.trim(),
        species: species.trim(),
        age: age.trim(),
        details: details.trim(),
        aiStatus: '',
        aiNotes: const AiNotes(),
      ),
    );
  }

  Future<void> deleteConsultation(Consultation consultation) {
    return _firebaseService.deleteConsultation(consultation);
  }
}
