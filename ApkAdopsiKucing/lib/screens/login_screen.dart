import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawfinder/services/auth_service.dart'; // Pastikan path sesuai dengan file Anda

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool _isLoading = false;

  String? _errorEmail;
  String? _errorPassword;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    setState(() {
      _errorEmail = null;
      _errorPassword = null;
    });
    bool hasError = false;

    if (email.isEmpty) {
      setState(() {
        _errorEmail = 'Email Tidak Boleh kosong!';
      });
      hasError = true;
    } else if (!RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(email)) {
      setState(() {
        _errorEmail = 'Format Email tidak valid!';
      });
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        _errorPassword = 'Password Tidak Boleh kosong!';
      });
      hasError = true;
    } else if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*()<>,.?"/:;]'))) {
      setState(() {
        _errorPassword =
            'Minimal 8 karaketer, terdiri huruf besar, kecil, angka, simbol';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true; // Set loading state to true
    });

    try {
      User? user = await _authService.signInWithEmailPassword(email, password);

      if (user != null) {
        // Berhasil login, pindah ke screen berikutnya
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/BottomNavBar');
      } else {
        // This 'else' block might not be reached if AuthService throws an exception.
        // The error handling below will catch FirebaseAuthException.
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Email atau password salah. Silakan coba lagi.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun Anda telah dinonaktifkan.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      // Catch any other unexpected errors
      print("Error during login process: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan yang tidak terduga: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo bulat hijau
              Container(
                margin: EdgeInsets.only(top: 30),
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: Color(0xFF6FCF97), // Hijau muda
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/PawfinderLogo.png',
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 20),

              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Login untuk menemukan kucing idaman!",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              SizedBox(height: 30),

              // Input Email
              TextField(
                controller: emailController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Email",
                  errorText: _errorEmail,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email, color: Color(0xFF6FCF97)),
                ),
              ),
              SizedBox(height: 20),

              // Input Password
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Password",
                  errorText: _errorPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF6FCF97)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF6FCF97),
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6FCF97),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color.fromRGBO(0, 0, 0, 0.5),
                          offset: Offset(2, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Jika belum punya akun
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Belum punya akun? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/SignupScreen');
                    },
                    child: Text(
                      "Daftar",
                      style: TextStyle(
                        color: Color(0xFF6FCF97),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
