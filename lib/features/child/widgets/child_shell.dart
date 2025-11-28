import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/utils/check_auth.dart';

// Pages
import '../pages/child_homepage_screen.dart';
import '../pages/child_goals_screen.dart';
import '../pages/child_rewards_screen.dart';
import '../pages/child_game_screen.dart';
import '../pages/child_card_screen.dart';
import '../pages/child_more_screen.dart';

// Widgets
import '../widgets/child_bottom_nav_bar.dart';

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
  int currentIndex = 2;

  String childName = "Child User";
  String childPhone = "";
  bool isLoadingData = true;

  int? spendingAccountId; // new field

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
          spendingAccountId = data["spendingAccountId"]; // must exist
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
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    final List<Widget> pages = [
      ChildRewardsScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ),
      ChildGameScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ),
      ChildHomePageScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
      ),
      ChildCardScreen(
        childId: widget.childId,
        token: widget.token,
        baseUrl: widget.baseUrl,
        receiverAccountId: spendingAccountId!, // important!!!
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
      body: SafeArea(
        bottom: false,
        child: pages[currentIndex],
      ),
      bottomNavigationBar: ChildBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
      ),
    );
  }
}
