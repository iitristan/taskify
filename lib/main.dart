import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create:
              (context) =>
                  UserProvider(authProvider: context.read<AuthProvider>()),
          update:
              (context, auth, previous) =>
                  previous ?? UserProvider(authProvider: auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TodoProvider>(
          create: (context) => TodoProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? TodoProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (context) => CategoryProvider(context.read<AuthProvider>()),
          update:
              (context, auth, previous) => previous ?? CategoryProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReminderProvider>(
          create: (context) => ReminderProvider(),
          update: (context, auth, previous) => previous ?? ReminderProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Taskify',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getTheme(),
            home: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (!auth.isInitialized) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return auth.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
