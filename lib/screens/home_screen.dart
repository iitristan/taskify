import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import 'add_todo_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TodoProvider>().initDatabase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text('Task Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          children: [
            _buildDashboardOption(
              icon: Icons.calendar_today,
              label: 'Calendar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              ),
            ),
            _buildDashboardOption(
              icon: Icons.add_circle,
              label: 'Create Task',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTodoScreen(selectedDate: DateTime.now()),
                ),
              ),
            ),
            _buildDashboardOption(
              icon: Icons.category,
              label: 'Categories',
              onTap: () {
                // TODO: Implement category screen navigation
              },
            ),
            _buildDashboardOption(
              icon: Icons.notifications,
              label: 'Reminders',
              onTap: () {
                // TODO: Implement reminders screen navigation
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue[800]),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 