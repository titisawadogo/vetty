import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/consultation.dart';
import '../services/firebase_service.dart';
import '../viewmodels/consultation_viewmodel.dart';
import 'auth_provider.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final consultationViewModelProvider = Provider<ConsultationViewModel>((ref) {
  return ConsultationViewModel(ref.watch(firebaseServiceProvider));
});

final consultationsProvider = StreamProvider<List<Consultation>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return ref.watch(firebaseServiceProvider).watchConsultations(user.uid);
});
