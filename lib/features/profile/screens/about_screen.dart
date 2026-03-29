import 'package:flutter/material.dart';
import 'package:exam_ace/core/constants/app_strings.dart';
import 'package:exam_ace/core/constants/legal_urls.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

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
              'v1.0.2',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'For people preparing for competitive exams (e.g. SSC, UPSC, '
                'banking, railway, state PSCs). Exam Ace is a private planner — '
                'not a government app. You add your own syllabus and data.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DisclaimerAndSourcesCard(
              theme: theme,
              onOpenUrl: (url) => _openLegalUrl(context, url),
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
            if (kPrivacyPolicyUrl.isNotEmpty ||
                kAccountDeletionRequestUrl.isNotEmpty) ...[
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 0,
                children: [
                  if (kPrivacyPolicyUrl.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          _openLegalUrl(context, kPrivacyPolicyUrl),
                      child: const Text('Privacy policy'),
                    ),
                  if (kPrivacyPolicyUrl.isNotEmpty &&
                      kAccountDeletionRequestUrl.isNotEmpty)
                    Text(
                      '·',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (kAccountDeletionRequestUrl.isNotEmpty)
                    TextButton(
                      onPressed: () => _openLegalUrl(
                        context,
                        kAccountDeletionRequestUrl,
                      ),
                      child: const Text('Request data deletion'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openLegalUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Invalid link');
      }
      return;
    }
    try {
      final ok =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showErrorSnackBar(context, 'Could not open link');
      }
    } on Object catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not open link');
      }
    }
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
              'Balanced — harmonic mean',
              'weekRatio = n / sum(1/p_i)\n'
              'p_i = each task’s progress (0.01–1.0); n = number of tasks. '
              'Penalizes extremes and rewards even distribution.',
              'Uses harmonic mean instead of arithmetic mean. Having one task at 10% '
                  'and another at 90% scores lower than both at 50%.\n\n'
                  'Example: tasks at [20%, 80%] → 32% vs [50%, 50%] → 50%. '
                  'Encourages working evenly across all tasks.',
            ),
            Divider(height: 28, color: cs.outlineVariant.withValues(alpha: 0.4)),
            _modeBlock(
              theme,
              'Momentum — recent days matter more',
              'weekRatio = sum(w_i * A_i) / sum(w_i)\n'
              'w_i = e^(i/6) where i is day index (0–6); A_i = daily average. '
              'Exponential weighting favors recent performance.',
              'Monday gets 1.0× weight, Sunday gets 2.7× weight. Building momentum '
                  'through the week is rewarded.\n\n'
                  'Example: improving week [50%, 60%, 70%, 80%, 90%, 95%, 100%] → 84.2%. '
                  'Finishing strong boosts your score.',
            ),
            Divider(height: 28, color: cs.outlineVariant.withValues(alpha: 0.4)),
            _modeBlock(
              theme,
              'Consistent — rewards steady work',
              'weekRatio = avg + (1 - σ) × 0.15\n'
              'avg = mean of daily averages; σ = standard deviation of daily scores. '
              'Lower variance adds up to 15% bonus.',
              'Calculates your average, then adds a consistency bonus based on how '
                  'steady your daily performance is.\n\n'
                  'Example: steady [70%, 72%, 71%, 70%, 73%] gets bonus vs '
                  '[50%, 90%, 50%, 90%, 50%]. Rewards regular, predictable progress.',
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

/// Play policy: visible disclaimer + links to official .gov sources for exam info.
class _DisclaimerAndSourcesCard extends StatelessWidget {
  final ThemeData theme;
  final void Function(String url) onOpenUrl;

  const _DisclaimerAndSourcesCard({
    required this.theme,
    required this.onOpenUrl,
  });

  static const _sources = <(String label, String url)>[
    ('UPSC — upsc.gov.in', 'https://upsc.gov.in'),
    ('SSC — ssc.gov.in', 'https://ssc.gov.in'),
    ('Indian Railways — indianrailways.gov.in', 'https://indianrailways.gov.in'),
    ('National portal — india.gov.in', 'https://www.india.gov.in'),
  ];

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
            Row(
              children: [
                Icon(Icons.gavel_rounded, size: 22, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Disclaimer & official sources',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Exam Ace is not affiliated with any government, exam '
              'commission, or employer. It does not publish official '
              'notifications or rules — only what you enter. For authentic '
              'exam information, use official websites (examples below).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Open official sites',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            ..._sources.map(
              (e) => Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => onOpenUrl(e.$2),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(e.$1),
                ),
              ),
            ),
          ],
        ),
      ),
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
