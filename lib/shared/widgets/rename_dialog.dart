import 'package:flutter/material.dart';

Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String currentName,
  String hint = 'Name',
}) {
  final controller = TextEditingController(text: currentName);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: currentName.length,
  );

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: hint,
          ),
          onSubmitted: (v) {
            final trimmed = v.trim();
            if (trimmed.isNotEmpty) Navigator.of(ctx).pop(trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) Navigator.of(ctx).pop(trimmed);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
