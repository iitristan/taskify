import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/todo_provider.dart';
import 'providers/category_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TodoProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        ChangeNotifierProvider(create: (context) => ReminderProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Taskify',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getTheme().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                themeProvider.isDarkMode
                    ? ThemeData.dark().textTheme
                    : ThemeData.light().textTheme,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
