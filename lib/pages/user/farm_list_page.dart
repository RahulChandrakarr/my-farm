import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/farm_service.dart';
import '../../theme/farm_theme.dart';
import '../user_dashboard.dart';
import 'add_farm_dialog.dart';
import 'farm_detail_page.dart';

class FarmListPage extends StatefulWidget {
  const FarmListPage({
    super.key,
    this.showAppBar = true,
    this.onFarmsChanged,
  });

  /// When false (e.g. user dashboard tab), no [Scaffold]/AppBar — parent supplies app bar.
  final bool showAppBar;

  /// Notifies when farms are added/removed/updated (e.g. refresh Overview).
  final VoidCallback? onFarmsChanged;

  @override
  State<FarmListPage> createState() => _FarmListPageState();
}

class _FarmListPageState extends State<FarmListPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      FarmService(Supabase.instance.client).fetchFarms();

  void _reload({bool notifyOverview = false}) {
    setState(() {
      _future = _load();
    });
    if (notifyOverview) widget.onFarmsChanged?.call();
  }

  Future<void> _openAddFarm() async {
    final ok = await showAddFarmDialog(context);
    if (ok && mounted) _reload(notifyOverview: true);
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FilledButton.icon(
              onPressed: _openAddFarm,
              icon: const Icon(Icons.add),
              label: const Text('Add farm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '${snap.error}\n\nRun SQL 006_farms_vegetables.sql',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No farms yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FarmColors.black.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _openAddFarm,
                            icon: const Icon(Icons.add),
                            label: const Text('Add farm'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: FarmColors.green,
                  onRefresh: () async {
                    final f = _load();
                    setState(() => _future = f);
                    await f;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: list.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (_, i) {
                      final row = list[i];
                      final id = row['id']?.toString() ?? '';
                      final name = row['name']?.toString() ?? '';
                      final size =
                          row['size_label']?.toString().trim() ?? '';
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: FarmColors.black.withValues(alpha: 0.08)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.agriculture_outlined,
                              color: FarmColors.green, size: 32),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            size.isEmpty
                                ? 'Tap to add / view vegetables'
                                : '$size · tap for vegetables',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: FarmColors.blackMuted),
                            onPressed: () async {
                              await FarmService(Supabase.instance.client)
                                  .deleteFarm(id);
                              _reload(notifyOverview: true);
                            },
                          ),
                          onTap: () {
                            final dash = context
                                .findAncestorStateOfType<UserDashboardState>();
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute<void>(
                                builder: (_) => FarmDetailPage(
                                  farmId: id,
                                  farmName: name,
                                  sizeLabel: size.isEmpty ? null : size,
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
                                .then((_) => _reload(notifyOverview: true));
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    if (!widget.showAppBar) {
      return ColoredBox(color: FarmColors.background, child: body);
    }
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Farms')),
      body: body,
    );
  }
}
