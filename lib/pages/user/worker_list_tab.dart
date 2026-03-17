import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/farm_worker_service.dart';
import '../../theme/farm_theme.dart';
import 'add_worker_sheet.dart';

class WorkerListTab extends StatefulWidget {
  const WorkerListTab({super.key});

  @override
  WorkerListTabState createState() => WorkerListTabState();
}

class WorkerListTabState extends State<WorkerListTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      FarmWorkerService(Supabase.instance.client).fetchMine();

  void refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _onPullRefresh() async {
    final f = _load();
    setState(() {
      _future = f;
    });
    await f;
  }

  Future<void> _openAdd() async {
    await showAddWorkerSheet(context, onSaved: refresh);
  }

  Future<void> _openEdit(Map<String, dynamic> row) async {
    await showAddWorkerSheet(context, onSaved: refresh, existing: row);
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    await FarmWorkerService(Supabase.instance.client).delete(id);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Workers',
                  style: TextStyle(
                    color: FarmColors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.person_add_outlined, size: 20),
                label: const Text('Add worker'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: FarmColors.green,
            onRefresh: _onPullRefresh,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                if (snap.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 80),
                      Text(
                        '${snap.error}\n\nRun migrations 004 + 005 in Supabase.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 48),
                      Icon(
                        Icons.groups_outlined,
                        size: 56,
                        color: FarmColors.black.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workers yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: FarmColors.black.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap Add worker to create a profile\n(name required; rest optional).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: FarmColors.black.withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _openAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Add worker'),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final row = list[i];
                    final name = row['name']?.toString() ?? '';
                    final type = row['worker_type']?.toString() ?? '';
                    final from = row['work_from']?.toString() ?? '';
                    final phone = row['phone']?.toString() ?? '';
                    final address = row['address']?.toString() ?? '';
                    final url = row['profile_image_url']?.toString() ?? '';
                    final subtitleLines = <String>[
                      [type, from].where((s) => s.isNotEmpty).join(' · '),
                      if (phone.isNotEmpty) phone,
                      if (address.isNotEmpty) address,
                    ].where((s) => s.isNotEmpty).toList();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      leading: url.isNotEmpty
                          ? CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  FarmColors.green.withValues(alpha: 0.12),
                              backgroundImage: NetworkImage(url),
                              onBackgroundImageError: (_, __) {},
                            )
                          : CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  FarmColors.green.withValues(alpha: 0.12),
                              child: const Icon(Icons.person_outline,
                                  color: FarmColors.green, size: 28),
                            ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: FarmColors.black,
                        ),
                      ),
                      subtitle: subtitleLines.isEmpty
                          ? null
                          : Text(
                              subtitleLines.join('\n'),
                              style: const TextStyle(
                                color: FarmColors.blackMuted,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                      isThreeLine: subtitleLines.length > 1,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: FarmColors.green),
                            onPressed: () => _openEdit(row),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: FarmColors.blackMuted),
                            onPressed: () => _delete(row),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
