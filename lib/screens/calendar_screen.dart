import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/todo_provider.dart';
import 'add_todo_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final startOfWeek = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday % 7),
    );
    final daysOfWeek = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );
    final todos = context.watch<TodoProvider>().getTodosForDate(_selectedDay);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendar',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: colorScheme.primary),
            onPressed: () => _pickMonthYear(context),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Month Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy').format(_focusedDay),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _pickMonthYear(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('MMMM').format(_focusedDay),
                              style: textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Week Days Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: List.generate(
                  7,
                  (i) => Expanded(
                    child: Center(
                      child: Text(
                        weekDays[i],
                        style: textTheme.bodyMedium?.copyWith(
                          color:
                              i == 0 || i == 6
                                  ? colorScheme.primary
                                  : colorScheme.onBackground.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Week View
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(7, (i) {
                  final day = daysOfWeek[i];
                  final isToday = isSameDay(day, DateTime.now());
                  final isSelected = isSameDay(day, _selectedDay);
                  final isWeekend =
                      day.weekday == DateTime.saturday ||
                      day.weekday == DateTime.sunday;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                          _focusedDay = day;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : isToday
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('E').format(day)[0],
                              style: textTheme.bodySmall?.copyWith(
                                color:
                                    isSelected
                                        ? colorScheme.onPrimary
                                        : isWeekend
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withOpacity(
                                          0.7,
                                        ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${day.day}',
                              style: textTheme.bodyLarge?.copyWith(
                                color:
                                    isSelected
                                        ? colorScheme.onPrimary
                                        : isToday
                                        ? colorScheme.primary
                                        : colorScheme.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (context
                                .read<TodoProvider>()
                                .getTodosForDate(day)
                                .isNotEmpty)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Date Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.today, color: colorScheme.primary),
                    onPressed: () {
                      setState(() {
                        _selectedDay = DateTime.now();
                        _focusedDay = DateTime.now();
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Task List
            Expanded(
              child:
                  todos.isEmpty
                      ? Center(
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
                                Icons.event_available,
                                size: 60,
                                color: colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Tasks Today',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onBackground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a new task',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onBackground.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: todos.length,
                        itemBuilder: (context, index) {
                          final todo = todos[index];
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

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: priorityColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: priorityColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  todo.isCompleted
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  color: priorityColor,
                                ),
                              ),
                              title: Text(
                                todo.title,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  decoration:
                                      todo.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    todo.description,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        size: 14,
                                        color: priorityColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        todo.priority,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: priorityColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      // Navigate to edit screen
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
                                      // Show delete confirmation
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
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    context
                                                        .read<TodoProvider>()
                                                        .deleteTodo(todo.id!);
                                                    Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            colorScheme.error,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                      );
                                      break;
                                    case 'complete':
                                      // Toggle completion status
                                      final updatedTodo = todo.copyWith(
                                        isCompleted: !todo.isCompleted,
                                      );
                                      context.read<TodoProvider>().updateTodo(
                                        updatedTodo,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              color: colorScheme.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color: colorScheme.error,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Delete'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'complete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              todo.isCompleted
                                                  ? Icons.check_box
                                                  : Icons
                                                      .check_box_outline_blank,
                                              color: colorScheme.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              todo.isCompleted
                                                  ? 'Mark as incomplete'
                                                  : 'Mark as complete',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTodoScreen(selectedDate: _selectedDay),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, size: 32),
        elevation: 6,
      ),
    );
  }

  Future<void> _pickMonthYear(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Select Month and Year',
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
    if (picked != null) {
      setState(() {
        _focusedDay = DateTime(picked.year, picked.month, 1);
        _selectedDay = _focusedDay;
      });
    }
  }
}
