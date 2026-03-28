import 'package:flutter/material.dart';
import 'package:exam_ace/core/constants/app_strings.dart';

/// About the app — features and audience (govt. & competitive exam prep).
class AboutScreen extends StatefulWidget {
  /// When true (e.g. `/about?section=week-score`), scrolls to the week-% explainer.
  final bool scrollToWeekScoreSection;

  const AboutScreen({
    super.key,
    this.scrollToWeekScoreSection = false,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _weekScoreSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToWeekScoreSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToWeekScore();
        });
      });
    }
  }

  void _scrollToWeekScore() {
    final ctx = _weekScoreSectionKey.currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.school_rounded,
                size: 46,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.appTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Syllabus, mocks & real exams — in one place',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'v1.0.0',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Built for aspirants targeting government and other '
                'competitive exams in India — SSC, UPSC, banking, railway, '
                'state PSCs, and more. Organise your prep and see progress clearly.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What you can do',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFF66BB6A),
              title: 'Track your syllabus',
              body:
                  'Split subjects into chapters and topics. Mark what’s done '
                  'so you always know gaps before the real exam.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF42A5F5),
              title: 'Plan your days',
              body:
                  'Schedule tasks and study blocks on specific dates. Home '
                  'shows what matters today — tasks and chapter work together.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.show_chart_rounded,
              iconColor: const Color(0xFFFFA726),
              title: 'Weekly pulse',
              body:
                  'A week-at-a-glance chart for consistency: see strong days '
                  'and where to push harder next week.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.quiz_rounded,
              iconColor: const Color(0xFFEF5350),
              title: 'Mock tests',
              body:
                  'Log mock scores, link attempts to subjects or topics, and '
                  'read trends from colour-coded charts on subject screens.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.fact_check_rounded,
              iconColor: const Color(0xFF26A69A),
              title: 'Exams',
              body:
                  'Record upcoming and completed attempts — actual exams, not '
                  'mocks. Mark “Yet to take” or enter marks when results are out.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.notifications_active_rounded,
              iconColor: theme.colorScheme.primary,
              title: 'Reminders',
              body:
                  'Optional morning and evening nudges so you open the app with '
                  'intent and close the day with a quick review.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.calendar_view_month_rounded,
              iconColor: const Color(0xFF7E57C2),
              title: 'Calendar history',
              body:
                  'Jump to any past date to see what you completed — dots show '
                  'full, partial, or no work at a glance.',
            ),
            const SizedBox(height: 28),
            Column(
              key: _weekScoreSectionKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'How your week % is counted',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You choose this in Profile. It only changes the big % on Home and '
                  'week-over-week — not your task list.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Days with no tasks aren’t treated as 0% — they’re skipped. Only '
                  'tasks you scheduled count, and partial progress on a task counts '
                  'toward its % (you don’t need to finish fully for it to matter).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _WeekScoreExplainer(theme: theme),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Stay organised. Stay consistent.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Good luck with your preparation.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain-language + tiny number examples for Profile → “How your week % is counted”.
class _WeekScoreExplainer extends StatelessWidget {
  final ThemeData theme;

  const _WeekScoreExplainer({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modeBlock(
              theme,
              'Simple — normal average',
              'weekRatio = sum(p_i) / (n * 100)\n'
              'p_i = each task’s progress 0–100; n = number of tasks this week. '
              'The app shows weekRatio as a percent.',
              'We add every task’s % and divide by how many tasks you had this week. '
                  'Each task counts the same.\n\n'
                  'Example: three tasks at 100%, 100%, and 0% → about 67% for the week '
                  '(200 ÷ 300).',
            ),
            Divider(height: 28, color: cs.outlineVariant.withValues(alpha: 0.4)),
            _modeBlock(
              theme,
              'Strong — rewards finishing well',
              'weekRatio = ( (1/n) * sum( (p_i/100)^3 ) )^(1/3)\n'
              'Cube each fraction (0–1), average the cubes, then take the cube root. '
              'Same as Simple when every task matches.',
              'Finishing tasks at a high % helps your week more than having many tasks '
                  'only partly done.\n\n'
                  'Example: same three tasks at 100%, 100%, and 0% → the week % comes out '
                  'higher than 67% (near 87%) because the two full finishes count extra.',
            ),
            Divider(height: 28, color: cs.outlineVariant.withValues(alpha: 0.4)),
            _modeBlock(
              theme,
              'Strict — your worst day sets the week',
              'weekRatio = min over days d of A_d\n'
              'A_d = average progress of tasks on day d (only days with at least one task).',
              'We look at each day that had at least one task and take the lowest '
                  'daily average. One bad day can pull the whole week down.\n\n'
                  'Example: Monday you averaged 100% across tasks, Tuesday you averaged '
                  '0% on the tasks that day → the week shows 0%, even though Monday was perfect.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBlock(
    ThemeData theme,
    String title,
    String formula,
    String body,
  ) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formula',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                formula,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _SectionCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
