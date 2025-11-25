import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/features/auth/pages/forget_password_screen.dart';
import 'package:my_app/features/parent/widgets/parent_shell.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  late String phoneNo;
  String firstName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    phoneNo = args?['phoneNo'] ?? '';
    _fetchFirstName();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchFirstName() async {
    if (phoneNo.isEmpty) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/name/$phoneNo');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          firstName = data['firstName'] ?? '';
        });
      }
    } catch (_) {
      // Silent fail – optional: show snackbar if you want
    }
  }

  Future<void> _loginParent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/login-parent');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNo': phoneNo.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = body['token'] as String?;
        final parentId = body['parentId'];

        if (token == null || parentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login response missing token or parentId'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        // Clear any stale data before storing fresh session
        await prefs.clear();
        await prefs.setString('token', token);
        await prefs.setString('role', 'Parent');
        await prefs.setInt('parentId', parentId as int);
        await prefs.setInt(
          'tokenIssuedAt',
          DateTime.now().millisecondsSinceEpoch,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParentShell(parentId: parentId, token: token),
          ),
        );
      } else {
        final errorMessage =
            body['error'] ??
            body['message'] ??
            'Login failed, please try again';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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
          child: Column(
            children: [
              // ← زر الرجوع
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              Image.asset(
                                'assets/logo/hassalaLogo5.png',
                                width: MediaQuery.of(context).size.width * 0.90,
                                fit: BoxFit.contain,
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                firstName.isNotEmpty ? firstName : phoneNo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),

                              const SizedBox(height: 25),

                              const Text(
                                'Enter your password',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                ),
                              ),

                              const SizedBox(height: 30),

                              Material(
                                elevation: 10,
                                shadowColor: Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                                child: TextFormField(
                                  controller: passwordController,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    hintStyle: const TextStyle(
                                      color: Colors.black38,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() => _obscure = !_obscure);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.black54,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Enter password'
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 15),

                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2EA49E),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF37C4BE),
                                        Color(0xFF2EA49E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _loginParent,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            "Continue",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
