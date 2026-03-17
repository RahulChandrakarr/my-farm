import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/farm_service.dart';
import '../../services/farm_worker_service.dart';
import '../../services/work_entry_service.dart';
import '../../theme/farm_theme.dart';
import '../user_dashboard.dart';
import 'farm_detail_page.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => OverviewTabState();
}

class OverviewTabState extends State<OverviewTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() {
    final client = Supabase.instance.client;
    return Future.wait([
      WorkEntryService(client).fetchMine(),
      FarmWorkerService(client).fetchMine(),
      FarmService(client).fetchFarms(),
      FarmService(client).farmsWithVegetables(),
    ]);
  }

  /// Call when Overview is shown again or after data changes elsewhere.
  void reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _onRefresh() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        final entries = _listAt(snap, 0);
        final farmWorkers = _listAt(snap, 1);
        final farms = _listAt(snap, 2);
        Map<String, List<Map<String, dynamic>>> vegByFarm = {};
        if (snap.hasData && snap.data!.length > 3 && snap.data![3] is Map) {
          vegByFarm = Map<String, List<Map<String, dynamic>>>.from(
            (snap.data![3] as Map).map(
              (k, v) => MapEntry(
                k.toString(),
                List<Map<String, dynamic>>.from(v as List),
              ),
            ),
          );
        }

        final listView = ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text(
              'Farms',
              style: TextStyle(
                color: FarmColors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (farms.isEmpty)
              Text(
                'No farms yet. Use the Farms tab or Profile → Farms.',
                style: TextStyle(
                  color: FarmColors.black.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              )
            else
              ...farms.map((farm) {
                final id = farm['id']?.toString() ?? '';
                final name = farm['name']?.toString() ?? '';
                final sizeLabel = farm['size_label']?.toString().trim();
                final veg = vegByFarm[id] ?? [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: FarmColors.black.withValues(alpha: 0.08)),
                    ),
                    child: InkWell(
                      onTap: () {
                        final dash = context
                            .findAncestorStateOfType<UserDashboardState>();
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute<void>(
                            builder: (_) => FarmDetailPage(
                              farmId: id,
                              farmName: name,
                              sizeLabel:
                                  sizeLabel != null && sizeLabel.isNotEmpty
                                      ? sizeLabel
                                      : null,
                              onMainNavTab: (i) {
                                Navigator.of(context)
                                    .popUntil((r) => r.isFirst);
                                dash?.goToTab(i);
                              },
                              onOpenEntrySheet: () {
                                Navigator.of(context)
                                    .popUntil((r) => r.isFirst);
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (dash?.mounted ?? false) {
                                    dash!.openEntrySheet();
                                  }
                                });
                              },
                            ),
                          ),
                        )
                            .then((_) => reload());
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.agriculture_outlined,
                                    color: FarmColors.green, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: FarmColors.green,
                                        ),
                                      ),
                                      if (sizeLabel != null &&
                                          sizeLabel.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          sizeLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: FarmColors.black
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: FarmColors.blackMuted, size: 20),
                              ],
                            ),
                            if (veg.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Vegetables',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: FarmColors.black.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: veg
                                    .map(
                                      (v) => Chip(
                                        label: Text(
                                          v['name']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        side: const BorderSide(
                                            color: FarmColors.outline),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ] else
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'No vegetables yet — tap to add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        FarmColors.black.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),
            Container(
              height: 1,
              color: FarmColors.black.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 20),
            const Text(
              'Stats',
              style: TextStyle(
                color: FarmColors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Summary at a glance',
              style: TextStyle(
                color: FarmColors.black.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _StatCard(
              title: 'Work entries',
              value: '${entries.length}',
              icon: Icons.assignment_outlined,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Saved workers',
              value: '${farmWorkers.length}',
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Farms',
              value: '${farms.length}',
              icon: Icons.agriculture_outlined,
            ),
          ],
        );

        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: FarmColors.green,
          onRefresh: _onRefresh,
          child: listView,
        );
      },
    );
  }

  static List<Map<String, dynamic>> _listAt(
      AsyncSnapshot<List<dynamic>> snap, int i) {
    if (!snap.hasData || snap.data!.length <= i) return [];
    final x = snap.data![i];
    if (x is! List) return [];
    return List<Map<String, dynamic>>.from(x);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: FarmColors.black.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: FarmColors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: FarmColors.blackMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: FarmColors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
