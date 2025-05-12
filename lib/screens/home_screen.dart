import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../providers/user_provider.dart';
import '../models/todo.dart';
import 'add_todo_screen.dart';
import 'calendar_screen.dart';
import 'categories_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Filter variables
  String? _priorityFilter;
  bool? _completionFilter;
  int? _categoryFilter;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    Future.microtask(() {
      context.read<TodoProvider>().initDatabase();
      context.read<CategoryProvider>().initDatabase();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar with Profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onBackground.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              return Text(
                                userProvider.name,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onBackground,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child:
                                userProvider.profileImagePath.isNotEmpty
                                    ? GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const ProfileScreen(),
                                            ),
                                          ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundImage: FileImage(
                                          File(userProvider.profileImagePath),
                                        ),
                                        backgroundColor: Colors.transparent,
                                      ),
                                    )
                                    : IconButton(
                                      onPressed:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const ProfileScreen(),
                                            ),
                                          ),
                                      icon: Icon(
                                        Icons.person,
                                        color: colorScheme.primary,
                                      ),
                                      iconSize: 28,
                                    ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dashboard Grid
                  Text(
                    'Quick Actions',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildDashboardOption(
                        icon: Icons.calendar_today,
                        label: 'Calendar',
                        color: colorScheme.primary,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CalendarScreen(),
                              ),
                            ),
                      ),
                      _buildDashboardOption(
                        icon: Icons.add_circle,
                        label: 'Create Task',
                        color: colorScheme.secondary,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddTodoScreen(
                                      selectedDate: DateTime.now(),
                                    ),
                              ),
                            ),
                      ),
                      _buildDashboardOption(
                        icon: Icons.category,
                        label: 'Categories',
                        color: colorScheme.tertiary,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            ),
                      ),
                      _buildDashboardOption(
                        icon: Icons.notifications,
                        label: 'Reminders',
                        color: colorScheme.error,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RemindersScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // My Day Segment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Day',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          Text(
                            today,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _showFilterDialog(context),
                        icon: Icon(
                          Icons.filter_list,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        label: Text(
                          _hasActiveFilters() ? 'Filtered' : 'Filter',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              _hasActiveFilters()
                                  ? colorScheme.primary.withOpacity(0.2)
                                  : colorScheme.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tasks for today
                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      var todayTasks = todoProvider.getTodosForDate(
                        DateTime.now(),
                      );

                      // Apply filters
                      if (_priorityFilter != null) {
                        todayTasks =
                            todayTasks
                                .where(
                                  (todo) => todo.priority == _priorityFilter,
                                )
                                .toList();
                      }

                      if (_completionFilter != null) {
                        todayTasks =
                            todayTasks
                                .where(
                                  (todo) =>
                                      todo.isCompleted == _completionFilter,
                                )
                                .toList();
                      }

                      if (_categoryFilter != null) {
                        todayTasks =
                            todayTasks
                                .where(
                                  (todo) => todo.categoryId == _categoryFilter,
                                )
                                .toList();
                      }

                      if (todayTasks.isEmpty) {
                        return Card(
                          color: colorScheme.surface,
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 48,
                                  color: colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Tasks Today',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enjoy your day off!',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Card(
                        color: colorScheme.surface,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children:
                                todayTasks.map((todo) {
                                  Color priorityColor;
                                  switch (todo.priority) {
                                    case 'Low':
                                      priorityColor = Colors.green;
                                      break;
                                    case 'High':
                                      priorityColor = Colors.red;
                                      break;
                                    default:
                                      priorityColor = Colors.orange;
                                  }

                                  return Column(
                                    children: [
                                      _buildTaskTile(todo, priorityColor),
                                      if (todayTasks.last != todo)
                                        const Divider(height: 24),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Stats Card
                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      final allTasks = todoProvider.todos.length;
                      final completedTasks =
                          todoProvider.todos
                              .where((todo) => todo.isCompleted)
                              .length;
                      final completionPercentage =
                          allTasks > 0
                              ? (completedTasks / allTasks * 100).round()
                              : 0;

                      return Card(
                        color: colorScheme.primary,
                        elevation: 8,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.insights,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Weekly Progress',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$completedTasks of $allTasks tasks completed',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Text(
                                  '$completionPercentage%',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddTodoScreen(selectedDate: DateTime.now()),
              ),
            ),
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildDashboardOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTile(Todo todo, Color accentColor) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
            context.read<TodoProvider>().updateTodo(updatedTodo);
          },
          child: Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor, width: 2),
            ),
            child:
                todo.isCompleted
                    ? Icon(Icons.check, color: accentColor, size: 16)
                    : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  decoration:
                      todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                ),
              ),
              Text(
                todo.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  decoration:
                      todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                ),
              ),
              if (todo.categoryName != 'Default')
                Text(
                  todo.categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: accentColor),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddTodoScreen(
                          selectedDate: todo.dueDate,
                          todo: todo,
                        ),
                  ),
                );
                break;
              case 'delete':
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: Text(
                          'Are you sure you want to delete "${todo.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.read<TodoProvider>().deleteTodo(todo.id!);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  // Show filter dialog
  void _showFilterDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Filter Tasks'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority Filter
                      const Text(
                        'Filter by Priority:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _priorityFilter == null,
                            onSelected: (selected) {
                              setDialogState(() {
                                _priorityFilter = null;
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('High'),
                            selected: _priorityFilter == 'High',
                            onSelected: (selected) {
                              setDialogState(() {
                                _priorityFilter = selected ? 'High' : null;
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Medium'),
                            selected: _priorityFilter == 'Medium',
                            onSelected: (selected) {
                              setDialogState(() {
                                _priorityFilter = selected ? 'Medium' : null;
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Low'),
                            selected: _priorityFilter == 'Low',
                            onSelected: (selected) {
                              setDialogState(() {
                                _priorityFilter = selected ? 'Low' : null;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Completion Status Filter
                      const Text(
                        'Filter by Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _completionFilter == null,
                            onSelected: (selected) {
                              setDialogState(() {
                                _completionFilter = null;
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Completed'),
                            selected: _completionFilter == true,
                            onSelected: (selected) {
                              setDialogState(() {
                                _completionFilter = selected ? true : null;
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Pending'),
                            selected: _completionFilter == false,
                            onSelected: (selected) {
                              setDialogState(() {
                                _completionFilter = selected ? false : null;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Category Filter
                      const Text(
                        'Filter by Category:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          final categories = categoryProvider.categories;

                          return Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _categoryFilter == null,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    _categoryFilter = null;
                                    _categoryName = null;
                                  });
                                },
                              ),
                              ...categories.map((category) {
                                return FilterChip(
                                  label: Text(category.name),
                                  selected: _categoryFilter == category.id,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      _categoryFilter =
                                          selected ? category.id : null;
                                      _categoryName =
                                          selected ? category.name : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _priorityFilter = null;
                        _completionFilter = null;
                        _categoryFilter = null;
                        _categoryName = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Clear Filters'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          ),
    );
  }

  bool _hasActiveFilters() {
    return _priorityFilter != null ||
        _completionFilter != null ||
        _categoryFilter != null;
  }
}
