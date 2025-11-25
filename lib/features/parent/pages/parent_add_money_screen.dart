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

  // ✅ فتح صفحة الدفع بدون canLaunchUrl + fallback
  Future<void> _openPaymentPage(String redirectUrl) async {
    final uri = Uri.parse(redirectUrl);

    // 1) افتحيه بمتصفح خارجي
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    // 2) لو ما فتح، افتحيه داخل التطبيق
    if (!ok) {
      final ok2 = await launchUrl(uri, mode: LaunchMode.inAppWebView);

      if (!ok2 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open payment page")),
        );
      }
    }
  }

  Future<void> _addMoney() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));
      return;
    }

    if (token == null || token!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Authentication error")));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Server returned non-JSON response (${res.statusCode})",
            ),
          ),
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
      appBar: AppBar(
        title: const Text("Add Money"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter amount to add:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g. 100",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _addMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                    : const Text("Add Money", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
