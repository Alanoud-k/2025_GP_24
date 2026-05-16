// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_svg/flutter_svg.dart'; 

// import 'package:my_app/utils/check_auth.dart';
// import 'package:my_app/l10n/app_localizations.dart'; 

// // Pages
// import '../pages/child_homepage_screen.dart';
// import '../pages/child_goals_screen.dart';
// import '../pages/child_rewards_screen.dart'; 
// import '../pages/child_game_screen.dart';
// import '../pages/child_card_screen.dart';
// import '../pages/child_more_screen.dart';
// import '../pages/child_qr_scan_image_screen.dart';
// import '../pages/child_request_money_screen.dart'; 
// import 'child_bottom_nav_bar.dart'; 

// class ChildShell extends StatefulWidget {
//   final int childId;
//   final String baseUrl;
//   final String token;

//   const ChildShell({
//     super.key,
//     required this.childId,
//     required this.baseUrl,
//     required this.token,
//   });

//   @override
//   State<ChildShell> createState() => _ChildShellState();
// }

// class _ChildShellState extends State<ChildShell> {
//   // تم تغيير الرقم الافتراضي إلى 0 ليكون متطابقاً مع ترتيب الأب
//   int currentIndex = 0; 

//   String childName = "Child User";
//   String childPhone = "";
//   bool isLoadingData = true;

//   int? spendingAccountId;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       checkAuthStatus(context);
//     });
//     _fetchChildData();
//   }

//   Future<void> _fetchChildData() async {
//     try {
//       final response = await http.get(
//         Uri.parse("${widget.baseUrl}/api/auth/child/info/${widget.childId}"),
//         headers: {
//           'Authorization': 'Bearer ${widget.token}',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 401) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.clear();
//         if (mounted) {
//           Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//         }
//         return;
//       }

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         setState(() {
//           childName = data["firstName"] ?? "Child User";
//           childPhone = data["phoneNo"] ?? "";
//           spendingAccountId = data["spendingAccountId"]; 
//           isLoadingData = false;
//         });
//       } else {
//         setState(() => isLoadingData = false);
//       }
//     } catch (e) {
//       setState(() => isLoadingData = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoadingData || spendingAccountId == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xffF7F8FA),
//         body: Center(child: CircularProgressIndicator(color: Colors.teal)),
//       );
//     }

//     // هنا أعدنا الترتيب ليكون منطقياً ومتطابقاً مع تصميم الأب
//     final List<Widget> pages = [
//       ChildHomePageScreen(
//         childId: widget.childId,
//         token: widget.token,
//         baseUrl: widget.baseUrl,
//       ), // الزر رقم 0: الهوم بيج (الرئيسية في المنتصف)
      
//       ChildQrScanImageScreen(
//         childId: widget.childId,
//         token: widget.token,
//         baseUrl: widget.baseUrl,
//       ), // الزر رقم 1: الدفع

//       ChildRequestMoneyScreen(
//         childId: widget.childId,
//         baseUrl: widget.baseUrl,
//         token: widget.token,
//       ), // الزر رقم 2: طلب مبلغ

//       ChildRewardsScreen(
//         childId: widget.childId,
//         token: widget.token,
//         baseUrl: widget.baseUrl,
//       ), // الزر رقم 3: الجوائز

//       ChildMoreScreen(
//         childId: widget.childId,
//         token: widget.token,
//         baseUrl: widget.baseUrl,
//         username: childName,
//         phoneNo: childPhone,
//       ), // الزر رقم 4: المزيد
//     ];

//     return Scaffold(
//       extendBody: true,
//       backgroundColor: const Color(0xffF7F8FA),
//       body: SafeArea(bottom: false, child: pages[currentIndex]),
//       bottomNavigationBar: ChildBottomNavBar(
//         currentIndex: currentIndex,
//         onTap: (index) {
//           setState(() => currentIndex = index);
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart'; 

import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/l10n/app_localizations.dart'; 

// Pages
import '../pages/child_homepage_screen.dart';
import '../pages/child_goals_screen.dart';
import '../pages/child_rewards_screen.dart'; 
import '../pages/child_game_screen.dart';
import '../pages/child_card_screen.dart';
import '../pages/child_more_screen.dart';
import '../pages/child_qr_scan_image_screen.dart';
import '../pages/child_request_money_screen.dart'; 
import 'child_bottom_nav_bar.dart'; 

class ChildShell extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildShell({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int currentIndex = 0; 

  String childName = "Child User";
  String childPhone = "";
  bool isLoadingData = true;

  int? spendingAccountId;

  // 🎯 تعريف مفاتيح شريط التنقل للطفل
  final GlobalKey _navHomeKey = GlobalKey();
  final GlobalKey _navPayKey = GlobalKey();
  final GlobalKey _navRequestKey = GlobalKey();
  final GlobalKey _navPrizesKey = GlobalKey();
  final GlobalKey _navMoreKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });
    _fetchChildData();
  }

  Future<void> _fetchChildData() async {
    try {
      final response = await http.get(
        Uri.parse("${widget.baseUrl}/api/auth/child/info/${widget.childId}"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          childName = data["firstName"] ?? "Child User";
          childPhone = data["phoneNo"] ?? "";
          spendingAccountId = data["spendingAccountId"]; 
          isLoadingData = false;
        });
      } else {
        setState(() => isLoadingData = false);
      }
    } catch (e) {
      setState(() => isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingData || spendingAccountId == null) {
      return const Scaffold(
        backgroundColor: Color(0xffF7F8FA),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    final List<Widget> pages = [
      ChildHomePageScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
        // 👈 تمرير المفاتيح
        payKey: _navPayKey,
        requestKey: _navRequestKey,
        prizesKey: _navPrizesKey,
      ), 
      
      ChildQrScanImageScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ), 

      ChildRequestMoneyScreen(
        childId: widget.childId,
        baseUrl: widget.baseUrl,
        token: widget.token,
      ), 

      ChildRewardsScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ), 

      ChildMoreScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
        username: childName,
        phoneNo: childPhone,
      ), 
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xffF7F8FA),
      body: SafeArea(bottom: false, child: pages[currentIndex]),
      bottomNavigationBar: ChildBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
        // 👈 ربط المفاتيح بالأزرار السفلية
        homeKey: _navHomeKey,
        payKey: _navPayKey,
        requestKey: _navRequestKey,
        prizesKey: _navPrizesKey,
        moreKey: _navMoreKey,
      ),
    );
  }
}