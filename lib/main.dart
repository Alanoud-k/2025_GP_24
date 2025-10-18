import 'package:flutter/material.dart';
import 'package:my_app/opening.dart';
//import 'pages/HomePage';
//import 'pages/AboutPage';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Demo',
     // initialRoute: '/',
      debugShowCheckedModeBanner: false,
     // routes: {
       // '/': (context) => HomePage(),
       // '/about': (context) => AboutPage(),
     // },
      home: SplashView(),
    );
  }
}
