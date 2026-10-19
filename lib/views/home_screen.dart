import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../models/consultation.dart';
import '../providers/auth_provider.dart';
import '../providers/consultation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultations = ref.watch(consultationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedPawPrint,
              size: 28,
              color: Colors.black,
            ),
            Text(
              'Vetty',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'Sign out',
            child: Bounceable(
              onTap: () => ref.read(authServiceProvider).signOut(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout03,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: consultations.when(
        data: (items) => _ConsultationList(consultations: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not load consultations.'),
          ),
        ),
      ),
      floatingActionButton: Bounceable(
        onTap: () => context.push('/consultation'),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedPlus,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsultationList extends StatefulWidget {
  const _ConsultationList({required this.consultations});

  final List<Consultation> consultations;

  @override
  State<_ConsultationList> createState() => _ConsultationListState();
}

class _ConsultationListState extends State<_ConsultationList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consultations (${widget.consultations.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Gap(16),
          Expanded(
            child: widget.consultations.isEmpty
                ? Center(
                    child: Column(
                      spacing: 20,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/animations/dog.json', height: 200),
                        Text(
                          'No consultations yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: widget.consultations.length,
                    separatorBuilder: (context, index) => Gap(12),
                    itemBuilder: (context, index) {
                      final consultation = widget.consultations[index];
                      return Bounceable(
                        onTap: () => context.push(
                          '/consultation/details',
                          extra: consultation,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              consultation.petName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${consultation.species} • ${consultation.age}',
                                  ),
                                  Gap(6),
                                  Text(
                                    consultation.details,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            trailing: const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
