import 'package:supabase_flutter/supabase_flutter.dart';

class FarmService {
  FarmService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchFarms() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('farms')
        .select()
        .eq('user_id', uid)
        .order('name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchVegetables(String farmId) async {
    final rows = await _client
        .from('farm_vegetables')
        .select()
        .eq('farm_id', farmId)
        .order('name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, List<Map<String, dynamic>>>> farmsWithVegetables() async {
    final farms = await fetchFarms();
    final map = <String, List<Map<String, dynamic>>>{};
    for (final f in farms) {
      final id = f['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      map[id] = await fetchVegetables(id);
    }
    return map;
  }

  Future<String> insertFarm(String name, {String? sizeLabel}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    final payload = <String, dynamic>{
      'user_id': uid,
      'name': name.trim(),
    };
    final s = sizeLabel?.trim();
    if (s != null && s.isNotEmpty) payload['size_label'] = s;
    final row =
        await _client.from('farms').insert(payload).select('id').single();
    return row['id'] as String;
  }

  /// Creates farm then inserts each non-empty vegetable name.
  Future<String> insertFarmWithVegetables({
    required String name,
    String? sizeLabel,
    required Iterable<String> vegetableNames,
  }) async {
    final id = await insertFarm(name, sizeLabel: sizeLabel);
    for (final raw in vegetableNames) {
      final n = raw.trim();
      if (n.isEmpty) continue;
      await addVegetable(id, n);
    }
    return id;
  }

  Future<void> deleteFarm(String id) async {
    await _client.from('farms').delete().eq('id', id);
  }

  Future<void> addVegetable(String farmId, String name) async {
    await _client.from('farm_vegetables').insert({
      'farm_id': farmId,
      'name': name.trim(),
    });
  }

  Future<void> deleteVegetable(String id) async {
    await _client.from('farm_vegetables').delete().eq('id', id);
  }
}
