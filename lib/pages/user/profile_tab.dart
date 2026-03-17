import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/farm_theme.dart';
import '../login_page.dart';
import '../user_dashboard.dart';
import 'worker_list_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 40,
          backgroundColor: FarmColors.green.withValues(alpha: 0.15),
          child: const Icon(Icons.person, size: 44, color: FarmColors.green),
        ),
        const SizedBox(height: 16),
        Text(
          user?.email ?? 'User',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: FarmColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FarmColors.black.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 28),
        _sectionCard(
          context,
          icon: Icons.groups_outlined,
          title: 'Workers',
          subtitle: 'List, add, edit worker profiles',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WorkerListPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          icon: Icons.agriculture_outlined,
          title: 'Farms',
          subtitle: 'Farms and vegetables per farm',
          onTap: () {
            final dash =
                context.findAncestorStateOfType<UserDashboardState>();
            dash?.goToTab(2);
          },
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: FarmColors.black.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: FarmColors.green),
            title: const Text(
              'Sign out',
              style: TextStyle(
                color: FarmColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: FarmColors.black.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: FarmColors.green, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: FarmColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: FarmColors.blackMuted),
        onTap: onTap,
      ),
    );
  }
}
