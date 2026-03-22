import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/services/image_upload_service.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';

class AddSubjectSheet extends StatefulWidget {
  final void Function(String name, String? imageUrl, DateTime? date) onSave;

  /// When set, sheet is in edit mode (name, date, cover prefilled; image can change).
  final Subject? existing;

  const AddSubjectSheet({
    super.key,
    required this.onSave,
    this.existing,
  });

  bool get isEditing => existing != null;

  @override
  State<AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<AddSubjectSheet> {
  final _nameController = TextEditingController();
  DateTime? _date;
  XFile? _pickedImage;

  /// User removed the existing network image without picking a new one.
  bool _clearedExistingImage = false;

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _date = e.date;
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final file = await ImageUploadService.pickImage(source: source);
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _clearedExistingImage = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      if (widget.existing?.imageUrl != null) {
        _clearedExistingImage = true;
      }
    });
  }

  bool get _hasCoverPreview =>
      _pickedImage != null ||
      (!_clearedExistingImage && widget.existing?.imageUrl != null);

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    String? imageUrl;

    if (_pickedImage != null) {
      setState(() => _uploading = true);
      try {
        imageUrl =
            await ImageUploadService.uploadSubjectImage(name, _pickedImage!);
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _uploading = false);
        return;
      }
    } else if (widget.isEditing) {
      if (_clearedExistingImage) {
        imageUrl = null;
      } else {
        imageUrl = widget.existing!.imageUrl;
      }
    }

    widget.onSave(name, imageUrl, _date);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? 'Edit Subject' : 'Add Subject',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: !widget.isEditing,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Subject Name *',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_pickedImage != null)
                    Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                    )
                  else if (!_clearedExistingImage &&
                      widget.existing?.imageUrl != null)
                    Image.network(
                      widget.existing!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme, colorScheme),
                    )
                  else
                    _placeholder(theme, colorScheme),
                  if (_hasCoverPreview)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: _uploading ? null : _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the image to change cover',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              _date != null
                  ? DateFormat.yMMMd().format(_date!)
                  : 'Target date (optional)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _uploading ? null : _submit,
            child: _uploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(widget.isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ThemeData theme, ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to add cover image',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
