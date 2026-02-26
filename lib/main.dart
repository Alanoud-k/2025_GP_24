// lib/main.dart

import 'package:flutter/material.dart';
import 'package:my_app/core/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Auth / Onboarding
import 'package:my_app/features/auth/pages/mobile_input_screen.dart';
import 'package:my_app/features/auth/pages/opening.dart';

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
import 'package:my_app/features/child/pages/child_security_settings_page.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_app/notifications/notification_service.dart';


Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp();

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  //  Local notifications setup
  await NotificationService().init();
  await NotificationService().requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  final role = prefs.getString("role");
  final childId = prefs.getInt("childId");
  final parentId = prefs.getInt("parentId");

  Widget startPage = const SplashView();

  if (token != null && role != null) {
    if (role == "Parent" && parentId != null) {
      startPage = ParentShell(parentId: parentId, token: token);
    } else if (role == "Child" && childId != null) {
      startPage = ChildShell(
        childId: childId,
        token: token,
        baseUrl: ApiConfig.baseUrl,
      );
    }
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
        // Auth
        '/mobile': (context) => const MobileInputScreen(),

        // Parent
        '/register': (context) => const RegisterScreen(),
        '/parentLogin': (context) => const ParentLoginScreen(),

        '/parentHome': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final int? parentId = args?['parentId'] as int?;
          final String? token = args?['token'] as String?;

          if (parentId == null || token == null) return const SplashView();

          return ParentShell(parentId: parentId, token: token);
        },

        '/manageKids': (context) => const ManageKidsScreen(),

        '/parentSecuritySettings': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final int? parentId = args?['parentId'] as int?;
          final String? token = args?['token'] as String?;

          if (parentId == null || token == null) return const SplashView();

          return ParentSecuritySettingsPage(parentId: parentId, token: token);
        },

        '/termsPrivacy': (context) => const TermsPrivacyPage(),

        // Child login
        '/childLogin': (context) => const ChildLoginScreen(),

        // Child shell
        '/childShell': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final int? childId = args?['childId'] as int?;
          final String? token = args?['token'] as String?;
          final String? baseUrl = args?['baseUrl'] as String?;

          if (childId == null || token == null || baseUrl == null) {
            return const SplashView();
          }

          return ChildShell(childId: childId, token: token, baseUrl: baseUrl);
        },

        // Child request money
        '/childRequestMoney': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final int? childId = args?['childId'] as int?;
          final String? token = args?['token'] as String?;
          final String? baseUrl = args?['baseUrl'] as String?;

          if (childId == null || token == null || baseUrl == null) {
            return const SplashView();
          }

          return ChildRequestMoneyScreen(
            childId: childId,
            baseUrl: baseUrl,
            token: token,
          );
        },

        // Child security settings
        '/childSecuritySettings': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final int? childId = args?['childId'] as int?;
          final String? token = args?['token'] as String?;
          final String? baseUrl = args?['baseUrl'] as String?;

          if (childId == null || token == null || baseUrl == null) {
            return const SplashView();
          }

          return ChildSecuritySettingsPage(
            childId: childId,
            baseUrl: baseUrl,
            token: token,
          );
        },
      },
    );
  }
}
