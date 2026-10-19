import 'package:go_router/go_router.dart';
import 'package:vetty/models/consultation.dart';
import 'package:vetty/views/consultation_screen.dart';
import 'package:vetty/views/ai_notes_screen.dart';
import 'package:vetty/views/auth_gate.dart';
import 'package:vetty/views/consultation_detail_screen.dart';
import 'package:vetty/views/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),

    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(
      path: '/consultation',
      builder: (context, state) => const ConsultationScreen(),
    ),

    GoRoute(
      path: '/consultation/details',
      builder: (context, state) =>
          ConsultationDetailScreen(consultation: state.extra! as Consultation),
    ),

    GoRoute(
      path: '/consultation/ai-notes',
      builder: (context, state) =>
          AiNotesScreen(consultation: state.extra! as Consultation),
    ),
  ],
);
