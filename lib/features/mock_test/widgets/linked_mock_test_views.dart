import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/features/mock_test/models/mock_test.dart';
import 'package:exam_ace/features/mock_test/utils/mock_test_score_style.dart';

/// Horizontal space per bar ([_BarColumn] width + trailing gap).
const double _kMockTestBarSlotWidth = 50;

/// Bar chart (newest tests to the right) + full history via bottom sheet when there are many tests.
class SubjectMockTestsChartSection extends StatelessWidget {
  final List<MockTest> tests;
  final String subjectTitle;

  const SubjectMockTestsChartSection({
    super.key,
    required this.tests,
    this.subjectTitle = 'Subject',
  });

  /// Recent attempts to show in the chart: scales with width (min 3, cap 80).
  static int chartBarCountForWidth(double width) {
    final n = (width / _kMockTestBarSlotWidth).floor();
    return math.min(80, math.max(3, n));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (tests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          'No mock tests linked to this subject yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final avgPct = tests.map((t) => t.percentage).reduce((a, b) => a + b) /
        tests.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barBudget = chartBarCountForWidth(constraints.maxWidth);
          final chronological = List<MockTest>.from(tests)
            ..sort((a, b) => a.date.compareTo(b.date));
          final chartSlice = chronological.length > barBudget
              ? chronological.sublist(chronological.length - barBudget)
              : chronological;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mock test scores',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tests.length} test${tests.length == 1 ? '' : 's'} · avg ${avgPct.round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tests.length > chartSlice.length)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Last ${chartSlice.length} in chart',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recent attempts (oldest → newest · scroll if needed)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 124,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final t in chartSlice)
                        _BarColumn(
                          test: t,
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openMockTestsHistorySheet(
                    context,
                    tests: tests,
                    title: subjectTitle,
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 20),
                  label: Text(
                    tests.length > chartSlice.length
                        ? 'View all ${tests.length} mock tests'
                        : 'View full list & details',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _openMockTestsHistorySheet(
  BuildContext context, {
  required List<MockTest> tests,
  required String title,
}) {
  final sorted = List<MockTest>.from(tests)
    ..sort((a, b) => b.date.compareTo(a.date));

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final h = MediaQuery.sizeOf(ctx).height * 0.88;

      return SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '$title · ${sorted.length} mock test${sorted.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  return _MockTestListCard(
                    test: sorted[i],
                    titleMaxLines: 2,
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shared row card for bottom sheet + chapter list.
class _MockTestListCard extends StatelessWidget {
  final MockTest test;
  final int titleMaxLines;

  const _MockTestListCard({
    required this.test,
    this.titleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: titleMaxLines > 1 ? 4 : 2,
        ),
        leading: CircleAvatar(
          backgroundColor: Color.alphaBlend(
            MockTestScoreStyle.accent(cs, test.percentage)
                .withValues(alpha: 0.2),
            cs.surfaceContainerHighest,
          ),
          child: Text(
            '${test.percentage.round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: MockTestScoreStyle.accent(cs, test.percentage),
            ),
          ),
        ),
        title: Text(
          test.title.trim().isEmpty ? 'Mock test' : test.title,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${test.marksObtained}/${test.totalMarks} · ${DateFormat.yMMMd().format(test.date)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final MockTest test;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _BarColumn({
    required this.test,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final p = test.percentage.clamp(0.0, 100.0);
    final barColor = MockTestScoreStyle.accent(colorScheme, p);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${p.round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: barColor,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final h = c.maxHeight;
                  final fill = h * (p / 100);
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 26,
                      height: fill.clamp(4.0, h),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat.MMMd().format(test.date),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mock tests for a chapter (below topics).
class ChapterMockTestsListSection extends StatelessWidget {
  final List<MockTest> tests;

  const ChapterMockTestsListSection({super.key, required this.tests});

  static const int _inlineMax = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tests.isEmpty) return const SizedBox.shrink();

    final showAllInSheet = tests.length > _inlineMax;
    final inline = showAllInSheet ? tests.take(_inlineMax).toList() : tests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Mock tests (${tests.length})',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ...inline.map(
          (t) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: _MockTestListCard(test: t, titleMaxLines: 1),
          ),
        ),
        if (showAllInSheet)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextButton.icon(
              onPressed: () => _openMockTestsHistorySheet(
                context,
                tests: tests,
                title: 'This chapter',
              ),
              icon: const Icon(Icons.open_in_full_rounded, size: 20),
              label: Text('View all ${tests.length} mock tests'),
            ),
          ),
      ],
    );
  }
}
