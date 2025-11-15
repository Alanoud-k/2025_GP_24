import 'package:flutter/material.dart';
import 'package:my_app/pages/mobile_input_screen.dart';
import 'package:my_app/pages/opening.dart';
import 'package:my_app/pages/register_screen.dart';
import 'package:my_app/pages/parent_login_screen.dart';
import 'package:my_app/pages/child_login_screen.dart';
import 'package:my_app/pages/parent_homepage_screen.dart';
import 'package:my_app/pages/manage_kids_screen.dart';
import 'package:my_app/pages/child_homepage_screen.dart';
import 'package:my_app/pages/child_goals_screen.dart'; 
import 'package:my_app/pages/child_add_goal_screen.dart';
import 'package:my_app/pages/child_request_money_screen.dart';
import 'package:my_app/pages/child_request_success.dart';



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

        '/register': (context) => const RegisterScreen(),

        '/parentLogin': (context) => const ParentLoginScreen(),
        '/parentHome': (context) => const ParentHomeScreen(),

        '/childLogin': (context) => const ChildLoginScreen(),
        '/childHome': (context) => const ChildHomePageScreen(),

        '/manageKids': (context) => const ManageKidsScreen(),
        '/childGoals': (context) => const ChildGoalsScreen(),
        '/childAddGoal': (context) => const ChildAddGoalScreen(), 

         '/childRequestMoney': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return ChildRequestMoneyScreen(childId: args['childId']);
  },

  '/childRequestSuccess': (context) => const ChildRequestSuccessScreen(),
 

      },
    );
  }
}
