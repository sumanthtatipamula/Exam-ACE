import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';

class AddChapterSheet extends StatefulWidget {
  final void Function(String name, DateTime? date, int progress) onSave;

  /// When set, the sheet opens in edit mode with name, date, and progress filled in.
  final Chapter? existing;

  /// When editing, hide manual completion if the chapter has topics (progress is derived).
  final bool hasTopics;

  const AddChapterSheet({
    super.key,
    required this.onSave,
    this.existing,
    this.hasTopics = false,
  });

  bool get isEditing => existing != null;

  @override
  State<AddChapterSheet> createState() => _AddChapterSheetState();
}

class _AddChapterSheetState extends State<AddChapterSheet> {
  final _nameController = TextEditingController();
  DateTime? _date;
  double _progress = 0;
  String? _nameError;

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
    if (name.isEmpty) {
      setState(() => _nameError = 'Required');
      return;
    }
    setState(() => _nameError = null);
    final progress = widget.isEditing && widget.hasTopics
        ? widget.existing!.progress
        : _progress.round();
    widget.onSave(name, _date, progress);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.isEditing;
    final showManualCompletion = !editing || !widget.hasTopics;

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
            Text(editing ? 'Edit Chapter' : 'Add Chapter',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: !editing,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Chapter Name *',
                errorText: _nameError,
              ),
              onChanged: (_) => setState(() => _nameError = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                _date != null
                    ? DateFormat.yMMMd().format(_date!)
                    : 'Pick date (optional)',
              ),
            ),
            if (showManualCompletion) ...[
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
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Completion comes from your topics — edit topic progress on the chapter screen.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _submit,
                child: Text(editing ? 'Save' : 'Add')),
          ],
        ),
      ),
    );
  }
}
