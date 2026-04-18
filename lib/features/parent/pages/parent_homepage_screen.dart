import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/utils/check_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parent_select_child_screen.dart';
import 'parent_add_money_screen.dart';
import 'parent_add_card_screen.dart';
import 'parent_my_card_screen.dart';
import 'package:my_app/core/api_config.dart';
import 'parent_insights_screen.dart';
import 'parent_notification_screen.dart';
import 'parent_transactions_screen.dart';
import 'parent_transfer_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentHomeScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with WidgetsBindingObserver {
  String firstname = '';
  String walletBalance = '0.00';
  bool _isLoading = true;
  bool parentHasCard = false;
  int unreadCount = 0;
  String get token => widget.token;
  int get parentId => widget.parentId;
  List<Map<String, dynamic>> insights = [];
  static const TextStyle fintechLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
    letterSpacing: 0.2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
      _fetchUnread();
      _fetchInsights();
    });
  }

  Future<void> _refreshData() async {
    // نعيد تحميل بيانات الأب (بما فيها الرصيد) + الإشعارات
    await Future.wait([fetchParentInfo(), _fetchUnread()]);
  }

  /////////////////////////////////
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🔧 FIX (3)
    super.dispose();
  }

  // 🔧 FIX (4): Detect when user comes back from Moyasar browser
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      // User has returned to the app → refresh wallet
      _refreshFromDb();
    }
  }
  ////////////////////////////////

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    if (!mounted) return;
    await fetchParentInfo();
  }

  Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/mobile',
      (Route<dynamic> route) => false,
    );
  }

  // ✅ NEW: Hassala-style TEAL info bar (for "add card first")
  void _showTealInfoBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // ✅ TEAL BOX STYLE (floating, rounded, consistent)
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2EA49E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Fetch parent info and card status
  Future<void> fetchParentInfo() async {
    if (token.isEmpty) {
      await _handleUnauthorized();
      return;
    }
    setState(() => _isLoading = true);

    final parentUrl = Uri.parse("${ApiConfig.baseUrl}/api/parent/$parentId");
    final cardUrl = Uri.parse("${ApiConfig.baseUrl}/api/parent/$parentId/card");

    try {
      String newFirstname = firstname;
      double newBalance = double.tryParse(walletBalance) ?? 0.0;
      bool newHasCard = false;

      // Parent info
      final parentRes = await http.get(
        parentUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (parentRes.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }

      if (parentRes.statusCode == 200) {
        final data = jsonDecode(parentRes.body);
        newFirstname = data['firstname'] ?? data['firstName'] ?? '';

        final b = data['walletbalance'] ?? data['balance'];
        if (b != null) {
          newBalance = (b is num)
              ? b.toDouble()
              : double.tryParse(b.toString()) ?? 0.0;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load parent info')),
        );
      }

      // Card status
      final cardRes = await http.get(
        cardUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (cardRes.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }

      if (cardRes.statusCode == 200) {
        final cardData = jsonDecode(cardRes.body);
        final hasLast4 =
            cardData['last4'] != null &&
            cardData['last4'].toString().isNotEmpty;
        final hasFlag = cardData['hasCard'] == true;
        newHasCard = hasLast4 || hasFlag;
      } else if (cardRes.statusCode == 404) {
        newHasCard = false;
      }

      if (!mounted) return;
      setState(() {
        firstname = newFirstname;
        walletBalance = newBalance.toStringAsFixed(2);
        parentHasCard = newHasCard;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading parent data')),
      );
    }
  }

  Future<void> _refreshFromDb() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await fetchParentInfo();
  }

  Future<void> _fetchUnread() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/unread/parent/$parentId",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        unreadCount = data["unread"] ?? 0;
      });
    }
  }

  Widget _notifIconWithBadge({
    required int unread,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 28,
            color: Colors.black87,
          ),

          if (unread > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    unread > 99 ? "99+" : unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchInsights() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/insights/parent/$parentId");

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        insights = List<Map<String, dynamic>>.from(data);
      });
    }
    print("INSIGHTS RESPONSE:");
    print(res.body);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    final balanceText =
        double.tryParse(walletBalance)?.toStringAsFixed(2) ?? "0.00";

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                // ----------------------- TOP BAR -----------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentNotificationsScreen(
                              parentId: parentId,
                              token: token,
                            ),
                          ),
                        );

                        // ✅ بعد الرجوع حدّث العداد
                        await _fetchUnread();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 28,
                            color: Colors.black87,
                          ),

                          if (unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  unreadCount > 99
                                      ? "99+"
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Welcome
                Text(
                  firstname.isNotEmpty ? "Welcome, $firstname" : "Welcome!",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),

                const SizedBox(height: 18),

                // Wallet card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Parent's Wallet",
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/Sar.png",
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            balanceText,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                if (insights.isNotEmpty) _insightsSection(),

                const SizedBox(height: 18),

                // Actions row 1
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: "Add Money",
                        asset: "assets/icons/addMoney.png",
                        labelStyle: fintechLabelStyle,
                        onTap: () async {
                          if (!parentHasCard) {
                            _showTealInfoBar("Please add a card first");
                            return;
                          }

                          final added = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentAddMoneyScreen(
                                parentId: parentId,
                                token: token,
                              ),
                            ),
                          );

                          if (added == true) {
                            await _refreshFromDb();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: "Transactions",
                        asset: "assets/icons/transactions.png",
                        labelStyle: fintechLabelStyle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentTransactionsScreen(
                                parentId: parentId,
                                token: token,
                                baseUrl: ApiConfig.baseUrl,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions row 2
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: parentHasCard ? "My Card" : "Add Card",
                        asset: parentHasCard
                            ? "assets/icons/myCard.png"
                            : "assets/icons/addCard.png",
                        labelStyle: fintechLabelStyle,
                        onTap: () async {
                          if (parentHasCard) {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParentMyCardScreen(
                                  parentId: parentId,
                                  token: token,
                                ),
                              ),
                            );
                            if (updated == true) {
                              await _refreshFromDb();
                            }
                          } else {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParentAddCardScreen(
                                  parentId: parentId,
                                  token: token,
                                ),
                              ),
                            );
                            if (result == true) {
                              await _refreshFromDb();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: "Insights",
                        asset: "assets/icons/insights.png",
                        labelStyle: fintechLabelStyle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentInsightsScreen(
                                parentId: parentId,
                                token: token,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions row 3
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: "My Children",
                        asset: "assets/icons/myKids.png",
                        labelStyle: fintechLabelStyle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentSelectChildScreen(
                                parentId: parentId,
                                token: token,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: "Transfer Money",
                        asset: "assets/icons/transactions.png",
                        labelStyle: fintechLabelStyle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentSelectChildScreen(
                                parentId: parentId,
                                token: token,
                                transferMode: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightText(String message) {
    final parts = message.split("SAR");

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w800,
      height: 1.35,
    );

    // No SAR → normal text
    if (parts.length == 1) {
      return Text(message, style: textStyle);
    }

    List<InlineSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: textStyle));

      if (i != parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Image.asset(
                "assets/icons/Sar.png",
                height: 16,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  int _currentPage = 0;

  final Map<String, Map<String, dynamic>> insightStyles = {
    "top-spender": {
      "colors": [Color(0xFFEF5350), Color(0xFFE57373)],
      "icon": Icons.emoji_events,
    },
    "average": {
      "colors": [Color(0xFF42A5F5), Color(0xFF90CAF9)],
      "icon": Icons.bar_chart,
    },
    "category": {
      "colors": [Color(0xFFAB47BC), Color(0xFFCE93D8)],
      "icon": Icons.pie_chart,
    },
    "total": {
      "colors": [Color(0xFF26A69A), Color(0xFF80CBC4)],
      "icon": Icons.account_balance_wallet,
    },
    "trend": {
      "colors": [Color(0xFFFF7043), Color(0xFFFFAB91)],
      "icon": Icons.trending_up,
    },
    "empty": {
      "colors": [Color(0xFFB0BEC5), Color(0xFFECEFF1)],
      "icon": Icons.info_outline,
    },
  };

  Widget _insightsSection() {
    final gradients = [
      [Color(0xFF37C4BE), Color(0xFF6EE7DF)],
      [Color(0xFF7E57C2), Color(0xFFB39DDB)],
      [Color(0xFFFF8A65), Color(0xFFFFB199)],
      [Color(0xFF42A5F5), Color(0xFF90CAF9)],
    ];

    final controller = PageController(viewportFraction: 0.88);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: controller,
            itemCount: insights.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, i) {
              final insight = insights[i];
              final type = insight["type"] ?? "empty";
              final title = insight["title"] ?? "";
              final message = insight["message"] ?? "";

              final style = insightStyles[type] ?? insightStyles["empty"]!;

              final gradient = style["colors"] as List<Color>;
              final icon = style["icon"] as IconData;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInsightText(message),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(insights.length, (index) {
            final isActive = index == _currentPage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF37C4BE)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String asset;
  final VoidCallback onTap;
  final TextStyle labelStyle;

  const _ActionCard({
    required this.title,
    required this.asset,
    required this.onTap,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEDED), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(asset, height: 28, fit: BoxFit.contain),
              const SizedBox(height: 10),
              Text(title, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
