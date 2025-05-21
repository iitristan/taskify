import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import '../screens/notification_settings_screen.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _toggleEditMode() async {
    if (_isEditing) {
      // Set saving state
      setState(() {
        _isSaving = true;
      });

      try {
        // Save user data to provider
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).updateUserData(name: _nameController.text.trim());

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // Show error feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        // Reset states
        if (mounted) {
          setState(() {
            _isSaving = false;
            _isEditing = false;
          });
        }
      }
    } else {
      // Just enter edit mode
      setState(() {
        _isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(colorScheme),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(userProvider, textTheme, colorScheme),
              const SizedBox(height: 32),
              _buildStatisticsSection(textTheme, colorScheme),
              const SizedBox(height: 32),
              _buildSettingsSection(textTheme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      title: const Text('Profile'),
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      actions: [
        _isSaving
            ? Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
            : IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _toggleEditMode,
            ),
      ],
    );
  }

  Widget _buildProfileHeader(
    UserProvider userProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            child: Icon(Icons.person, size: 60, color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          _isEditing
              ? _buildEditableUserInfo(textTheme)
              : _buildUserInfo(userProvider, textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEditableUserInfo(TextTheme textTheme) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.transparent : colorScheme.surface,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.7),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDarkMode
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
      ),
      child: TextField(
        controller: _nameController,
        textAlign: TextAlign.center,
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : colorScheme.onSurface,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          hintStyle: TextStyle(
            color: (isDarkMode ? Colors.white : colorScheme.onSurface)
                .withOpacity(0.5),
            fontSize: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    UserProvider userProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        userProvider.name,
        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatisticsSection(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Consumer<TodoProvider>(
          builder: (context, todoProvider, child) {
            final totalTasks = todoProvider.todos.length;
            final completedTasks =
                todoProvider.todos.where((todo) => todo.isCompleted).length;
            final pendingTasks = totalTasks - completedTasks;
            final completionRate =
                totalTasks > 0
                    ? (completedTasks / totalTasks * 100).round()
                    : 0;

            return Column(
              children: [
                _buildStatCard(
                  'Total Tasks',
                  totalTasks.toString(),
                  Icons.list_alt,
                  colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Completed',
                  completedTasks.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Pending',
                  pendingTasks.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Completion Rate',
                  '$completionRate%',
                  Icons.analytics,
                  Colors.purple,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildThemeToggle(colorScheme),
                const Divider(),
                _buildSettingsItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification settings',
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildSettingsItem(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  trailing: const Text('v1.0.0'),
                  colorScheme: colorScheme,
                  onTap: () => _showAboutDialog(context, colorScheme),
                ),
                const Divider(),
                _buildSettingsItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  colorScheme: colorScheme,
                  onTap: () => _showLogoutConfirmation(context, colorScheme),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(ColorScheme colorScheme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Toggle between light and dark theme'),
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context, ColorScheme colorScheme) {
    showAboutDialog(
      context: context,
      applicationName: 'Taskify',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.check_circle_outline,
        color: colorScheme.primary,
        size: 40,
      ),
      children: const [
        Text(
          'Taskify is a task management app designed to help you organize your daily tasks efficiently.',
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
