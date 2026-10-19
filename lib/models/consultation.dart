import 'package:cloud_firestore/cloud_firestore.dart';

class AiNotes {
  const AiNotes({this.summary = '', this.advice = ''});

  final String summary;
  final String advice;

  factory AiNotes.fromFirestore(Map<String, dynamic>? data) {
    return AiNotes(
      summary: data?['summary'] as String? ?? '',
      advice: data?['advice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'summary': summary, 'advice': advice};
  }
}

class Consultation {
  const Consultation({
    required this.id,
    required this.userId,
    required this.petName,
    required this.species,
    required this.age,
    required this.details,
    required this.createdAt,
    this.aiStatus = '',
    this.aiNotes = const AiNotes(),
  });

  final String id;
  final String userId;
  final String petName;
  final String species;
  final String age;
  final String details;
  final DateTime createdAt;
  final String aiStatus;
  final AiNotes aiNotes;

  Consultation copyWith({
    String? petName,
    String? species,
    String? age,
    String? details,
    String? aiStatus,
    AiNotes? aiNotes,
  }) {
    return Consultation(
      id: id,
      userId: userId,
      petName: petName ?? this.petName,
      species: species ?? this.species,
      age: age ?? this.age,
      details: details ?? this.details,
      createdAt: createdAt,
      aiStatus: aiStatus ?? this.aiStatus,
      aiNotes: aiNotes ?? this.aiNotes,
    );
  }

  factory Consultation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    final timestamp = data['createdAt'] as Timestamp?;
    final aiNotesData = data['aiNotes'];

    return Consultation(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      petName: data['petName'] as String? ?? '',
      species: data['species'] as String? ?? '',
      age: data['age'] as String? ?? '',
      details: data['details'] as String? ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      aiStatus: data['aiStatus'] as String? ?? '',
      aiNotes: AiNotes.fromFirestore(
        aiNotesData is Map<String, dynamic> ? aiNotesData : null,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'petName': petName,
      'species': species,
      'age': age,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'aiStatus': aiStatus,
      'aiNotes': aiNotes.toFirestore(),
    };
  }
}
