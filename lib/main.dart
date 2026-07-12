import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_service.dart';
import 'registration_screen.dart';
import 'search_screen.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'admin_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google-services.json eka auto initialize karanawa
  await Firebase.initializeApp();

  // Notification Service එක Initialize කිරීම
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Badulla Blood Bank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainHomeScreen(),
        '/admin': (context) => AdminPanel(),
      },
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RegistrationScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Register',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search Donors',
          ),
        ],
      ),
    );
  }
}