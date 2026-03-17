import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class FarmWorkerService {
  FarmWorkerService(this._client);

  final SupabaseClient _client;
  static const _bucket = 'worker_profiles';

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('farm_workers')
        .select()
        .eq('user_id', uid)
        .order('name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Uploads image bytes; returns public URL. Path: `{uid}/{timestamp}.jpg`
  Future<String> uploadProfilePhoto(Uint8List bytes, String contentType) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    final ext = contentType.contains('png') ? 'png' : 'jpg';
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Adds each name to [farm_workers] if this user does not already have that name (case-insensitive).
  Future<void> ensureNamesInDirectory(Iterable<String> names) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await fetchMine();
    final have = rows
        .map((r) => (r['name']?.toString() ?? '').toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (have.contains(key)) continue;
      await insert(
        name: name,
        workerType: '',
        workFrom: '',
      );
      have.add(key);
    }
  }

  Future<void> insert({
    required String name,
    required String workerType,
    required String workFrom,
    String profileImageUrl = '',
    String phone = '',
    String address = '',
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    await _client.from('farm_workers').insert({
      'user_id': uid,
      'name': name.trim(),
      'worker_type': workerType.trim(),
      'work_from': workFrom.trim(),
      'profile_image_url': profileImageUrl.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String workerType,
    required String workFrom,
    required String profileImageUrl,
    required String phone,
    required String address,
  }) async {
    await _client.from('farm_workers').update({
      'name': name.trim(),
      'worker_type': workerType.trim(),
      'work_from': workFrom.trim(),
      'profile_image_url': profileImageUrl.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('farm_workers').delete().eq('id', id);
  }
}
