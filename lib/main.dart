import 'package:flutter/material.dart';

// Core / Auth
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
import 'package:my_app/features/child/pages/child_request_success.dart';
import 'package:my_app/features/child/pages/child_security_settings_page.dart';

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
      home: const SplashView(),

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
        '/parentHome': (context) => const ParentShell(),

        '/manageKids': (context) => const ManageKidsScreen(),

        '/parentSecuritySettings': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ParentSecuritySettingsPage(parentId: args['parentId']);
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

        '/childRequestSuccess': (context) =>
            const ChildRequestSuccessScreen(),

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
