import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/worker_assignment.dart';
import '../../services/farm_service.dart';
import '../../services/farm_worker_service.dart';
import '../../services/work_entry_service.dart';
import '../../theme/farm_theme.dart';

Future<void> showWorkEntrySheet(BuildContext context, VoidCallback onSubmitted) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FarmColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _WorkEntrySheet(onSubmitted: onSubmitted),
  );
}

class _WorkEntrySheet extends StatefulWidget {
  const _WorkEntrySheet({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_WorkEntrySheet> createState() => _WorkEntrySheetState();
}

class _WorkEntrySheetState extends State<_WorkEntrySheet> {
  final _work = TextEditingController();
  final _description = TextEditingController();
  final _extraNameCtrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _directoryFuture;
  late Future<List<Map<String, dynamic>>> _farmsFuture;
  String? _farmId;
  String _farmName = '';
  String _vegetableName = '';
  Future<List<Map<String, dynamic>>>? _vegFuture;
  final _assigned = <WorkerAssignment>[];
  final _extraNames = <String>[];
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _directoryFuture = FarmWorkerService(Supabase.instance.client).fetchMine();
    _farmsFuture = FarmService(Supabase.instance.client).fetchFarms();
  }

  @override
  void dispose() {
    _work.dispose();
    _description.dispose();
    _extraNameCtrl.dispose();
    super.dispose();
  }

  void _toggleWorker(Map<String, dynamic> row) {
    final a = WorkerAssignment.fromFarmWorkerRow(row);
    setState(() {
      final i = _assigned.indexWhere((e) => e == a);
      if (i >= 0) {
        _assigned.removeAt(i);
      } else {
        _assigned.add(a);
      }
    });
  }

  bool _isSelected(Map<String, dynamic> row) {
    return _assigned.contains(WorkerAssignment.fromFarmWorkerRow(row));
  }

  void _addExtraName() {
    final name = _extraNameCtrl.text.trim();
    if (name.isEmpty) return;
    final lower = name.toLowerCase();
    final dupAssigned =
        _assigned.any((a) => a.name.toLowerCase() == lower);
    final dupExtra = _extraNames.any((n) => n.toLowerCase() == lower);
    if (dupAssigned || dupExtra) {
      _extraNameCtrl.clear();
      return;
    }
    setState(() {
      _extraNames.add(name);
      _extraNameCtrl.clear();
    });
  }

  List<WorkerAssignment> _allAssignments() {
    final list = List<WorkerAssignment>.from(_assigned);
    for (final n in _extraNames) {
      list.add(WorkerAssignment(name: n));
    }
    return list;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    if (_work.text.trim().isEmpty) {
      setState(() => _error = 'Enter work title');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final hm =
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
      final farm = FarmWorkerService(Supabase.instance.client);
      await farm.ensureNamesInDirectory(_extraNames);
      await WorkEntryService(Supabase.instance.client).insert(
        workTitle: _work.text.trim(),
        workDescription: _description.text.trim(),
        assignments: _allAssignments(),
        workDate: _date,
        workTimeHm: hm,
        farmId: _farmId,
        farmName: _farmName,
        vegetableName: _vegetableName,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: pad.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FarmColors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'New work entry',
              style: TextStyle(
                color: FarmColors.green,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _work,
              decoration: const InputDecoration(labelText: 'Work'),
              style: const TextStyle(color: FarmColors.black),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Work description',
                alignLabelWithHint: true,
              ),
              style: const TextStyle(color: FarmColors.black),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _farmsFuture,
              builder: (context, snap) {
                final farms = snap.data ?? [];
                return InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Farm',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _farmId,
                      isExpanded: true,
                      hint: const Text('— No farm —'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('— No farm —'),
                        ),
                        ...farms.map((f) {
                          final id = f['id']?.toString() ?? '';
                          final name = f['name']?.toString() ?? '';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text(name),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _farmId = v;
                          _farmName = '';
                          _vegetableName = '';
                          _vegFuture = null;
                          if (v != null) {
                            for (final f in farms) {
                              if (f['id']?.toString() == v) {
                                _farmName = f['name']?.toString() ?? '';
                                break;
                              }
                            }
                            _vegFuture = FarmService(Supabase.instance.client)
                                .fetchVegetables(v);
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Create farms under the Farms tab if empty.',
              style: TextStyle(
                fontSize: 11,
                color: FarmColors.black.withValues(alpha: 0.45),
              ),
            ),
            if (_farmId != null) ...[
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _vegFuture,
                builder: (context, vegSnap) {
                  final veggies = vegSnap.data ?? [];
                  if (vegSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final vegNames = veggies
                      .map((r) => r['name']?.toString() ?? '')
                      .where((n) => n.isNotEmpty)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vegNames.isNotEmpty)
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Vegetable / crop',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: vegNames.contains(_vegetableName)
                                  ? _vegetableName
                                  : '',
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('— None —'),
                                ),
                                ...vegNames.map(
                                  (n) => DropdownMenuItem<String>(
                                    value: n,
                                    child: Text(n),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() => _vegetableName = v ?? '');
                              },
                            ),
                          ),
                        )
                      else ...[
                        TextField(
                          onChanged: (s) =>
                              setState(() => _vegetableName = s.trim()),
                          decoration: const InputDecoration(
                            labelText: 'Vegetable / crop (optional)',
                            hintText: 'e.g. Tomato',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Add vegetables on this farm in Farms → tap farm → list.',
                            style: TextStyle(
                              fontSize: 11,
                              color: FarmColors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Workers from your list',
              style: TextStyle(
                color: FarmColors.blackMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to assign saved workers (optional).',
              style: TextStyle(
                fontSize: 12,
                color: FarmColors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _directoryFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final dir = snap.data ?? [];
                if (dir.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No saved workers — use “Add by name” below.',
                      style: TextStyle(
                        color: FarmColors.black.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dir.map((row) {
                    final sel = _isSelected(row);
                    final a = WorkerAssignment.fromFarmWorkerRow(row);
                    final img = row['profile_image_url']?.toString() ?? '';
                    return FilterChip(
                      avatar: img.isNotEmpty
                          ? CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(img),
                              onBackgroundImageError: (_, __) {},
                            )
                          : const CircleAvatar(
                              radius: 12,
                              backgroundColor: FarmColors.background,
                              child: Icon(Icons.person,
                                  size: 14, color: FarmColors.green),
                            ),
                      label: Text(
                        a.chipLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? FarmColors.background : FarmColors.black,
                        ),
                      ),
                      selected: sel,
                      onSelected: (_) => _toggleWorker(row),
                      selectedColor: FarmColors.green,
                      checkmarkColor: FarmColors.background,
                      side: const BorderSide(color: FarmColors.outline),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Add by name (only)',
              style: TextStyle(
                color: FarmColors.blackMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Type a name and + to add. Saved on this job and added to Worker list (no duplicates by name).',
              style: TextStyle(
                fontSize: 12,
                color: FarmColors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _extraNameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Worker name',
                      isDense: true,
                    ),
                    style: const TextStyle(color: FarmColors.black),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addExtraName(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addExtraName,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.add, size: 22),
                ),
              ],
            ),
            if (_extraNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _extraNames
                    .map(
                      (n) => Chip(
                        label: Text(n),
                        onDeleted: () =>
                            setState(() => _extraNames.remove(n)),
                        deleteIconColor: FarmColors.green,
                        side: const BorderSide(color: FarmColors.outline),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (_assigned.isNotEmpty || _extraNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'On this work: ${_allAssignments().map((e) => e.name).join(', ')}',
                style: const TextStyle(
                  fontSize: 11,
                  color: FarmColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: FarmColors.green),
                    label: Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: FarmColors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule,
                        size: 18, color: FarmColors.green),
                    label: Text(
                      _time.format(context),
                      style: const TextStyle(color: FarmColors.black),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFB71C1C))),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FarmColors.background,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
