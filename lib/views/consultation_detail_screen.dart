import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../models/consultation.dart';
import '../providers/consultation_provider.dart';

class ConsultationDetailScreen extends ConsumerStatefulWidget {
  const ConsultationDetailScreen({required this.consultation, super.key});

  final Consultation consultation;

  @override
  ConsumerState<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState
    extends ConsumerState<ConsultationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _petNameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _ageController;
  late final TextEditingController _detailsController;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _petNameController = TextEditingController(
      text: widget.consultation.petName,
    );
    _speciesController = TextEditingController(
      text: widget.consultation.species,
    );
    _ageController = TextEditingController(text: widget.consultation.age);
    _detailsController = TextEditingController(
      text: widget.consultation.details,
    );
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _speciesController.dispose();
    _ageController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(consultationViewModelProvider)
          .updateConsultation(
            consultation: widget.consultation,
            petName: _petNameController.text,
            species: _speciesController.text,
            age: _ageController.text,
            details: _detailsController.text,
          );

      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update consultation.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete consultation?'),
        content: const Text('This consultation will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await ref
          .read(consultationViewModelProvider)
          .deleteConsultation(widget.consultation);

      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete consultation.')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: 'Delete consultation',
              child: Bounceable(
                onTap: isBusy ? null : _delete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: Theme.of(context).colorScheme.error,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _petNameController,
                  enabled: !isBusy,
                  validator: _required,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Pet name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                Gap(16),
                TextFormField(
                  controller: _speciesController,
                  enabled: !isBusy,
                  validator: _required,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Species',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                Gap(16),
                TextFormField(
                  controller: _ageController,
                  enabled: !isBusy,
                  validator: _required,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                Gap(16),
                TextFormField(
                  controller: _detailsController,
                  enabled: !isBusy,
                  validator: _required,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Consultation details',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                Gap(24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isBusy ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(_isSaving ? 'Saving...' : 'Save changes'),
                    ),
                  ),
                ),
                Gap(20),
                Bounceable(
                  onTap: isBusy
                      ? null
                      : () => context.push(
                          '/consultation/ai-notes',
                          extra: widget.consultation,
                        ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedAiMagic),
                          Gap(8),
                          Text('AI Notes'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
