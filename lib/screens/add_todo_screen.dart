import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';

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

  int? _selectedCategoryId;
  String _selectedCategoryName = 'Default';
  bool _isEditing = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _priority = 'Medium';
    _isEditing = widget.todo != null;

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
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(
              context,
            ).copyWith(colorScheme: Theme.of(context).colorScheme),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedDate = picked;
          debugPrint('Date selected: ${_selectedDate.toString()}');
        });
      }
    } catch (e) {
      debugPrint('Error selecting date: $e');
    }
  }

  void _saveTodo() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Validate inputs
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (_isEditing && widget.todo != null) {
      final updatedTodo = Todo(
        id: widget.todo!.id,
        title: title,
        description: description,
        dueDate: _selectedDate,
        priority: _priority,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        isCompleted: widget.todo!.isCompleted,
      );
      context.read<TodoProvider>().updateTodo(updatedTodo);
    } else {
      final todo = Todo(
        title: title,
        description: description,
        dueDate: _selectedDate,
        priority: _priority,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
      );
      context.read<TodoProvider>().addTodo(todo);
    }
    Navigator.pop(context);
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
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            Icon(Icons.calendar_today, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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
            child: DropdownButton<int>(
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
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 20),
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
