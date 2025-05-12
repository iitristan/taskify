import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';

class AddTodoScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Todo? todo; // Optional todo for editing

  const AddTodoScreen({super.key, required this.selectedDate, this.todo});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _priority = 'Medium';
  int? _selectedCategoryId;
  String _selectedCategoryName = 'Default';
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isEditing = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _isEditing = widget.todo != null;

    // Initialize with existing todo data if editing
    if (_isEditing) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _selectedDate = widget.todo!.dueDate;
      _priority = widget.todo!.priority;
      _selectedCategoryId = widget.todo!.categoryId;
      _selectedCategoryName = widget.todo!.categoryName;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Initialize category provider
    Future.microtask(() => context.read<CategoryProvider>().initDatabase());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info dialog
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Field
                  Text(
                    'Task Title',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      prefixIcon: Icon(Icons.title, color: colorScheme.primary),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Description Field
                  Text(
                    'Description',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter task description',
                      prefixIcon: Icon(
                        Icons.description,
                        color: colorScheme.primary,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Due Date Field
                  Text(
                    'Due Date',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                          Icon(
                            Icons.calendar_today,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Selector
                  Text(
                    'Category',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      final categories = categoryProvider.categories;

                      if (categories.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
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
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
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
                          child: DropdownButton<int>(
                            value: _selectedCategoryId,
                            hint: Text(
                              'Select Category',
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
                                categories.map((category) {
                                  return DropdownMenuItem<int>(
                                    value: category.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          category.icon,
                                          color: category.color,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(category.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (int? value) {
                              setState(() {
                                _selectedCategoryId = value;
                                if (value != null) {
                                  final category = categories.firstWhere(
                                    (cat) => cat.id == value,
                                  );
                                  _selectedCategoryName = category.name;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Priority Selector
                  Text(
                    'Priority',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        value: _priority,
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
                            _priorities.map((String value) {
                              Color priorityColor;
                              IconData priorityIcon;

                              switch (value) {
                                case 'Low':
                                  priorityColor = Colors.green;
                                  priorityIcon = Icons.flag;
                                  break;
                                case 'Medium':
                                  priorityColor = Colors.orange;
                                  priorityIcon = Icons.flag;
                                  break;
                                case 'High':
                                  priorityColor = Colors.red;
                                  priorityIcon = Icons.flag;
                                  break;
                                default:
                                  priorityColor = Colors.orange;
                                  priorityIcon = Icons.flag;
                              }

                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(priorityIcon, color: priorityColor),
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
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_isEditing) {
                          // Update existing todo
                          final updatedTodo = Todo(
                            id: widget.todo!.id,
                            title: _titleController.text,
                            description: _descriptionController.text,
                            dueDate: _selectedDate,
                            priority: _priority,
                            categoryId: _selectedCategoryId,
                            categoryName: _selectedCategoryName,
                            isCompleted: widget.todo!.isCompleted,
                          );
                          context.read<TodoProvider>().updateTodo(updatedTodo);
                        } else {
                          // Create new todo
                          final todo = Todo(
                            title: _titleController.text,
                            description: _descriptionController.text,
                            dueDate: _selectedDate,
                            priority: _priority,
                            categoryId: _selectedCategoryId,
                            categoryName: _selectedCategoryName,
                          );
                          context.read<TodoProvider>().addTodo(todo);
                        }
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(_isEditing ? Icons.save : Icons.add_task),
                    label: Text(_isEditing ? 'Update Task' : 'Add Task'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
