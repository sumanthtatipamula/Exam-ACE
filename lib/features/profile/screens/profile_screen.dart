import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exam_ace/core/theme/theme_provider.dart';
import 'package:exam_ace/core/services/image_upload_service.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/profile/widgets/change_password_sheet.dart';

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
    } on Exception catch (e) {
      if (mounted) showErrorSnackBar(context, 'Upload failed: $e');
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
      await user.updatePhotoURL(null);
      await user.reload();
      if (mounted) {
        setState(() {});
        showSuccessSnackBar(context, 'Profile photo removed');
      }
    } on Exception catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not remove photo: $e');
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
        showErrorSnackBar(
          context,
          friendlyAuthError(
            e is Exception ? e : Exception(e.toString()),
          ),
        );
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
        showErrorSnackBar(
          context,
          friendlyAuthError(
            e is Exception ? e : Exception(e.toString()),
          ),
        );
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
    final isEmailUser = authService.isEmailPasswordUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (!isEmailUser)
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
          const SizedBox(height: 28),
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
          const SizedBox(height: 16),
          if (isEmailUser)
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
          const _ThemeToggleTile(),
          _ProfileTile(
            icon: Icons.info_outlined,
            title: 'About',
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Data & account',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The actions below are permanent and cannot be reversed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
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

  String _providerLabel(User? user) {
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? {};
    if (providers.contains('google.com')) return 'Signed in with Google';
    if (providers.contains('facebook.com')) return 'Signed in with Facebook';
    return 'OAuth';
  }
}

// --- Extracted widgets ---

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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
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
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: Icon(Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      margin: const EdgeInsets.only(bottom: 8),
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
      margin: const EdgeInsets.only(bottom: 8),
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
