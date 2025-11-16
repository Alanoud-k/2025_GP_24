import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_config.dart'; // ✅ base URL

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController phoneController = TextEditingController();

  bool _loading = false;

  bool get _canContinue =>
      !_loading && phoneController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1ABC9C);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F8FA), Color(0xFFE9E9E9)],
            stops: [0.64, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "Welcome to",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/logo/hassalaLogo2.png',
                      width: 280,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Please Enter Your \nMobile Number",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Material(
                      elevation: 3,
                      shadowColor: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Phone number',
                          labelStyle: const TextStyle(
                            color: Colors.black45,
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        'By clicking "Continue", you agree to our Terms and\nData Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _onContinuePressed : null,
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.disabled)) {
                              return primary.withValues(alpha: 0.35);
                            }
                            return primary;
                          }),
                          foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                          elevation:
                              WidgetStateProperty.resolveWith<double>((states) {
                            return states.contains(WidgetState.disabled)
                                ? 0
                                : 6;
                          }),
                          shadowColor: WidgetStateProperty.all<Color>(
                            primary.withValues(alpha: 0.35),
                          ),
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(vertical: 18),
                          ),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          textStyle: WidgetStateProperty.all<TextStyle>(
                            const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text("Continue"),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- API call to /api/auth/check-user ---
  Future<void> _onContinuePressed() async {
    final phoneRaw = phoneController.text.trim();

    if (phoneRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return;
    }

    final phoneRegex = RegExp(r'^05\d{8}$');
    if (!phoneRegex.hasMatch(phoneRaw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid Saudi phone number starting with 05'),
        ),
      );
      return;
    }

    final phone = phoneRaw;

    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$kBaseUrl/api/auth/check-user');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone}),
      );

      // Debug logs
      debugPrint('CHECK-USER → status: ${response.statusCode}');
      debugPrint('CHECK-USER → body  : ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['exists'] == true) {
          if (data['role'] == 'Parent') {
            Navigator.pushNamed(
              context,
              '/parentLogin',
              arguments: {'phoneNo': phone},
            );
          } else {
            Navigator.pushNamed(
              context,
              '/childLogin',
              arguments: {'phoneNo': phone},
            );
          }
        } else {
          Navigator.pushNamed(
            context,
            '/register',
            arguments: {'phoneNo': phone},
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error (${response.statusCode}). Please try again later.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('CHECK-USER → exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
