import 'package:flutter/material.dart';
import 'package:my_app/core/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core / Auth
import 'package:my_app/features/auth/pages/mobile_input_screen.dart';
import 'package:my_app/features/auth/pages/opening.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Parent
import 'package:my_app/features/parent/pages/register_screen.dart';
import 'package:my_app/features/parent/pages/parent_login_screen.dart';
import 'package:my_app/features/parent/pages/manage_kids_screen.dart';
import 'package:my_app/features/parent/pages/parent_security_settings_page.dart';
import 'package:my_app/features/parent/pages/terms_privacy_page.dart';
import 'package:my_app/features/parent/widgets/parent_shell.dart';

// Child
import 'package:my_app/features/child/pages/child_login_screen.dart';
import 'package:my_app/features/child/widgets/child_shell.dart';
import 'package:my_app/features/child/pages/child_request_money_screen.dart';
import 'package:my_app/features/child/pages/child_request_success.dart';
import 'package:my_app/features/child/pages/child_security_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  final role = prefs.getString("role");
  final childId = prefs.getInt("childId");
  final parentId = prefs.getInt("parentId");

  Widget startPage;

  if (token != null) {
    if (role == "Parent") {
      if (parentId != null) {
        startPage = ParentShell(parentId: parentId!, token: token!);
      } else {
        startPage = const SplashView();
      }
    } else if (role == "Child") {
      if (childId != null) {
        startPage = ChildShell(
          childId: childId!,
          token: token!,
          baseUrl: ApiConfig.baseUrl,
        );
      } else {
        startPage = const SplashView();
      }
    } else {
      startPage = const SplashView();
    }
  } else {
    startPage = const SplashView();
  }

  runApp(MyApp(startPage: startPage));
}

class MyApp extends StatelessWidget {
  final Widget startPage;
  const MyApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hassalah App',
      debugShowCheckedModeBanner: false,
      home: startPage,

      routes: {
        // --------------------------
        // Auth & Onboarding
        // --------------------------
        '/mobile': (context) => const MobileInputScreen(),

        // --------------------------
        // Parent Routes
        // --------------------------
        '/register': (context) => const RegisterScreen(),
        '/parentLogin': (context) => const ParentLoginScreen(),

        // Parent main shell (with bottom nav)
        '/parentHome': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;

          return ParentShell(
            parentId: args?['parentId'],
            token: args?['token'],
          );
        },

        '/manageKids': (context) => const ManageKidsScreen(),

        '/parentSecuritySettings': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ParentSecuritySettingsPage(
            parentId: args['parentId'],
            token: args['token'],
          );
        },

        '/termsPrivacy': (context) => const TermsPrivacyPage(),

        // --------------------------
        // Child Login Only
        // --------------------------
        '/childLogin': (context) => const ChildLoginScreen(),

        // --------------------------
        // Child main shell
        // --------------------------
        '/childShell': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ChildShell(
            childId: args['childId'],
            token: args['token'],
            baseUrl: args['baseUrl'],
          );
        },

        // --------------------------
        // Child Requests (Money)
        // --------------------------
        '/childRequestMoney': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ChildRequestMoneyScreen(childId: args['childId']);
        },

        '/childRequestSuccess': (context) => const ChildRequestSuccessScreen(),

        '/childSecuritySettings': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ChildSecuritySettingsPage(
            childId: args['childId'],
            baseUrl: args['baseUrl'],
          );
        },
      },
    );
  }
}
