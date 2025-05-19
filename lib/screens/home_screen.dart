import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/category_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import 'add_todo_screen.dart';
import 'calendar_screen.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';

class FilterOption {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final Color color;

  FilterOption({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.color,
  });
}

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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initProviders();
  }

  void _initAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  void _initProviders() {
    Future.microtask(() {
      context.read<TodoProvider>().initDatabase();
      context.read<CategoryProvider>().initDatabase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToAddTodo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(selectedDate: DateTime.now()),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
  }

  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
    );
  }

  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemindersScreen()),
    );
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
                  _buildHeader(textTheme, colorScheme),
                  const SizedBox(height: 24),
                  _buildSearchBar(colorScheme),
                  const SizedBox(height: 32),
                  _buildQuickActionsSection(textTheme, colorScheme),
                  const SizedBox(height: 32),
                  _buildMyDaySection(today, textTheme, colorScheme),
                  const SizedBox(height: 24),
                  _buildStatsCard(colorScheme, textTheme),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTodo,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
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
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _navigateToProfile,
            icon: Icon(Icons.person, color: colorScheme.primary),
            iconSize: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
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
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onTap: _navigateToCalendar,
            ),
            _buildDashboardOption(
              icon: Icons.add_circle,
              label: 'Create Task',
              color: colorScheme.secondary,
              onTap: _navigateToAddTodo,
            ),
            _buildDashboardOption(
              icon: Icons.category,
              label: 'Categories',
              color: colorScheme.tertiary,
              onTap: _navigateToCategories,
            ),
            _buildDashboardOption(
              icon: Icons.notifications,
              label: 'Reminders',
              color: colorScheme.error,
              onTap: _navigateToReminders,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyDaySection(
    String today,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
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
            _buildFilterButton(colorScheme),
          ],
        ),
        const SizedBox(height: 16),
        _buildTasksList(colorScheme, textTheme),
      ],
    );
  }

  Widget _buildFilterButton(ColorScheme colorScheme) {
    final hasFilters = _hasActiveFilters();

    return TextButton.icon(
      onPressed: () => _showFilterDialog(context),
      icon: Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
      label: Text(
        hasFilters ? 'Filtered' : 'Filter',
        style: TextStyle(color: colorScheme.primary),
      ),
      style: TextButton.styleFrom(
        backgroundColor:
            hasFilters
                ? colorScheme.primary.withOpacity(0.2)
                : colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTasksList(ColorScheme colorScheme, TextTheme textTheme) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        var filteredTasks = _getFilteredTasks(todoProvider);

        if (filteredTasks.isEmpty) {
          return _buildEmptyStateCard(colorScheme, textTheme);
        }

        return Card(
          color: colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.onSurface.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  _searchQuery.isNotEmpty
                      ? _buildGroupedTasksList(
                        filteredTasks,
                        colorScheme,
                        textTheme,
                      )
                      : filteredTasks.map((todo) {
                        Color priorityColor = _getPriorityColor(todo.priority);
                        return _buildTaskTile(todo, priorityColor);
                      }).toList(),
            ),
          ),
        );
      },
    );
  }

  List<Todo> _getFilteredTasks(TodoProvider todoProvider) {
    // Get all tasks if searching, otherwise just today's tasks
    var tasks =
        _searchQuery.isNotEmpty
            ? todoProvider.todos
            : todoProvider.getTodosForDate(DateTime.now());

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      tasks =
          tasks.where((todo) {
            final titleMatch = todo.title.toLowerCase().contains(_searchQuery);
            final descriptionMatch = todo.description.toLowerCase().contains(
              _searchQuery,
            );
            final categoryMatch = todo.categoryName.toLowerCase().contains(
              _searchQuery,
            );
            final dateMatch = DateFormat(
              'MMMM d, y',
            ).format(todo.dueDate).toLowerCase().contains(_searchQuery);
            return titleMatch || descriptionMatch || categoryMatch || dateMatch;
          }).toList();

      // Sort by due date
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    // Apply priority filter
    if (_priorityFilter != null) {
      tasks = tasks.where((todo) => todo.priority == _priorityFilter).toList();
    }

    // Apply completion filter
    if (_completionFilter != null) {
      tasks =
          tasks.where((todo) => todo.isCompleted == _completionFilter).toList();
    }

    // Apply category filter
    if (_categoryFilter != null) {
      tasks =
          tasks.where((todo) => todo.categoryId == _categoryFilter).toList();
    }

    return tasks;
  }

  List<Widget> _buildGroupedTasksList(
    List<Todo> tasks,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Map<String, List<Todo>> groupedTasks = {};
    for (var task in tasks) {
      final dateKey = DateFormat('MMMM d, y').format(task.dueDate);
      if (!groupedTasks.containsKey(dateKey)) {
        groupedTasks[dateKey] = [];
      }
      groupedTasks[dateKey]!.add(task);
    }

    List<Widget> widgets = [];
    groupedTasks.forEach((date, dateTasks) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 13,
                color: colorScheme.primary.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: colorScheme.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      );

      // Sort tasks by time
      dateTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      widgets.addAll(
        dateTasks.map((todo) {
          Color priorityColor = _getPriorityColor(todo.priority);
          return _buildTaskTile(todo, priorityColor);
        }),
      );

      if (date != groupedTasks.keys.last) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.onSurface.withOpacity(0.05),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'High':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildEmptyStateCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      color: colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.check_circle_outline,
              size: 48,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching tasks found'
                  : 'No Tasks Today',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Enjoy your day off!',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final allTasks = todoProvider.todos.length;
        final completedTasks =
            todoProvider.todos.where((todo) => todo.isCompleted).length;
        final completionPercentage =
            allTasks > 0 ? (completedTasks / allTasks * 100).round() : 0;

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

  Widget _buildTaskTile(Todo todo, Color priorityColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (bool? value) {
                      final updatedTodo = todo.copyWith(
                        isCompleted: value ?? false,
                      );
                      context.read<TodoProvider>().updateTodo(updatedTodo);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(color: priorityColor, width: 1.5),
                    activeColor: priorityColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Task Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            height: 1.3,
                            color: todo.isCompleted
                                ? colorScheme.onSurface.withOpacity(0.3)
                                : colorScheme.onSurface,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('h:mm a').format(todo.dueDate),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (todo.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      todo.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.3,
                        color: todo.isCompleted
                            ? colorScheme.onSurface.withOpacity(0.3)
                            : colorScheme.onSurface.withOpacity(0.6),
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                  if (todo.categoryName != 'Default') ...[
                    const SizedBox(height: 4),
                    Text(
                      todo.categoryName,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.2,
                        color: priorityColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Menu
            SizedBox(
              width: 32,
              height: double.infinity,
              child: IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withOpacity(0.3),
                  size: 18,
                ),
                onPressed: () => _showTaskMenu(todo, priorityColor),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                alignment: Alignment.centerRight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskMenu(Todo todo, Color priorityColor) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.edit, color: colorScheme.primary),
                    title: Text(
                      'Edit Task',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    onTap: () {
                      Navigator.pop(context);
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
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: colorScheme.error),
                    title: Text(
                      'Delete Task',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(todo);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(Todo todo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${todo.title}"?'),
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
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Tasks',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFilterSection(
                        title: 'Filter by Priority:',
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        setDialogState: setDialogState,
                        options: [
                          FilterOption(
                            label: 'All',
                            isSelected: _priorityFilter == null,
                            onSelected: (selected) {
                              setDialogState(() => _priorityFilter = null);
                            },
                            color: colorScheme.primary,
                          ),
                          FilterOption(
                            label: 'High',
                            isSelected: _priorityFilter == 'High',
                            onSelected: (selected) {
                              setDialogState(
                                () =>
                                    _priorityFilter = selected ? 'High' : null,
                              );
                            },
                            color: Colors.red,
                          ),
                          FilterOption(
                            label: 'Medium',
                            isSelected: _priorityFilter == 'Medium',
                            onSelected: (selected) {
                              setDialogState(
                                () =>
                                    _priorityFilter =
                                        selected ? 'Medium' : null,
                              );
                            },
                            color: Colors.orange,
                          ),
                          FilterOption(
                            label: 'Low',
                            isSelected: _priorityFilter == 'Low',
                            onSelected: (selected) {
                              setDialogState(
                                () => _priorityFilter = selected ? 'Low' : null,
                              );
                            },
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFilterSection(
                        title: 'Filter by Status:',
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        setDialogState: setDialogState,
                        options: [
                          FilterOption(
                            label: 'All',
                            isSelected: _completionFilter == null,
                            onSelected: (selected) {
                              setDialogState(() => _completionFilter = null);
                            },
                            color: colorScheme.primary,
                          ),
                          FilterOption(
                            label: 'Completed',
                            isSelected: _completionFilter == true,
                            onSelected: (selected) {
                              setDialogState(
                                () =>
                                    _completionFilter = selected ? true : null,
                              );
                            },
                            color: Colors.green,
                          ),
                          FilterOption(
                            label: 'Pending',
                            isSelected: _completionFilter == false,
                            onSelected: (selected) {
                              setDialogState(
                                () =>
                                    _completionFilter = selected ? false : null,
                              );
                            },
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          final categories = categoryProvider.categories;
                          return _buildFilterSection(
                            title: 'Filter by Category:',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            setDialogState: setDialogState,
                            options: [
                              FilterOption(
                                label: 'All',
                                isSelected: _categoryFilter == null,
                                onSelected: (selected) {
                                  setDialogState(() => _categoryFilter = null);
                                },
                                color: colorScheme.primary,
                              ),
                              ...categories.map(
                                (category) => FilterOption(
                                  label: category.name,
                                  isSelected: _categoryFilter == category.id,
                                  onSelected: (selected) {
                                    setDialogState(
                                      () =>
                                          _categoryFilter =
                                              selected ? category.id : null,
                                    );
                                  },
                                  color: category.color,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _priorityFilter = null;
                                _completionFilter = null;
                                _categoryFilter = null;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Clear Filters',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required StateSetter setDialogState,
    required List<FilterOption> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options
                  .map(
                    (option) => _buildFilterChip(
                      option: option,
                      colorScheme: colorScheme,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required FilterOption option,
    required ColorScheme colorScheme,
  }) {
    return FilterChip(
      label: Text(
        option.label,
        style: TextStyle(
          color: option.isSelected ? Colors.white : colorScheme.onSurface,
          fontWeight: option.isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: option.isSelected,
      onSelected: option.onSelected,
      backgroundColor: option.color.withOpacity(0.1),
      selectedColor: option.color,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              option.isSelected
                  ? Colors.transparent
                  : option.color.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _priorityFilter != null ||
        _completionFilter != null ||
        _categoryFilter != null;
  }
}
