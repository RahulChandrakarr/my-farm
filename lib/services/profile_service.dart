import 'package:supabase_flutter/supabase_flutter.dart';

enum AppUserType { admin, user }

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  /// Reads [user_type] from public.profiles for the signed-in user.
  Future<AppUserType> getUserType() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return AppUserType.user;

    final row = await _client
        .from('profiles')
        .select('user_type')
        .eq('id', uid)
        .maybeSingle();

    final type = row?['user_type'] as String?;
    if (type == 'admin') return AppUserType.admin;
    return AppUserType.user;
  }
}
