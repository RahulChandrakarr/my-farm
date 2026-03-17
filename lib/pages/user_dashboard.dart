import 'package:flutter/material.dart';

import '../components/farm_bottom_nav.dart';
import '../theme/farm_theme.dart';
import 'user/farm_list_page.dart';
import 'user/overview_tab.dart';
import 'user/profile_tab.dart';
import 'user/work_entry_sheet.dart';
import 'user/works_tab.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  UserDashboardState createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard> {
  int _index = 0;
  final GlobalKey<WorksTabState> _worksKey = GlobalKey();
  final GlobalKey<OverviewTabState> _overviewKey = GlobalKey();

  static const titles = ['Overview', 'Works', 'Farms', 'Profile'];

  void _afterEntry() {
    _worksKey.currentState?.refresh();
    _overviewKey.currentState?.reload();
    setState(() {});
  }

  void goToTab(int i) {
    setState(() => _index = i);
    if (i == 0) _overviewKey.currentState?.reload();
  }

  void openEntrySheet() {
    showWorkEntrySheet(context, _afterEntry);
  }

  /// Call after a work entry is saved (e.g. sheet opened from a pushed route).
  void afterWorkEntry() => _afterEntry();

  void _onNavTap(int i) {
    goToTab(i);
  }

  /// Pops any pushed routes (e.g. farm detail) then switches tab.
  void popToRootAndGoTo(int i) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    goToTab(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: const TextStyle(
            color: FarmColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          OverviewTab(key: _overviewKey),
          WorksTab(key: _worksKey),
          FarmListPage(
            key: const ValueKey('farms_tab'),
            showAppBar: false,
            onFarmsChanged: () => _overviewKey.currentState?.reload(),
          ),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: FarmBottomNav(
        currentIndex: _index,
        onTap: _onNavTap,
        onCenterTap: openEntrySheet,
      ),
    );
  }
}
