import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.school_rounded,
                  size: 44, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text('Exam Ace',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 4),
            Text('v1.0.0',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            _SectionCard(
              theme: theme,
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFF66BB6A),
              title: 'Track Your Progress',
              body: 'Break down your syllabus into subjects, chapters, '
                  'and topics. Track completion at every level so you '
                  'always know exactly where you stand.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF42A5F5),
              title: 'Plan Your Days',
              body: 'Schedule tasks and chapters on specific dates. '
                  'Your home screen shows everything planned for today '
                  '— standalone tasks alongside chapters that need attention.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFFFFA726),
              title: 'Weekly Overview',
              body: 'The weekly tracker gives you a visual pulse of your '
                  'consistency. See which days you crushed it and which '
                  'days need improvement at a glance.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.quiz_rounded,
              iconColor: const Color(0xFFEF5350),
              title: 'Mock Test Tracking',
              body: 'Log your mock test scores and link them to specific '
                  'subjects, chapters, or topics. Watch your scores improve '
                  'over time as you study smarter.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.notifications_active_rounded,
              iconColor: theme.colorScheme.primary,
              title: 'Smart Reminders',
              body: 'Morning notifications to start your day with focus, '
                  'and evening reminders to review what you missed. '
                  'Fully customisable to fit your routine.',
            ),
            const SizedBox(height: 12),
            _SectionCard(
              theme: theme,
              icon: Icons.calendar_view_month_rounded,
              iconColor: const Color(0xFF26A69A),
              title: 'Calendar History',
              body: 'Look back at any date to see what you worked on. '
                  'Color-coded dots show your completion status for '
                  'every day — all done, partial, or none.',
            ),
            const SizedBox(height: 28),
            Text(
              'Built for students preparing for competitive exams. '
              'Stay organised, stay consistent, ace your exams.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
