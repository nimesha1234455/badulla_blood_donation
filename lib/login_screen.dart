import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_screen.dart';
import 'search_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  bool _showAdminLogin = false;

  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  static const Color primaryRed = Color(0xFFE53935);
  static const Color darkMaroon = Color(0xFF5D0A0A);
  static const Color bgCream = Color(0xFFF5EFE6);

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final String uid = userCredential.user!.uid;
      final doc = await FirebaseFirestore.instance.collection('donors').doc(uid).get();
      if (mounted) {
        if (doc.exists) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegistrationScreen()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ඇඩ්මින් සඳහා වෙනස් කළ කොටස
  Future<void> _adminLogin() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _adminEmailController.text.trim(),
        password: _adminPasswordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (mounted) {
        if (userDoc.exists && (userDoc.data() as Map<String, dynamic>)['role'] == 'admin') {
          // ඇඩ්මින් පැනල් එකට යන පාර මෙතන ඇතුළත් කර ඇත
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          await _auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Access Denied: Not an admin"), backgroundColor: Colors.red),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Error: ${e.message}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackgroundPatternPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: primaryRed, shape: BoxShape.circle),
                    child: const Icon(Icons.bloodtype, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('BADULLA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkMaroon, letterSpacing: 1.5)),
                  const Text('BLOOD BANK', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkMaroon, letterSpacing: 1.5)),
                  const SizedBox(height: 32),

                  _isLoading ? const CircularProgressIndicator(color: primaryRed)
                      : _GlassButton(onTap: _signInWithGoogle, backgroundColor: Colors.white, textColor: Colors.black87, icon: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))), label: 'Sign in with Google Account'),

                  const SizedBox(height: 24),
                  _GlassButton(onTap: _signInWithGoogle, backgroundColor: primaryRed, textColor: Colors.white, icon: const Icon(Icons.person_add, color: Colors.white), label: 'DONOR SIGN IN', bold: true),
                  const SizedBox(height: 16),
                  _GlassButton(onTap: () => setState(() => _showAdminLogin = !_showAdminLogin), backgroundColor: darkMaroon, textColor: Colors.white, icon: const Icon(Icons.key, color: Colors.white), label: 'ADMIN LOGIN (Staff Only)', bold: true),

                  if (_showAdminLogin) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _adminEmailController,
                      decoration: InputDecoration(
                        hintText: 'Admin Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: primaryRed),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _adminPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Admin Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: primaryRed),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator(color: primaryRed)
                        : _GlassButton(
                      onTap: _adminLogin,
                      backgroundColor: primaryRed,
                      textColor: Colors.white,
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: 'Confirm Login',
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final String label;
  final bool bold;

  const _GlassButton({
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(30),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: bold ? FontWeight.bold : FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE53935).withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 2;
    const double dropSize = 60;
    const double spacing = 110;
    for (double y = -20; y < size.height + spacing; y += spacing) {
      for (double x = -20; x < size.width + spacing; x += spacing) {
        final offsetX = (y / spacing).floor() % 2 == 0 ? 0.0 : spacing / 2;
        _drawDrop(canvas, Offset(x + offsetX, y), dropSize, paint);
      }
    }
  }
  void _drawDrop(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.cubicTo(center.dx - size * 0.5, center.dy + size * 0.5, center.dx - size * 0.4, center.dy + size, center.dx, center.dy + size);
    path.cubicTo(center.dx + size * 0.4, center.dy + size, center.dx + size * 0.5, center.dy + size * 0.5, center.dx, center.dy);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}