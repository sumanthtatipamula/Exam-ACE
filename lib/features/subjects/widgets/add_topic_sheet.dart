import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/features/subjects/models/topic.dart';

class AddTopicSheet extends StatefulWidget {
  final void Function(String name, DateTime? date, int progress) onSave;

  /// When set, the sheet opens in edit mode with name, date, and progress filled in.
  final Topic? existing;

  const AddTopicSheet({super.key, required this.onSave, this.existing});

  bool get isEditing => existing != null;

  @override
  State<AddTopicSheet> createState() => _AddTopicSheetState();
}

class _AddTopicSheetState extends State<AddTopicSheet> {
  final _nameController = TextEditingController();
  DateTime? _date;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _date = e.date;
      _progress = e.progress.toDouble();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name, _date, _progress.round());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.isEditing;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? 'Edit Topic' : 'Add Topic',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: !editing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Topic Name *',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(_date != null
                  ? DateFormat.yMMMd().format(_date!)
                  : 'Pick Date (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Completion: ${_progress.round()}%',
                    style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Slider(
                    value: _progress,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_progress.round()}%',
                    onChanged: (v) => setState(() => _progress = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _submit, child: Text(editing ? 'Save' : 'Add')),
          ],
        ),
      ),
    );
  }
}
