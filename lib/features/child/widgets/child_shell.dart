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
import '../pages/child_rewards_screen.dart'; // مسار صفحة الجوائز الصحيح
import '../pages/child_game_screen.dart';
import '../pages/child_card_screen.dart';
import '../pages/child_more_screen.dart';
import '../pages/child_qr_scan_image_screen.dart';
import '../pages/child_request_money_screen.dart'; 
import 'child_bottom_nav_bar.dart'; // تأكد من استدعاء النافقيشن بار هنا

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
  int currentIndex = 2; // الهوم بيج هي الافتراضية في المنتصف

  String childName = "Child User";
  String childPhone = "";
  bool isLoadingData = true;

  int? spendingAccountId;

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

    // هنا يتم ربط الصفحات بالأرقام
    final List<Widget> pages = [
      ChildMoreScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
        username: childName,
        phoneNo: childPhone,
      ), // الزر رقم 0: المزيد
      
      ChildQrScanImageScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ), // الزر رقم 1: الدفع

      ChildHomePageScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ), // الزر رقم 2: الهوم بيج (الرئيسية في المنتصف)

      ChildRequestMoneyScreen(
        childId: widget.childId,
        baseUrl: widget.baseUrl,
        token: widget.token,
      ), // الزر رقم 3: طلب مبلغ

      ChildRewardsScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ), // الزر رقم 4: الجوائز
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
      ),
    );
  }
}