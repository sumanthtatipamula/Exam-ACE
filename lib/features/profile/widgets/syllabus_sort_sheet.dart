import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/settings/syllabus_sort_mode.dart';
import 'package:exam_ace/core/settings/syllabus_sort_provider.dart';

Future<void> showSyllabusSortSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final current = ref.watch(syllabusSortProvider);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Chapter & topic order',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Applies to chapter lists under each subject and topic lists under each chapter.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final mode in SyllabusSortMode.values)
                RadioListTile<SyllabusSortMode>(
                  value: mode,
                  groupValue: current,
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref.read(syllabusSortProvider.notifier).setMode(v);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  title: Text(mode.title),
                  subtitle: Text(
                    mode.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
