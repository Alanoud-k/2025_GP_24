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
import 'package:my_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/providers/locale_provider.dart';
import 'parent_allowance_screen.dart';

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
    await Future.wait([fetchParentInfo(), _fetchUnread()]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _refreshFromDb();
    }
  }

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

  void _showTealInfoBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadParentInfo),
          ),
        );
      }

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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorLoadingParentData),
        ),
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
            PositionedDirectional(
              end: -2,
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

    final locale = Provider.of<LocaleProvider>(
      context,
      listen: false,
    ).locale.languageCode;

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "x-language": locale},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        insights = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  void _showInsightDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _getTranslatedTitle(String titleKey, AppLocalizations l10n) {
    switch (titleKey) {
      case "insight_title_no_children": return l10n.insight_title_no_children;
      case "insight_title_get_started": return l10n.insight_title_get_started;
      case "insight_title_no_data": return l10n.insight_title_no_data;
      case "insight_title_no_activity": return l10n.insight_title_no_activity;
      case "insight_title_spending_trend": return l10n.insight_title_spending_trend;
      case "insight_title_recent_spending": return l10n.insight_title_recent_spending;
      case "insight_title_top_spender": return l10n.insight_title_top_spender;
      case "insight_title_average_spending": return l10n.insight_title_average_spending;
      case "insight_title_top_category": return l10n.insight_title_top_category;
      case "insight_title_total_spent": return l10n.insight_title_total_spent;
      case "insight_title_smart_insight": return l10n.insight_title_smart_insight;
      default: return titleKey; 
    }
  }

  String _getTranslatedMessage(String msgKey, String? val1, String? val2, AppLocalizations l10n) {
    String v1 = val1 ?? "";
    String v2 = val2 ?? "";
    
    switch (msgKey) {
      case "insight_msg_no_children": return l10n.insight_msg_no_children;
      case "insight_msg_get_started": return l10n.insight_msg_get_started;
      case "insight_msg_no_data": return l10n.insight_msg_no_data;
      case "insight_msg_no_activity_7d": return l10n.insight_msg_no_activity_7d;
      case "insight_msg_no_activity_recent": return l10n.insight_msg_no_activity_recent;
      case "insight_msg_trend_decreased": return l10n.insight_msg_trend_decreased;
      case "insight_msg_trend_consistent": return l10n.insight_msg_trend_consistent;
      case "insight_msg_recent_spending": return l10n.insight_msg_recent_spending(v1, v2);
      case "insight_msg_top_spender_similar": return l10n.insight_msg_top_spender_similar;
      case "insight_msg_top_spender": return l10n.insight_msg_top_spender(v1, v2);
      case "insight_msg_average_spending": return l10n.insight_msg_average_spending(v1);
      case "insight_msg_top_category_percent": return l10n.insight_msg_top_category_percent(v1, v2);
      case "insight_msg_top_category_balanced": return l10n.insight_msg_top_category_balanced;
      case "insight_msg_total_spent": return l10n.insight_msg_total_spent(v1);
      case "insight_msg_trend_increased": return l10n.insight_msg_trend_increased(v1);
      case "insight_msg_trend_decreased_percent": return l10n.insight_msg_trend_decreased_percent(v1);
      default: return msgKey;
    }
  }

 @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    final l10n = AppLocalizations.of(context)!;
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
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          // 👇 هنا قمنا بإضافة RefreshIndicator
          child: RefreshIndicator(
            color: const Color(0xFF2EA49E), // لون أيقونة التحميل لتناسب تصميمك
            onRefresh: () async {
              // عند السحب، نقوم بجلب أحدث البيانات من السيرفر
              await Future.wait([
                fetchParentInfo(),
                _fetchUnread(),
                _fetchInsights(),
              ]);
            },
            child: SingleChildScrollView(
              // 👇 هذا السطر ضروري جداً لكي يعمل السحب حتى لو لم تكن الشاشة ممتلئة
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              PositionedDirectional(
                                end: -2,
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
                    firstname.isNotEmpty
                        ? l10n.welcomeUser(firstname)
                        : l10n.welcome,
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
                        Text(
                          l10n.parentWallet,
                          style: const TextStyle(
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
                          title: l10n.addMoney,
                          asset: "assets/icons/addMoney.png",
                          labelStyle: fintechLabelStyle,
                          onTap: () async {
                            if (!parentHasCard) {
                              _showTealInfoBar(l10n.pleaseAddCardFirst);
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
                          title: l10n.transactions,
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
                          title: parentHasCard ? l10n.myCard : l10n.addCard,
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
                          title: l10n.insights,
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
                          title: l10n.myChildren,
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
                          title: l10n.allowance, 
                          iconData: Icons.account_balance_wallet_rounded, 
                          labelStyle: fintechLabelStyle, 
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAllowanceScreen(parentId: widget.parentId, token: widget.token)))
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // مساحة للـ Nav Bar
                ],
              ),
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
      height: 1.15,
    );

    if (parts.length == 1) {
      return Text(
        message,
        style: textStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
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

    return RichText(
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
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
    "ai-category": {
      "colors": [Color(0xFF5C6BC0), Color(0xFF9FA8DA)],
      "icon": Icons.auto_awesome,
    },
  };

  Widget _insightsSection() {
    final controller = PageController(viewportFraction: 0.88);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: controller,
            itemCount: insights.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, i) {
              final insight = insights[i];
              final type = insight["type"] ?? "";

              final titleKey = insight["title"] ?? "";
              final messageKey = insight["message"] ?? "";
              final val1 = insight["value"]?.toString();
              final val2 = insight["extraValue"]?.toString();

              final title = _getTranslatedTitle(titleKey, l10n);
              final message = type == "ai-category"
                  ? messageKey // AI Message is already translated by the model
                  : _getTranslatedMessage(messageKey, val1, val2, l10n);

              final style = insightStyles[type] ?? insightStyles["empty"]!;

              final gradient = style["colors"] as List<Color>;
              final icon = style["icon"] as IconData;

              final bool isAiInsight = type == "ai-category";

              return GestureDetector(
                onTap: isAiInsight
                    ? () {
                        _showInsightDialog(title, message);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
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

                      //const Spacer(),
                      if (isAiInsight) ...[
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Tap to expand",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
  final String? asset;
  final IconData? iconData; // 👈 إضافة دعم أيقونات Flutter
  final VoidCallback onTap;
  final TextStyle labelStyle;

  const _ActionCard({
    super.key,
    required this.title,
    this.asset,
    this.iconData,
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
              // 👇 التحقق: إذا أرسلنا أيقونة يعرضها، وإلا يعرض الصورة
              if (iconData != null)
                Icon(iconData, size: 30, color: const Color(0xFF2EA49E))
              else if (asset != null)
                Image.asset(asset!, height: 28, fit: BoxFit.contain),
                
              const SizedBox(height: 10),
              Text(title, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}