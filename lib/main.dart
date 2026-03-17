import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'pages/login_page.dart';
import 'services/profile_service.dart';
import 'theme/farm_theme.dart';
import 'pages/admin_dashboard.dart';
import 'pages/user_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Farm',
      debugShowCheckedModeBanner: false,
      theme: buildFarmTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Decides whether to show login or dashboard based on stored Supabase session.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _loading = true;
  bool _signedIn = false;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _signedIn = false;
      });
      return;
    }

    try {
      final type = await ProfileService(client).getUserType();
      final dest =
          type == AppUserType.admin ? const AdminDashboard() : const UserDashboard();
      setState(() {
        _home = dest;
        _signedIn = true;
        _loading = false;
      });
    } catch (_) {
      // If anything goes wrong, fall back to login.
      setState(() {
        _loading = false;
        _signedIn = false;
        _home = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_signedIn || _home == null) {
      return const LoginPage();
    }
    return _home!;
  }
}
