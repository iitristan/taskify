import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'add_todo_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    final daysOfWeek = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final todos = context.watch<TodoProvider>().getTodosForDate(_selectedDay);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pageController = PageController(initialPage: 1000);
    int currentPage = 1000;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Calendar', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  DateFormat('yyyy').format(_focusedDay),
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _pickMonthYear(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMMM').format(_focusedDay),
                          style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text('Calendars', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: List.generate(7, (i) =>
                Expanded(
                  child: Center(
                    child: Text(
                      weekDays[i],
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colorScheme.primary, size: 28),
                  onPressed: () {
                    setState(() {
                      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                      _selectedDay = _focusedDay;
                    });
                  },
                ),
                Expanded(
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = daysOfWeek[i];
                      final isToday = isSameDay(day, DateTime.now());
                      final isSelected = isSameDay(day, _selectedDay);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                              _focusedDay = day;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : isToday
                                      ? colorScheme.primary.withOpacity(0.15)
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : isToday
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                width: isSelected || isToday ? 2 : 1,
                              ),
                            ),
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : isToday
                                          ? colorScheme.primary
                                          : colorScheme.onBackground,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colorScheme.primary, size: 28),
                  onPressed: () {
                    setState(() {
                      _focusedDay = _focusedDay.add(const Duration(days: 7));
                      _selectedDay = _focusedDay;
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 1,
            color: colorScheme.onBackground.withOpacity(0.08),
          ),
          const SizedBox(height: 8),
          if (todos.isEmpty) ...[
            const Spacer(),
            Icon(Icons.hourglass_empty, size: 100, color: colorScheme.primary.withOpacity(0.15)),
            const SizedBox(height: 24),
            Text(
              'No Events Today!',
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'It looks like a great day to rest,\nrelax, and recharge.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
            ),
            const Spacer(),
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Card(
                    color: colorScheme.surface,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(todo.title, style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      subtitle: Text(todo.description, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
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
      fieldLabelText: 'Month/Year',
      fieldHintText: 'Month/Year',
      selectableDayPredicate: (date) => date.day == 1,
    );
    if (picked != null) {
      setState(() {
        _focusedDay = DateTime(picked.year, picked.month, 1);
        _selectedDay = _focusedDay;
      });
    }
  }
} 