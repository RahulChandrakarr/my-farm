import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/worker_assignment.dart';

class WorkEntryService {
  WorkEntryService(this._client);

  final SupabaseClient _client;

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('work_entries')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Work entries for this farm + vegetable (jobs tagged in new entry sheet).
  Future<List<Map<String, dynamic>>> fetchByFarmAndVegetable({
    required String farmId,
    required String vegetableName,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('work_entries')
        .select()
        .eq('user_id', uid)
        .eq('farm_id', farmId)
        .eq('vegetable_name', vegetableName.trim())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchMineFiltered({
    DateTime? from,
    DateTime? to,
    String? search,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    dynamic query = _client
        .from('work_entries')
        .select()
        .eq('user_id', uid);

    if (from != null) {
      query = query.gte('work_date', _dateOnly(from));
    }
    if (to != null) {
      query = query.lte('work_date', _dateOnly(to));
    }

    final rows = await query.order('created_at', ascending: false);
    var list = List<Map<String, dynamic>>.from(rows as List);

    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list.where((row) {
        final t = row['work_title']?.toString().toLowerCase() ?? '';
        final d = row['work_description']?.toString().toLowerCase() ?? '';
        final w = row['workers'];
        var workersStr = '';
        if (w is List) {
          workersStr = w.map((e) => e.toString().toLowerCase()).join(' ');
        }
        var assignStr = '';
        assignStr +=
            '${row['farm_name'] ?? ''} ${row['farm_id'] ?? ''} ${row['vegetable_name'] ?? ''} '
                .toLowerCase();
        final ja = row['worker_assignments'];
        if (ja is List) {
          for (final e in ja) {
            if (e is Map) {
              assignStr +=
                  '${e['name']} ${e['worker_type']} ${e['work_from']} ';
            }
          }
        }
        assignStr = assignStr.toLowerCase();
        return t.contains(q) ||
            d.contains(q) ||
            workersStr.contains(q) ||
            assignStr.contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> insert({
    required String workTitle,
    required String workDescription,
    required List<WorkerAssignment> assignments,
    required DateTime workDate,
    required String workTimeHm,
    String? farmId,
    String farmName = '',
    String vegetableName = '',
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    final names = assignments.map((e) => e.name).toList();
    await _client.from('work_entries').insert({
      'user_id': uid,
      'work_title': workTitle,
      'work_description': workDescription,
      'workers': names,
      'worker_assignments':
          assignments.map((e) => e.toJson()).toList(growable: false),
      'work_date': _dateOnly(workDate),
      'work_time': workTimeHm,
      'farm_id': farmId,
      'farm_name': farmName.trim(),
      'vegetable_name': vegetableName.trim(),
    });
  }
}
