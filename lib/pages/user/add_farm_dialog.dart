import 'package:flutter/material.dart';

import '../../services/farm_service.dart';
import '../../theme/farm_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dialog form: farm name, size, multiple vegetable rows.
Future<bool> showAddFarmDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _AddFarmDialog(),
  );
  return ok == true;
}

class _AddFarmDialog extends StatefulWidget {
  const _AddFarmDialog();

  @override
  State<_AddFarmDialog> createState() => _AddFarmDialogState();
}

class _AddFarmDialogState extends State<_AddFarmDialog> {
  final _name = TextEditingController();
  final _size = TextEditingController();
  final List<TextEditingController> _vegControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    for (final c in _vegControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addVegRow() {
    setState(() => _vegControllers.add(TextEditingController()));
  }

  void _removeVegRow(int i) {
    if (_vegControllers.length <= 1) return;
    _vegControllers[i].dispose();
    setState(() => _vegControllers.removeAt(i));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Farm name is required');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final vegNames = _vegControllers.map((c) => c.text).toList();
      await FarmService(Supabase.instance.client).insertFarmWithVegetables(
        name: name,
        sizeLabel: _size.text.trim().isEmpty ? null : _size.text.trim(),
        vegetableNames: vegNames,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FarmColors.background,
      title: const Text(
        'Add farm',
        style: TextStyle(color: FarmColors.black, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Farm name *',
                  hintText: 'e.g. North plot',
                ),
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _size,
                decoration: const InputDecoration(
                  labelText: 'Farm size',
                  hintText: 'e.g. 5 acres, 2 ha, 500 sq m',
                ),
                enabled: !_saving,
              ),
              const SizedBox(height: 20),
              Text(
                'Vegetables grown',
                style: TextStyle(
                  color: FarmColors.black.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add one crop per row (optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: FarmColors.blackMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_vegControllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vegControllers[i],
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Vegetable ${i + 1}',
                            hintText: 'e.g. Tomato',
                            isDense: true,
                          ),
                          enabled: !_saving,
                        ),
                      ),
                      if (_vegControllers.length > 1)
                        IconButton(
                          onPressed: _saving ? null : () => _removeVegRow(i),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: FarmColors.blackMuted),
                          tooltip: 'Remove row',
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _addVegRow,
                  icon: const Icon(Icons.add, color: FarmColors.green),
                  label: const Text('Add vegetable row',
                      style: TextStyle(color: FarmColors.green)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: FarmColors.black, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save farm'),
        ),
      ],
    );
  }
}
