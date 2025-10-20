import 'package:flutter/material.dart';
import 'package:my_app/pages/mobile_input_screen.dart';
import 'package:my_app/pages/opening.dart';
//import 'pages/register_screen.dart';
//import 'pages/password_screen.dart';
//import 'pages/parent_login_screen.dart';
//import 'pages/child_login_screen.dart';
//import 'pages/pin_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hassalah App',
      debugShowCheckedModeBanner: false,
      home: SplashView(),
      routes: {
        '/mobile': (context) => MobileInputScreen(),
        //'/register': (context) => RegisterScreen(),
        //'/password': (context) => PasswordScreen(),
        //'/loginID': (context) => LoginIDScreen(),
        //'/username': (context) => UsernameScreen(),
        //'/pin': (context) => PinScreen(),
      },
    );
  }
}
