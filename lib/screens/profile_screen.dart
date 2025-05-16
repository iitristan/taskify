import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import '../screens/notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.name;
    _emailController.text = userProvider.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (_isEditing) {
      // Save user data to provider
      Provider.of<UserProvider>(context, listen: false).updateUserData(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
    }
    setState(() {
      _isEditing = !_isEditing;
    });
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
        IconButton(
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
    return Column(
      children: [
        TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: InputBorder.none,
          ),
        ),
        TextField(
          controller: _emailController,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(
    UserProvider userProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          userProvider.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          userProvider.email,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
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
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help using the app',
                  colorScheme: colorScheme,
                  onTap: () {
                    // Navigate to help screen
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
