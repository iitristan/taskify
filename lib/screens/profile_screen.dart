import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${directory.path}/$fileName');
      await savedImage.writeAsBytes(await image.readAsBytes());

      // Update user provider with new image path
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).updateUserData(profileImagePath: savedImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
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
            onPressed: () {
              if (_isEditing) {
                // Save user data to provider
                userProvider.updateUserData(
                  name: _nameController.text,
                  email: _emailController.text,
                );
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.2,
                            ),
                            backgroundImage:
                                userProvider.profileImagePath.isNotEmpty
                                    ? FileImage(
                                      File(userProvider.profileImagePath),
                                    )
                                    : null,
                            child:
                                userProvider.profileImagePath.isEmpty
                                    ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: colorScheme.primary,
                                    )
                                    : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isEditing
                        ? TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your name',
                            border: InputBorder.none,
                          ),
                        )
                        : Text(
                          _nameController.text,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    const SizedBox(height: 4),
                    _isEditing
                        ? TextField(
                          controller: _emailController,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your email',
                            border: InputBorder.none,
                          ),
                        )
                        : Text(
                          _emailController.text,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Statistics
              Text(
                'Statistics',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<TodoProvider>(
                builder: (context, todoProvider, child) {
                  final totalTasks = todoProvider.todos.length;
                  final completedTasks =
                      todoProvider.todos
                          .where((todo) => todo.isCompleted)
                          .length;
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

              const SizedBox(height: 32),

              // Settings
              Text(
                'Settings',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text(
                          'Toggle between light and dark theme',
                        ),
                        value: Provider.of<ThemeProvider>(context).isDarkMode,
                        onChanged: (value) {
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).toggleTheme();
                        },
                        secondary: Icon(
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Notifications'),
                        subtitle: const Text('Manage notification settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to notifications settings
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.help, color: colorScheme.primary),
                        title: const Text('Help & Support'),
                        subtitle: const Text('Get help using the app'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to help screen
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.info, color: colorScheme.primary),
                        title: const Text('About'),
                        subtitle: const Text('App version and information'),
                        trailing: const Text('v1.0.0'),
                        onTap: () {
                          // Show about dialog
                          showAboutDialog(
                            context: context,
                            applicationName: 'Taskify',
                            applicationVersion: '1.0.0',
                            applicationIcon: Icon(
                              Icons.check_circle_outline,
                              color: colorScheme.primary,
                              size: 40,
                            ),
                            children: [
                              const Text(
                                'Taskify is a task management app designed to help you organize your daily tasks efficiently.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
