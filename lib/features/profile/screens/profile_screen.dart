import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exam_ace/core/theme/app_color_preset.dart';
import 'package:exam_ace/core/theme/color_preset_provider.dart';
import 'package:exam_ace/core/theme/theme_provider.dart';
import 'package:exam_ace/core/services/image_upload_service.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/core/constants/about_sections.dart';
import 'package:exam_ace/core/settings/metric_formula_mode.dart';
import 'package:exam_ace/core/settings/metric_formula_provider.dart';
import 'package:exam_ace/core/settings/syllabus_sort_mode.dart';
import 'package:exam_ace/core/settings/home_streak_badge_provider.dart';
import 'package:exam_ace/core/settings/home_week_stats_provider.dart';
import 'package:exam_ace/core/settings/syllabus_sort_provider.dart';
import 'package:exam_ace/core/constants/legal_urls.dart';
import 'package:exam_ace/features/profile/widgets/change_password_sheet.dart';
import 'package:exam_ace/features/profile/widgets/syllabus_sort_sheet.dart';
import 'package:exam_ace/features/onboarding/screens/onboarding_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;
  bool _destructiveBusy = false;

  Future<void> _showPhotoActions({required bool hasPhoto}) async {
    var removeRequested = false;
    final source = await showModalBottomSheet<ImageSource?>(
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
              if (hasPhoto) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.hide_image_outlined,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  title: Text(
                    'Remove profile photo',
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    removeRequested = true;
                    Navigator.of(ctx).pop(null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (removeRequested) {
      await _removePhoto();
      return;
    }

    if (source == null) return;

    final file = await ImageUploadService.pickImage(source: source);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ImageUploadService.uploadProfilePhoto(file);
      final auth = ref.read(authServiceProvider);
      await auth.currentUser?.updatePhotoURL(url);
      await auth.currentUser?.reload();
      if (mounted) {
        setState(() {});
        showSuccessSnackBar(context, 'Profile photo updated');
      }
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          userFacingError(
            e,
            debugPrefix: 'Upload photo',
            releaseMessage: 'Could not upload photo. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your account will use the default avatar until you add a new photo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;
      final oldUrl = user.photoURL;
      await user.updatePhotoURL(null);
      await user.reload();
      if (oldUrl != null) {
        await ImageUploadService.deleteFirebaseStorageDownloadUrl(oldUrl);
      }
      if (mounted) {
        setState(() {});
        showSuccessSnackBar(context, 'Profile photo removed');
      }
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          userFacingError(
            e,
            debugPrefix: 'Remove photo',
            releaseMessage: 'Could not remove photo. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<bool?> _showDangerConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _onClearAllData() async {
    final ok = await _showDangerConfirmDialog(
      title: 'Clear all data?',
      body:
          'This permanently deletes all your tasks, subjects, progress, mock '
          'tests, and uploaded files from our servers. Your sign-in account '
          'stays active.\n\n'
          'This action cannot be undone.',
      confirmLabel: 'Clear all data',
    );
    if (ok != true || !mounted) return;

    setState(() => _destructiveBusy = true);
    try {
      final uid = ref.read(authServiceProvider).currentUid;
      if (uid == null) throw StateError('Not signed in');
      await ref.read(userDataCleanupServiceProvider).deleteAllDataForUser(uid);
      if (mounted) {
        showSuccessSnackBar(context, 'All data cleared');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, friendlyAuthError(e));
      }
    } finally {
      if (mounted) setState(() => _destructiveBusy = false);
    }
  }

  Future<void> _onDeleteAccount() async {
    final ok = await _showDangerConfirmDialog(
      title: 'Delete account?',
      body:
          'This permanently deletes your account and every piece of data '
          'associated with it. You will be signed out immediately.\n\n'
          'This action cannot be reversed.',
      confirmLabel: 'Delete account',
    );
    if (ok != true || !mounted) return;

    setState(() => _destructiveBusy = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, friendlyAuthError(e));
      }
    } finally {
      if (mounted) setState(() => _destructiveBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final canChangePassword = authService.canChangePassword;

    final topPad = MediaQuery.paddingOf(context).top + 24;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered hero (same as before section-level stretch): photo, name, email.
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfileAvatar(
                photoUrl: photoUrl,
                uploading: _uploadingPhoto,
                onTap: _uploadingPhoto
                    ? null
                    : () => _showPhotoActions(hasPhoto: photoUrl != null),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (!canChangePassword)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _providerLabel(user),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          _ProfileSectionHeader(
            title: 'Account',
            subtitle: canChangePassword
                ? 'Your details, password, and notification settings.'
                : 'Your details and notification settings.',
          ),
          _InfoCard(
            children: [
              _InfoRow(
                  icon: Icons.person_outlined,
                  label: 'Full Name',
                  value: displayName),
              const Divider(height: 1),
              _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email),
            ],
          ),
          const SizedBox(height: 8),
          if (canChangePassword)
            _ProfileTile(
              icon: Icons.lock_reset_rounded,
              title: 'Change Password',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ChangePasswordSheet(),
              ),
            ),
          _ProfileTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 20),
          _ProfileSectionHeader(
            title: 'Appearance',
            subtitle: 'Theme and colour mood.',
          ),
          const _ThemeToggleTile(),
          const _AccentPresetTile(),
          const SizedBox(height: 20),
          _ProfileSectionHeader(
            title: 'Study',
            subtitle:
                'Syllabus order and how your week progress % is calculated.',
          ),
          _ProfileTile(
            icon: Icons.sort_rounded,
            title: 'Chapter & topic order',
            subtitle: ref.watch(syllabusSortProvider).title,
            onTap: () => showSyllabusSortSheet(context, ref),
          ),
          const _MetricFormulaTile(),
          const _StreakBadgeToggleTile(),
          const _WeekStatsToggleTile(),
          const SizedBox(height: 20),
          _ProfileSectionHeader(
            title: 'Help',
            subtitle: 'Walkthrough and support.',
          ),
          _ProfileTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Replay Tutorial',
            subtitle: 'View the onboarding walkthrough again',
            onTap: () async {
              await resetOnboarding();
              if (mounted) context.go('/onboarding');
            },
          ),
          _ProfileTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Report a bug or suggest an improvement',
            onTap: () => _openFeedbackEmail(),
          ),
          const SizedBox(height: 20),
          _ProfileSectionHeader(
            title: 'Data & account',
            subtitle:
                'Privacy and data requests open in your browser. Destructive actions cannot be reversed.',
          ),
          _ProfileAboutNavCard(
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 8),
          _PrivacyAssuranceCard(),
          const SizedBox(height: 8),
          if (kPrivacyPolicyUrl.isNotEmpty) ...[
            _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              subtitle: 'Opens in browser',
              onTap: () {
                _openExternalUrl(kPrivacyPolicyUrl);
              },
            ),
          ],
          if (kAccountDeletionRequestUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.person_remove_outlined,
              title: 'Request data deletion',
              subtitle: 'Account deletion and email request — opens in browser',
              onTap: () => _openExternalUrl(kAccountDeletionRequestUrl),
            ),
          ],
          const SizedBox(height: 12),
          _DangerActionTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear all data',
            subtitle: 'Remove tasks, subjects, and files. Your account stays.',
            enabled: !_destructiveBusy,
            onTap: _onClearAllData,
          ),
          _DangerActionTile(
            icon: Icons.person_off_outlined,
            title: 'Delete account',
            subtitle: 'Remove your account and all data. You will be signed out.',
            enabled: !_destructiveBusy,
            onTap: _onDeleteAccount,
          ),
          if (_destructiveBusy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _destructiveBusy
                  ? null
                  : () async {
                      try {
                        await ref.read(authServiceProvider).signOut();
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackBar(
                            context,
                            'Sign out failed: $e',
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFeedbackEmail() async {
    final user = ref.read(authServiceProvider).currentUser;
    final email = user?.email ?? 'unknown';
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@examace.app',
      queryParameters: {
        'subject': 'Exam Ace Feedback',
        'body': '\n\n---\nApp: Exam Ace\nUser: $email\n',
      },
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        showErrorSnackBar(context, 'Could not open email app');
      }
    } on Object catch (_) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not open email app');
      }
    }
  }

  Future<void> _openExternalUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        showErrorSnackBar(context, 'Invalid link');
      }
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showErrorSnackBar(context, 'Could not open link');
      }
    } on Object catch (_) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not open link');
      }
    }
  }

  String _providerLabel(User? user) {
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? {};
    if (providers.contains('google.com')) return 'Signed in with Google';
    return 'OAuth';
  }
}

