import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/category_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
            navigatorKey: navigatorKey,
            title: 'Taskify',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getTheme().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                themeProvider.isDarkMode
                    ? ThemeData.dark().textTheme
                    : ThemeData.light().textTheme,
              ).apply(
                bodyColor:
                    themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
              inputDecorationTheme: InputDecorationTheme(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        themeProvider.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        themeProvider.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        themeProvider.isDarkMode
                            ? Colors.blueAccent
                            : Colors.blue,
                  ),
                ),
                hintStyle: TextStyle(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                  fontSize: 14,
                  textBaseline: TextBaseline.alphabetic,
                ),
                alignLabelWithHint: true,
              ),
              cardTheme: CardTheme(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
