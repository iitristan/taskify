import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/todo_provider.dart';
import '../models/reminder.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRepeating = false;
  String _repeatType = 'none';
  int? _selectedTodoId;

  final List<String> _repeatOptions = ['none', 'daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Initialize the database
    Future.microtask(() => context.read<ReminderProvider>().initDatabase());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showAddReminderDialog() {
    _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    _isRepeating = false;
    _repeatType = 'none';
    _selectedTodoId = null;

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final todos = todoProvider.todos;

    if (todos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to create tasks first before setting reminders',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add Reminder'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task dropdown
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Select Task',
                            hintText: 'Choose a task',
                          ),
                          value: _selectedTodoId,
                          items:
                              todos.map((todo) {
                                return DropdownMenuItem<int>(
                                  value: todo.id,
                                  child: Text(
                                    todo.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTodoId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a task';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date and time picker
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Reminder Date & Time'),
                          subtitle: Text(
                            DateFormat(
                              'EEE, MMM d, yyyy - h:mm a',
                            ).format(_selectedDateTime),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDateTime(context),
                        ),
                        const SizedBox(height: 16),

                        // Repeating switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Repeat Reminder'),
                          value: _isRepeating,
                          onChanged: (value) {
                            setState(() {
                              _isRepeating = value;
                              if (!value) {
                                _repeatType = 'none';
                              } else {
                                _repeatType = 'daily';
                              }
                            });
                          },
                        ),

                        // Repeat type dropdown (only visible when repeating is enabled)
                        if (_isRepeating)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Repeat Frequency',
                            ),
                            value: _repeatType,
                            items:
                                _repeatOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option.capitalize()),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _repeatType = value;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final reminderProvider = Provider.of<ReminderProvider>(
                          context,
                          listen: false,
                        );
                        reminderProvider.addReminder(
                          Reminder(
                            todoId: _selectedTodoId!,
                            reminderTime: _selectedDateTime,
                            isRepeating: _isRepeating,
                            repeatType: _repeatType,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<ReminderProvider>(
          builder: (context, reminderProvider, child) {
            final reminders = reminderProvider.reminders;

            if (reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications,
                        size: 60,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Reminders Set',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a new reminder',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final todo = todoProvider.todos.firstWhere(
                      (todo) => todo.id == reminder.todoId,
                      orElse: () => todoProvider.todos.first,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            reminder.isRepeating
                                ? Icons.repeat
                                : Icons.notifications_active,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          todo.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEE, MMM d, yyyy - h:mm a',
                              ).format(reminder.reminderTime),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (reminder.isRepeating)
                              Text(
                                'Repeats ${reminder.repeatType.capitalize()}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: colorScheme.error),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Delete Reminder'),
                                    content: const Text(
                                      'Are you sure you want to delete this reminder?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          reminderProvider.deleteReminder(
                                            reminder.id!,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.error,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
