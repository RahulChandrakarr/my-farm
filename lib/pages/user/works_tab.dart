import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/work_entry_service.dart';
import '../../theme/farm_theme.dart';

class WorksTab extends StatefulWidget {
  const WorksTab({super.key});

  @override
  WorksTabState createState() => WorksTabState();
}

List<String> _assignLines(Map<String, dynamic> row) {
  final ja = row['worker_assignments'];
  if (ja is! List || ja.isEmpty) {
    final w = row['workers'];
    if (w is List) {
      return w.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
  return ja.map((e) {
    if (e is! Map) return '';
    final name = e['name']?.toString() ?? '';
    final type = e['worker_type']?.toString() ?? '';
    final from = e['work_from']?.toString() ?? '';
    final rest = [type, from].where((s) => s.isNotEmpty).join(' · ');
    return rest.isEmpty ? name : '$name ($rest)';
  }).where((s) => s.isNotEmpty).toList();
}

class WorksTabState extends State<WorksTab> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchCtrl = TextEditingController();
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      WorkEntryService(Supabase.instance.client).fetchMineFiltered(
        from: _from,
        to: _to,
        search: _searchCtrl.text,
      );

  void refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _runSearch() {
    setState(() {
      _future = _load();
    });
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
      _searchCtrl.clear();
      _future = _load();
    });
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? _from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _to = d);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: FarmColors.background,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: FarmColors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFrom,
                        icon: const Icon(Icons.calendar_today_outlined,
                            size: 18, color: FarmColors.green),
                        label: Text(
                          'From ${_fmt(_from)}',
                          style: const TextStyle(
                            color: FarmColors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTo,
                        icon: const Icon(Icons.event_outlined,
                            size: 18, color: FarmColors.green),
                        label: Text(
                          'To ${_fmt(_to)}',
                          style: const TextStyle(
                            color: FarmColors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  decoration: const InputDecoration(
                    hintText: 'Search work, description, workers…',
                    prefixIcon: Icon(Icons.search, color: FarmColors.green),
                    isDense: true,
                  ),
                  style: const TextStyle(color: FarmColors.black),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _runSearch,
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: FarmColors.blackMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
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
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snap.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No entries match your filters.\nChange dates or search, then tap Search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FarmColors.black.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: FarmColors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if ((row['farm_name']?.toString() ?? '')
                                  .isNotEmpty ||
                              (row['vegetable_name']?.toString() ?? '')
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if ((row['farm_name']?.toString() ?? '')
                                    .isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.agriculture_outlined,
                                        size: 14,
                                        color: FarmColors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        row['farm_name']!.toString(),
                                        style: const TextStyle(
                                          color: FarmColors.blackMuted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if ((row['vegetable_name']?.toString() ?? '')
                                    .isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.spa_outlined,
                                        size: 14,
                                        color: FarmColors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        row['vegetable_name']!.toString(),
                                        style: const TextStyle(
                                          color: FarmColors.blackMuted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              style: const TextStyle(
                                color: FarmColors.black,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_outlined,
                                size: 16,
                                color: FarmColors.blackMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$date  ·  $time',
                                style: const TextStyle(
                                  color: FarmColors.blackMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_assignLines(row).isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ..._assignLines(row).map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: FarmColors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: const TextStyle(
                                          color: FarmColors.black,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
