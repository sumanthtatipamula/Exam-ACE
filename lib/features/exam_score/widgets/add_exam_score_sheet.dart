import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/constants/input_limits.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/core/utils/validators.dart';
import 'package:exam_ace/features/exam_score/models/exam_score.dart';
import 'package:exam_ace/features/exam_score/providers/exam_score_provider.dart';

class AddExamSheet extends ConsumerStatefulWidget {
  final Exam? existing;

  const AddExamSheet({super.key, this.existing});

  bool get isEditing => existing != null;

  @override
  ConsumerState<AddExamSheet> createState() => _AddExamSheetState();
}

class _AddExamSheetState extends ConsumerState<AddExamSheet> {
  final _nameController = TextEditingController();
  final _marksController = TextEditingController();
  final _totalController = TextEditingController();
  DateTime _date = DateTime.now();
  ExamAttemptStatus _status = ExamAttemptStatus.taken;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.examName;
      _date = e.date;
      _status = e.status;
      if (e.status == ExamAttemptStatus.taken) {
        if (e.marksObtained != null) {
          _marksController.text = '${e.marksObtained}';
        }
        if (e.totalMarks != null) {
          _totalController.text = '${e.totalMarks}';
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _marksController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Exam name is required.');
      return;
    }
    final lenErr = validateMaxLength(name, InputLimits.examName, 'Exam name');
    if (lenErr != null) {
      if (!mounted) return;
      showErrorSnackBar(context, lenErr);
      return;
    }

    int? marks;
    int? total;

    if (_status == ExamAttemptStatus.yetToTake) {
      marks = null;
      total = null;
    } else {
      final m = int.tryParse(_marksController.text.trim());
      final t = int.tryParse(_totalController.text.trim());
      if (m == null || t == null) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Marks obtained and total marks are required when status is Taken.',
        );
        return;
      }
      if (t <= 0) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Total marks must be greater than zero.');
        return;
      }
      if (m < 0 || m > t) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Marks obtained must be between 0 and total marks.',
        );
        return;
      }
      marks = m;
      total = t;
    }

    final repo = ref.read(examRepositoryProvider);
    final row = Exam(
      id: widget.existing?.id ?? '',
      examName: name,
      date: _date,
      status: _status,
      marksObtained: marks,
      totalMarks: total,
    );

    try {
      if (widget.existing != null) {
        await repo.update(row);
      } else {
        await repo.add(row);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnackBar(
        context,
        widget.isEditing ? 'Exam updated' : 'Exam added',
      );
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          userFacingError(
            e,
            debugPrefix: widget.isEditing ? 'Update exam' : 'Add exam',
            releaseMessage: widget.isEditing
                ? 'Could not update the exam. Please try again.'
                : 'Could not add the exam. Please try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taken = _status == ExamAttemptStatus.taken;

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
            Text(
              widget.isEditing ? 'Edit exam' : 'Add exam',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: InputLimits.examName,
              decoration: const InputDecoration(
                labelText: 'Exam name *',
                hintText: 'e.g. SSC CGL Tier-I · May shift',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExamAttemptStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status *',
              ),
              items: ExamAttemptStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _status = v;
                  if (v == ExamAttemptStatus.yetToTake) {
                    _marksController.clear();
                    _totalController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Date *',
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(DateFormat.yMMMd().format(_date)),
            ),
            if (taken) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Marks obtained *',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total marks *',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
