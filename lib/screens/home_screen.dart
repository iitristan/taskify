import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'add_todo_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TodoProvider>().initDatabase());
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    final daysOfWeek = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final todos = context.watch<TodoProvider>().getTodosForDate(_selectedDay);
    final pageController = PageController(initialPage: 1000);
    int currentPage = 1000;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text('Calendar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  DateFormat('yyyy').format(_focusedDay),
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _pickMonthYear(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMMM').format(_focusedDay),
                          style: const TextStyle(color: Colors.blue, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text('Calendars', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 16)),
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
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 64,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 28),
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
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            border: i < 6 ? Border(
                              right: BorderSide(color: Colors.grey[300]!, width: 1),
                            ) : null,
                          ),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDay = day;
                                  _focusedDay = day;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue : isToday ? Colors.blue[100] : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.blue[800]! : isToday ? Colors.blue : Colors.transparent,
                                    width: isSelected || isToday ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : isToday ? Colors.blue[800] : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
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
                  icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 28),
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
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          if (todos.isEmpty) ...[
            const Spacer(),
            Icon(Icons.hourglass_empty, size: 100, color: Colors.blue[100]),
            const SizedBox(height: 24),
            const Text(
              'No Events Today!',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'It looks like a great day to rest,\nrelax, and recharge.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const Spacer(),
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Card(
                    color: Colors.blue[50],
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(todo.title, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      subtitle: Text(todo.description, style: const TextStyle(color: Colors.black54)),
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
        backgroundColor: Colors.blue[800],
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