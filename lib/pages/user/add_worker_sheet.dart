import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/farm_worker_service.dart';
import '../../theme/farm_theme.dart';

const _kTypes = ['reja', 'kuli'];
const _kFrom = ['home', 'outside'];

/// [existing] when non-null opens in edit mode (same sheet).
Future<void> showAddWorkerSheet(
  BuildContext context, {
  required VoidCallback onSaved,
  Map<String, dynamic>? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FarmColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddWorkerBody(onSaved: onSaved, existing: existing),
  );
}

class _AddWorkerBody extends StatefulWidget {
  const _AddWorkerBody({required this.onSaved, this.existing});

  final VoidCallback onSaved;
  final Map<String, dynamic>? existing;

  @override
  State<_AddWorkerBody> createState() => _AddWorkerBodyState();
}

class _AddWorkerBodyState extends State<_AddWorkerBody> {
  final _name = TextEditingController();
  final _type = TextEditingController();
  final _from = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;
  Uint8List? _photoBytes;
  String? _photoMime;
  String? _workerId;
  String _existingImageUrl = '';

  bool get _isEdit => _workerId != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _workerId = e['id']?.toString();
      _name.text = e['name']?.toString() ?? '';
      _type.text = e['worker_type']?.toString() ?? '';
      _from.text = e['work_from']?.toString() ?? '';
      _phone.text = e['phone']?.toString() ?? '';
      _address.text = e['address']?.toString() ?? '';
      _existingImageUrl = e['profile_image_url']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _from.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final n = x.name.toLowerCase();
    setState(() {
      _photoBytes = bytes;
      _photoMime = n.endsWith('.png') ? 'image/png' : 'image/jpeg';
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final svc = FarmWorkerService(Supabase.instance.client);
      var imageUrl = _existingImageUrl;
      if (_photoBytes != null && _photoMime != null) {
        imageUrl = await svc.uploadProfilePhoto(_photoBytes!, _photoMime!);
      }
      if (_isEdit) {
        await svc.update(
          id: _workerId!,
          name: _name.text.trim(),
          workerType: _type.text.trim(),
          workFrom: _from.text.trim(),
          profileImageUrl: imageUrl,
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        );
      } else {
        await svc.insert(
          name: _name.text.trim(),
          workerType: _type.text.trim(),
          workFrom: _from.text.trim(),
          profileImageUrl: imageUrl,
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showNetworkPhoto =
        _photoBytes == null && _existingImageUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottom + 16,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit worker' : 'Add worker',
                    style: const TextStyle(
                      color: FarmColors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: FarmColors.blackMuted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: FarmColors.green.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _pickPhoto,
                      customBorder: const CircleBorder(),
                      child: _photoBytes != null
                          ? CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.transparent,
                              backgroundImage: MemoryImage(_photoBytes!),
                            )
                          : showNetworkPhoto
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage:
                                      NetworkImage(_existingImageUrl),
                                  onBackgroundImageError: (_, __) {},
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.transparent,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          color: FarmColors.green, size: 26),
                                      SizedBox(height: 4),
                                      Text(
                                        'Photo\n(optional)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: FarmColors.blackMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  if (_photoBytes != null || showNetworkPhoto)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: FarmColors.blackMuted,
                          foregroundColor: FarmColors.background,
                          padding: const EdgeInsets.all(6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => setState(() {
                          _photoBytes = null;
                          _photoMime = null;
                          _existingImageUrl = '';
                        }),
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact (optional)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            _autoField(_type, 'Type', 'reja / kuli', _kTypes),
            const SizedBox(height: 10),
            _autoField(_from, 'From', 'home / outside', _kFrom),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FarmColors.background,
                        ),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Save worker'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autoField(
    TextEditingController c,
    String label,
    String hint,
    List<String> opts,
  ) {
    return Autocomplete<String>(
      optionsBuilder: (tv) {
        final q = tv.text.toLowerCase();
        return opts.where((o) => o.toLowerCase().contains(q));
      },
      onSelected: (v) => c.text = v,
      fieldViewBuilder: (ctx, _, focus, onSubmit) {
        return TextField(
          controller: c,
          focusNode: focus,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: options
                    .map((o) => ListTile(
                          dense: true,
                          title: Text(o),
                          onTap: () => onSelected(o),
                        ))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
