import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

/// Theme mode notifier
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Theme mode provider
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // Profile Section
          authState.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return _buildProfileSection(context, user);
            },
          ),

          const Divider(),

          // Subscription Section
          _buildSectionHeader(context, 'Subscription'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.star,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Free Plan'),
            subtitle: const Text('3 mind maps • 10 AI uses/month'),
            trailing: FilledButton(
              onPressed: () => _showPaywall(context),
              child: const Text('Upgrade'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('AI Usage'),
            subtitle: const Text('5 of 10 uses remaining'),
            trailing: Text(
              '50%',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),

          const Divider(),

          // Support Section
          _buildSectionHeader(context, 'Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help Center'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Help Center...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showFeedbackDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Idea Weaver AI',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.hub_outlined,
                  size: 48,
                  color: colorScheme.primary,
                ),
                children: [
                  const Text(
                    'AI-powered mind mapping app for brainstorming and idea generation.',
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // Legal Section
          _buildSectionHeader(context, 'Legal'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(),

          // Sign Out
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () => _showSignOutDialog(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            child: user.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      user.photoURL!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 32,
                    color: colorScheme.onPrimaryContainer,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  user.email ?? '',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              _showEditProfileDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  Icons.star,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Upgrade to Pro',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock all features and supercharge your creativity',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildProFeature(
                    context, Icons.all_inclusive, 'Unlimited mind maps'),
                _buildProFeature(
                    context, Icons.auto_awesome, 'Unlimited AI suggestions'),
                _buildProFeature(
                    context, Icons.people, 'Real-time collaboration'),
                _buildProFeature(
                    context, Icons.file_download, 'All export formats'),
                _buildProFeature(context, Icons.cloud, 'Cloud sync & backup'),
                const SizedBox(height: 32),
                // Monthly option
                _buildPricingCard(
                  context,
                  title: 'Monthly',
                  price: '¥800',
                  period: '/month',
                  isPopular: false,
                ),
                const SizedBox(height: 12),
                // Yearly option
                _buildPricingCard(
                  context,
                  title: 'Yearly',
                  price: '¥8,000',
                  period: '/year',
                  isPopular: true,
                  savings: 'Save 17%',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment processing... (Mock)'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Subscribe Now'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cancel anytime. Terms apply.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProFeature(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required bool isPopular,
    String? savings,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? colorScheme.primary : colorScheme.outline,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'POPULAR',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (savings != null)
                  Text(
                    savings,
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
          Text(
            price,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            period,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Your feedback',
            hintText: 'Tell us how we can improve...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
