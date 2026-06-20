import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart'; // ප්‍රධාන හෝම් පිටුවට යන්න මේක ඕනේ

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// 💡 මෙන්න මේ පේළියේ නම '_SplashScreenState' කියලා නිවැරදි කළා 😍
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ⏳ තත්පර 3කට පසු ප්‍රධාන පිටුවට (MainHomeScreen) මාරু වන ටයිමර් එක
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainHomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.redAccent, // පසුබිම් රතු පාට
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🩸 මැද පෙනෙන ලස්සන ලේ බිංදුවක සහ හෘද වස්තුවක අයිකන් එක
            Icon(
              Icons.bloodtype,
              size: 120,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Badulla Blood Bank',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Save Lives, Donate Blood',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            // 🔄 කැරකෙන ලස්සන Loading බාර් එකක්
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}