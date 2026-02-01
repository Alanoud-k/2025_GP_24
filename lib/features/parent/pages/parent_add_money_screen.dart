import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/core/api_config.dart';

class ParentAddMoneyScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentAddMoneyScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentAddMoneyScreen> createState() => _ParentAddMoneyScreenState();
}

class _ParentAddMoneyScreenState extends State<ParentAddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String? token;
  final String baseUrl = ApiConfig.baseUrl;

  // Switch between local and railway when needed
  //static const String backendUrl = "https://2025gp24-production.up.railway.app";
  // static const String backendUrl = "http://10.0.2.2:3000";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token; // fallback من الwidget
  }

  // ✅✅ NEW: Unified Hassala-style message bar (teal / red / green)
  void _showMessageBar(
    String message, {
    Color backgroundColor = const Color(0xFF37C4BE), // default teal
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: duration,
      ),
    );
  }

  // ✅ Colors for consistency (optional helper)
  static const Color _tealMsg = Color(0xFF37C4BE);
  static const Color _redMsg = Color(0xFFE74C3C);
  static const Color _greenMsg = Color(0xFF27AE60);

  // ✅ فتح صفحة الدفع بدون canLaunchUrl + fallback
  Future<void> _openPaymentPage(String redirectUrl) async {
    final uri = Uri.parse(redirectUrl);

    // 1) افتحيه بمتصفح خارجي
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    // 2) لو ما فتح، افتحيه داخل التطبيق
    if (!ok) {
      final ok2 = await launchUrl(uri, mode: LaunchMode.inAppWebView);

      if (!ok2 && mounted) {
        _showMessageBar(
          "Unable to open payment page",
          backgroundColor: _redMsg,
        );
      }
    }
  }

  Future<void> _addMoney() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessageBar("Enter a valid amount", backgroundColor: _redMsg);
      return;
    }

    if (token == null || token!.isEmpty) {
      // ✅ CHANGED: unified popup
      _showMessageBar("Authentication error", backgroundColor: _redMsg);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-payment/${widget.parentId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"parentId": widget.parentId, "amount": amount}),
      );

      print("Add money status: ${res.statusCode}");
      print("Add money body: ${res.body}");

      if (res.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }

      final contentType = res.headers["content-type"] ?? "";
      if (!contentType.contains("application/json")) {
        // ✅ CHANGED: unified popup
        _showMessageBar(
          "Server returned non-JSON response (${res.statusCode})",
          backgroundColor: _redMsg,
        );
        return;
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        final redirectUrl = data["redirectUrl"];
        if (redirectUrl != null && redirectUrl.toString().isNotEmpty) {
          await _openPaymentPage(redirectUrl);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Redirect URL missing")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Add money failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // HEADER -------------------------------------------------------
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2C3E50),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Add Money",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // MAIN CARD ---------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Amount",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // AMOUNT TEXT FIELD -------------------------------------
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/icons/Sar.png',
                            width: 20,
                            height: 20,
                            color: Colors.grey,
                          ),
                        ),
                        //hintText: "e.g. 100",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF37C4BE),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12), // 👈 small space
                    // BUTTON -------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addMoney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37C4BE),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Proceed to Payment",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
