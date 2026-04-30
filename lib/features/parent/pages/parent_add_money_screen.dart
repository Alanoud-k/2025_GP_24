import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/l10n/app_localizations.dart';
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
    token = prefs.getString("token") ?? widget.token; 
  }

  void _showMessageBar(
    String message, {
    Color backgroundColor = const Color(0xFF37C4BE), 
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: duration,
      ),
    );
  }

  static const Color _tealMsg = Color(0xFF37C4BE);
  static const Color _redMsg = Color(0xFFE74C3C);
  static const Color _greenMsg = Color(0xFF27AE60);

  Future<void> _openPaymentPage(String redirectUrl) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(redirectUrl);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) {
      final ok2 = await launchUrl(uri, mode: LaunchMode.inAppWebView);

      if (!ok2 && mounted) {
        _showMessageBar(
          l10n.unableToOpenPaymentPage,
          backgroundColor: _redMsg,
        );
      }
    }
  }

  Future<void> _addMoney() async {
    final amountText = _amountController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessageBar(l10n.enterValidAmount, backgroundColor: _redMsg);
      return;
    }

    if (token == null || token!.isEmpty) {
      _showMessageBar(l10n.authenticationError, backgroundColor: _redMsg);
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

      debugPrint("Add money status: ${res.statusCode}");
      debugPrint("Add money body: ${res.body}");

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
        // ✅ تم إصلاح مشكلة الأقواس هنا
        _showMessageBar(
          l10n.somethingWentWrong("Server returned non-JSON response (${res.statusCode})"), 
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
          _showMessageBar(l10n.redirectUrlMissing, backgroundColor: _redMsg);
        }
      } else {
        _showMessageBar(data["message"] ?? l10n.addMoneyFailed, backgroundColor: _redMsg);
      }
    } catch (e) {
      _showMessageBar(l10n.somethingWentWrong(e.toString()), backgroundColor: _redMsg);
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(24),
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
                  Text(
                    l10n.addMoney,
                    style: const TextStyle(
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
                padding: const EdgeInsetsDirectional.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.enterAmount, 
                      style: const TextStyle(
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
                          padding: const EdgeInsetsDirectional.all(12),
                          child: Image.asset(
                            'assets/icons/Sar.png',
                            width: 20,
                            height: 20,
                            color: Colors.grey,
                          ),
                        ),
                        hintText: l10n.enterAmount,
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

                    const SizedBox(height: 12), 
                    // BUTTON -------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addMoney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37C4BE),
                          padding: const EdgeInsetsDirectional.symmetric(vertical: 16),
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
                            : Text(
                                l10n.proceedToPayment,
                                style: const TextStyle(
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