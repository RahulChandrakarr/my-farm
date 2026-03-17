import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/farm_bottom_nav.dart';
import '../../services/work_entry_service.dart';
import '../../theme/farm_theme.dart';

/// Work entries (jobs) for one vegetable on one farm.
class VegetableJobsPage extends StatelessWidget {
  const VegetableJobsPage({
    super.key,
    required this.farmId,
    required this.farmName,
    required this.vegetableName,
    required this.onMainNavTab,
    required this.onOpenEntrySheet,
  });

  final String farmId;
  final String farmName;
  final String vegetableName;
  final void Function(int tabIndex) onMainNavTab;
  final VoidCallback onOpenEntrySheet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vegetableName),
            Text(
              farmName,
              style: TextStyle(
                color: FarmColors.black.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: WorkEntryService(Supabase.instance.client)
            .fetchByFarmAndVegetable(
          farmId: farmId,
          vegetableName: vegetableName,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No jobs yet for $vegetableName.\n'
                  'Add a work entry with this farm and vegetable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FarmColors.black.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final row = list[i];
              final title = row['work_title']?.toString() ?? '';
              final desc = row['work_description']?.toString() ?? '';
              final date = row['work_date']?.toString() ?? '';
              final time = row['work_time']?.toString() ?? '';
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: FarmColors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: FarmColors.black,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '$date  ·  $time',
                        style: const TextStyle(
                          color: FarmColors.blackMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: FarmBottomNav(
        currentIndex: 2,
        onTap: onMainNavTab,
        onCenterTap: onOpenEntrySheet,
      ),
    );
  }
}
