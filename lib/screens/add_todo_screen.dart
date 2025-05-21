import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';

class AddTodoScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Todo? todo;

  const AddTodoScreen({super.key, required this.selectedDate, this.todo});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  late String _priority;
  late AnimationController _animationController;
  late Animation<double> _animation;

  String? _selectedCategoryId;
  String _selectedCategoryName = 'Default';
  bool _isEditing = false;
  bool _isRecurring = false;
  String? _recurrenceType;
  DateTime? _recurrenceEndDate;
  bool _addReminder = false;
  DateTime? _reminderDateTime;

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _recurrenceTypes = ['daily', 'weekly', 'monthly'];

  // Add mapping for display values
  String _getDisplayRecurrenceType(String? type) {
    if (type == null) return '';
    return type[0].toUpperCase() + type.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _priority = 'Medium';
    _isEditing = widget.todo != null;
    _reminderDateTime = _selectedDate;

    _initializeFormData();
    _setupAnimation();

    // Initialize category provider
    Future.microtask(() => context.read<CategoryProvider>().initDatabase());
  }

  void _initializeFormData() {
    if (_isEditing && widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _selectedDate = widget.todo!.dueDate;
      _priority = widget.todo!.priority;
      _selectedCategoryId = widget.todo!.categoryId;
      _selectedCategoryName = widget.todo!.categoryName;
      _isRecurring = widget.todo!.isRecurring;
      _recurrenceType = widget.todo!.recurrenceType;
      _recurrenceEndDate = widget.todo!.recurrenceEndDate;
    }
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final now = DateTime.now();
      final defaultDate = now;
      final oldDueDate = _selectedDate;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: defaultDate,
        firstDate: now,
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme,
              datePickerTheme: DatePickerThemeData(
                surfaceTintColor: Colors.transparent,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDate.isAfter(now) ? _selectedDate : now),
        );

        if (pickedTime != null) {
          final selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (selectedDateTime.isBefore(now)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Due date/time cannot be in the past.')),
            );
            return;
          }
          setState(() {
            _selectedDate = selectedDateTime;
            // If reminder is enabled and reminder date matched old due date, update reminder date to new due date
            if (_addReminder && (_reminderDateTime == null || _reminderDateTime == oldDueDate)) {
              _reminderDateTime = selectedDateTime;
            }
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _selectRecurrenceEndDate(BuildContext context) async {
    // Force a default date 30 days from now to avoid the June 20 issue
    final defaultDate = DateTime.now().add(const Duration(days: 30));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: defaultDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
            // Reset the calendar's internal state
            datePickerTheme: DatePickerThemeData(
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  void _saveTodo() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Validate inputs
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (_isRecurring && _recurrenceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recurrence type')),
      );
      return;
    }

    if (_isRecurring && _recurrenceEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an end date for recurrence')),
      );
      return;
    }

    if (_isEditing && widget.todo != null) {
      final updatedTodo = Todo(
        id: widget.todo!.id,
        userId: context.read<AuthProvider>().user!.id,
        title: title,
        description: description,
        dueDate: _selectedDate,
        priority: _priority,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        isCompleted: widget.todo!.isCompleted,
        isRecurring: _isRecurring,
        recurrenceType: _recurrenceType,
        recurrenceEndDate: _recurrenceEndDate,
      );
      await context.read<TodoProvider>().updateTodo(updatedTodo);
    } else {
      final todo = Todo(
        userId: context.read<AuthProvider>().user!.id,
        title: title,
        description: description,
        dueDate: _selectedDate,
        priority: _priority,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        isRecurring: _isRecurring,
        recurrenceType: _recurrenceType,
        recurrenceEndDate: _recurrenceEndDate,
      );
      
      // Add the todo first
      final todoProvider = context.read<TodoProvider>();
      final newTodo = await todoProvider.addTodo(todo);
      
      if (newTodo != null && _addReminder && _reminderDateTime != null) {
        final reminderProvider = context.read<ReminderProvider>();
        await reminderProvider.addReminder(
          Reminder(
            todoId: newTodo.id!,
            reminderTime: _reminderDateTime!,
            isRepeating: false,
            repeatType: 'none',
          ),
        );
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _buildAppBar(colorScheme),
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormField(
                  title: 'Task Title',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: _buildTitleField(colorScheme),
                ),

                _buildFormField(
                  title: 'Description',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: _buildDescriptionField(colorScheme),
                ),

                _buildFormField(
                  title: 'Due Date',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: _buildDateSelector(textTheme, colorScheme),
                ),

                _buildFormField(
                  title: 'Category',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: _buildCategorySelector(textTheme, colorScheme),
                ),

                _buildFormField(
                  title: 'Priority',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: _buildPrioritySelector(textTheme, colorScheme),
                ),

                _buildFormField(
                  title: 'Recurrence',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Recurring Task',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                            if (!value) {
                              _recurrenceType = null;
                              _recurrenceEndDate = null;
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _recurrenceType,
                              hint: Text(
                                'Select Recurrence Type',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.primary,
                              ),
                              isExpanded: true,
                              dropdownColor: colorScheme.surface,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              items:
                                  _recurrenceTypes.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        _getDisplayRecurrenceType(value),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _recurrenceType = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _selectRecurrenceEndDate(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _recurrenceEndDate != null
                                      ? DateFormat(
                                        'MMM d, y',
                                      ).format(_recurrenceEndDate!)
                                      : 'Select End Date',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color:
                                        _recurrenceEndDate != null
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurface.withOpacity(
                                              0.7,
                                            ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                _buildFormField(
                  title: 'Reminder',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: Text('Add Reminder', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                        value: _addReminder,
                        onChanged: (value) {
                          setState(() {
                            _addReminder = value;
                            if (value && _reminderDateTime == null) {
                              _reminderDateTime = _selectedDate;
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                      if (_addReminder)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Reminder Date & Time'),
                          subtitle: Text(
                            DateFormat('EEE, MMM d, yyyy - h:mm a').format(_reminderDateTime ?? _selectedDate),
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _reminderDateTime ?? _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? _selectedDate),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  _reminderDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                _buildSubmitButton(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        _isEditing ? 'Edit Task' : 'Add Task',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }

  Widget _buildFormField({
    required String title,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildTitleField(ColorScheme colorScheme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.title, color: colorScheme.primary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter task title',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 4),
                filled: false,
              ),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w500,
              ),
              textAlignVertical: TextAlignVertical.center,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(ColorScheme colorScheme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.description,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _descriptionController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Enter task description',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 4),
                filled: false,
              ),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
              textAlignVertical: TextAlignVertical.center,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  '${DateFormat('MMM d, y').format(_selectedDate)} at ${DateFormat('h:mm a').format(_selectedDate)}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(TextTheme textTheme, ColorScheme colorScheme) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return _buildDefaultCategoryItem(textTheme, colorScheme);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              hint: Text(
                'Select Category',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
              isExpanded: true,
              dropdownColor: colorScheme.surface,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              items:
                  categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id.toString(),
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 20),
                          const SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedCategoryId = value;
                  if (value != null) {
                    final category = categories.firstWhere(
                      (cat) => cat.id.toString() == value,
                    );
                    _selectedCategoryName = category.name;
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultCategoryItem(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.category, color: colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            'Default',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _priority,
          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          items:
              _priorities.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(value),
                        color: _getPriorityColor(value),
                      ),
                      const SizedBox(width: 16),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _priority = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    return Icons.flag;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return ElevatedButton.icon(
      onPressed: _saveTodo,
      icon: Icon(_isEditing ? Icons.save : Icons.add_task),
      label: Text(_isEditing ? 'Update Task' : 'Add Task'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
