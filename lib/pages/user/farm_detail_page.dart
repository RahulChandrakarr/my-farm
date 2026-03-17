import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/farm_bottom_nav.dart';
import '../../services/farm_service.dart';
import '../../theme/farm_theme.dart';
import 'vegetable_jobs_page.dart';

class FarmDetailPage extends StatefulWidget {
  const FarmDetailPage({
    super.key,
    required this.farmId,
    required this.farmName,
    this.sizeLabel,
    required this.onMainNavTab,
    required this.onOpenEntrySheet,
  });

  final String farmId;
  final String farmName;
  final String? sizeLabel;
  /// Pop to dashboard root then switch tab (0–3).
  final void Function(int tabIndex) onMainNavTab;
  /// Pop to root then open new work entry sheet.
  final VoidCallback onOpenEntrySheet;

  @override
  State<FarmDetailPage> createState() => _FarmDetailPageState();
}

class _FarmDetailPageState extends State<FarmDetailPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final _veg = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _veg.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      FarmService(Supabase.instance.client).fetchVegetables(widget.farmId);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _add() async {
    if (_veg.text.trim().isEmpty) return;
    await FarmService(Supabase.instance.client)
        .addVegetable(widget.farmId, _veg.text.trim());
    _veg.clear();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: Text(widget.farmName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.sizeLabel != null && widget.sizeLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Size: ${widget.sizeLabel}',
                style: TextStyle(
                  color: FarmColors.black.withValues(alpha: 0.65),
                  fontSize: 14,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _veg,
                    decoration: const InputDecoration(
                      labelText: 'Vegetable',
                      hintText: 'e.g. Tomato, Onion',
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _add,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Vegetables on this farm',
              style: TextStyle(
                color: FarmColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
                  return Center(child: Text('${snap.error}'));
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No vegetables yet.\nAdd names above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: FarmColors.black.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final row = list[i];
                    final id = row['id']?.toString() ?? '';
                    final name = row['name']?.toString() ?? '';
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: FarmColors.black.withValues(alpha: 0.08)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.eco_outlined,
                            color: FarmColors.green),
                        title: Text(name),
                        subtitle: const Text('Tap for jobs on this crop'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_right,
                                color: FarmColors.blackMuted),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: FarmColors.blackMuted),
                              onPressed: () async {
                                await FarmService(Supabase.instance.client)
                                    .deleteVegetable(id);
                                _reload();
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => VegetableJobsPage(
                                farmId: widget.farmId,
                                farmName: widget.farmName,
                                vegetableName: name,
                                onMainNavTab: widget.onMainNavTab,
                                onOpenEntrySheet: widget.onOpenEntrySheet,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: FarmBottomNav(
        currentIndex: 2,
        onTap: widget.onMainNavTab,
        onCenterTap: widget.onOpenEntrySheet,
      ),
    );
  }
}