// --- Extracted widgets ---

/// Section title + optional subtitle, matching **Data & account** typography.
class _ProfileSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _ProfileSectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final bool uploading;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    const double diameter = 48 * 2;
    return GestureDetector(
      onTap: onTap,
      // Bounded Stack so the camera badge stays on the avatar (wide parents
      // would otherwise stretch the Stack edge-to-edge).
      child: Center(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: uploading
                    ? const CircularProgressIndicator(strokeWidth: 2.5)
                    : photoUrl == null
                        ? Icon(Icons.person_rounded,
                            size: 48, color: colorScheme.onPrimaryContainer)
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 16, color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Single card: section copy + nav affordance (no duplicate title vs header).
class _ProfileAboutNavCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAboutNavCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.info_outlined, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'About',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What this app does and how features work.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _DangerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withValues(alpha: 0.4),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        onTap: enabled ? onTap : null,
        leading: Icon(icon, color: colorScheme.error),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing:
            Icon(Icons.chevron_right_rounded, color: colorScheme.error),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

IconData _metricFormulaIcon(MetricFormulaMode m) => switch (m) {
      MetricFormulaMode.balanced => Icons.balance_rounded,
      MetricFormulaMode.momentum => Icons.trending_up_rounded,
      MetricFormulaMode.consistent => Icons.show_chart_rounded,
    };

Widget _metricFormulaChip({
  required BuildContext context,
  required WidgetRef ref,
  required MetricFormulaMode option,
  required MetricFormulaMode selected,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return SizedBox(
    width: double.infinity,
    child: Tooltip(
      message: option.detailHint,
      child: FilterChip(
        avatar: Icon(
          _metricFormulaIcon(option),
          size: 17,
          color: selected == option
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            option.title,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        selected: selected == option,
        onSelected: (_) =>
            ref.read(metricFormulaProvider.notifier).setMode(option),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.only(left: 2, right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    ),
  );
}

IconData _accentIcon(AppColorPreset p) => switch (p) {
      AppColorPreset.earth => Icons.terrain_rounded,
      AppColorPreset.fire => Icons.local_fire_department_rounded,
      AppColorPreset.forest => Icons.park_rounded,
      AppColorPreset.sky => Icons.cloud_outlined,
    };

Widget _accentMoodChip({
  required BuildContext context,
  required WidgetRef ref,
  required AppColorPreset option,
  required AppColorPreset selected,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return SizedBox(
    width: double.infinity,
    child: FilterChip(
      avatar: Icon(
        _accentIcon(option),
        size: 18,
        color: selected == option
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant,
      ),
      label: Text(option.shortLabel),
      selected: selected == option,
      onSelected: (_) =>
          ref.read(appColorPresetProvider.notifier).setPreset(option),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

class _MetricFormulaTile extends ConsumerWidget {
  const _MetricFormulaTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mode = ref.watch(metricFormulaProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'How your week % is counted',
                    style: theme.textTheme.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: 'Examples and plain-English help in About',
                  child: TextButton(
                    onPressed: () => context.push(
                      '/about?section=${AboutSections.weekScore}',
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Learn more',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              mode.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricFormulaChip(
                    context: context,
                    ref: ref,
                    option: MetricFormulaMode.balanced,
                    selected: mode,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _metricFormulaChip(
                    context: context,
                    ref: ref,
                    option: MetricFormulaMode.momentum,
                    selected: mode,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _metricFormulaChip(
                    context: context,
                    ref: ref,
                    option: MetricFormulaMode.consistent,
                    selected: mode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadgeToggleTile extends ConsumerWidget {
  const _StreakBadgeToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showStreak = ref.watch(homeStreakBadgeProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(
          Icons.local_fire_department_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          'Streak badge',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Show your daily streak next to the week title on Home.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        value: showStreak,
        onChanged: (v) =>
            ref.read(homeStreakBadgeProvider.notifier).setVisible(v),
      ),
    );
  }
}

class _WeekStatsToggleTile extends ConsumerWidget {
  const _WeekStatsToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showWeekStats = ref.watch(homeWeekStatsProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(
          Icons.show_chart_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          'Week stats row',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Show streak, calendar, and week stats chip on Home.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        value: showWeekStats,
        onChanged: (v) =>
            ref.read(homeWeekStatsProvider.notifier).setVisible(v),
      ),
    );
  }
}

class _AccentPresetTile extends ConsumerWidget {
  const _AccentPresetTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final preset = ref.watch(appColorPresetProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Color mood',
                    style: theme.textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Earth · stone & amber · Fire · warm orange · Forest · cream & teal · Sky · cool blue.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _accentMoodChip(
                        context: context,
                        ref: ref,
                        option: AppColorPreset.earth,
                        selected: preset,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _accentMoodChip(
                        context: context,
                        ref: ref,
                        option: AppColorPreset.fire,
                        selected: preset,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _accentMoodChip(
                        context: context,
                        ref: ref,
                        option: AppColorPreset.forest,
                        selected: preset,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _accentMoodChip(
                        context: context,
                        ref: ref,
                        option: AppColorPreset.sky,
                        selected: preset,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends ConsumerWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mode = ref.watch(themeModeProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  switch (mode) {
                    ThemeMode.light => Icons.light_mode_rounded,
                    ThemeMode.dark => Icons.dark_mode_rounded,
                    ThemeMode.system => Icons.brightness_auto_rounded,
                  },
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Appearance',
                    style: theme.textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 16),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (v) =>
                  ref.read(themeModeProvider.notifier).setMode(v.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAssuranceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined,
                size: 22, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your data is secure',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All data is stored securely using Firebase with encryption '
                    'in transit and at rest. We never sell or share your personal '
                    'information. Read our privacy policy for full details.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
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
