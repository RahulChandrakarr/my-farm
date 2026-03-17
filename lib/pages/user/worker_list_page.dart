import 'package:flutter/material.dart';

import '../../theme/farm_theme.dart';
import 'worker_list_tab.dart';

/// Full-screen workers (opened from Profile).
class WorkerListPage extends StatelessWidget {
  const WorkerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Workers')),
      body: const WorkerListTab(),
    );
  }
}
