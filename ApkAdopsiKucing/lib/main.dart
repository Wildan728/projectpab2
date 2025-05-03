import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawfinder/bottom_navbar.dart';
import 'package:pawfinder/firebase_options.dart';
import 'package:pawfinder/screens/home_screen.dart';
import 'package:pawfinder/screens/login_screen.dart';
import 'package:pawfinder/screens/posting_screen.dart';
import 'package:pawfinder/screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/LoginScreen',
      routes: {
        '/LoginScreen': (context) => LoginScreen(),
        '/SignupScreen': (context) => SignupScreen(),
        '/HomeScreen': (context) => HomeScreen(),
        '/BottomNavBar': (context) => BottomNavBar(),
        '/PostingScreen': (context) => PostingScreen(),
      },
    );
  }
}
