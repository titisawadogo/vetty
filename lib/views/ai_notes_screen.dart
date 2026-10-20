import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';

import '../models/consultation.dart';
import '../providers/consultation_provider.dart';

class AiNotesScreen extends ConsumerStatefulWidget {
  const AiNotesScreen({required this.consultation, super.key});

  final Consultation consultation;

  @override
  ConsumerState<AiNotesScreen> createState() => _AiNotesScreenState();
}

class _AiNotesScreenState extends ConsumerState<AiNotesScreen> {
  AiNotes _notes = const AiNotes();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final consultation = await ref
          .read(firebaseServiceProvider)
          .getConsultation(widget.consultation);

      if (!mounted) return;

      if (consultation == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Consultation not found.';
        });
        return;
      }

      final notes = consultation.aiNotes;
      if (notes.summary.isNotEmpty || notes.advice.isNotEmpty) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
        return;
      }

      await _generateNotes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load AI notes.';
      });
    }
  }

  Future<void> _generateNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notes = await ref
          .read(firebaseServiceProvider)
          .generateAiNotes(widget.consultation.id);

      if (!mounted) return;
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (_) {
      final savedNotes = await _getCompletedNotes();
      if (!mounted) return;

      if (savedNotes != null) {
        setState(() {
          _notes = savedNotes;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not generate AI notes. Please try again.';
      });
    }
  }

  Future<AiNotes?> _getCompletedNotes() async {
    try {
      final consultation = await ref
          .read(firebaseServiceProvider)
          .getConsultation(widget.consultation);
      final notes = consultation?.aiNotes;

      if (consultation?.aiStatus == 'completed' &&
          notes != null &&
          (notes.summary.isNotEmpty || notes.advice.isNotEmpty)) {
        return notes;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Notes')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            Gap(16),
            Text('Generating AI notes...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const Gap(16),
              FilledButton(
                onPressed: _generateNotes,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedAiMagic),
                Gap(10),
                Expanded(child: Text('AI-generated notes. Review before use.')),
              ],
            ),
          ),
          const Gap(24),
          Text('Summary', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(_notes.summary),
          const Gap(24),
          Text('Advice', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(_notes.advice),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generateNotes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Regenerate AI notes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
