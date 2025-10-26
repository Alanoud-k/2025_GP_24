import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'forget_password_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final nationalIdController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  late String phoneNo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get phone number from previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    phoneNo = args?['phoneNo'] ?? '';
  }

  @override
  void dispose() {
    nationalIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginParent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
  final url = Uri.parse('http://10.0.2.2:3000/api/auth/login-parent');
//final url = Uri.parse('http://localhost:3000/api/auth/check-user');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNo': phoneNo.trim(),
          'nationalId': int.tryParse(nationalIdController.text.trim()),
          'password': passwordController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/parentHome',
          arguments: {'parentId': data['parentId']},
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? error['error'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black87),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        Image.asset(
                          'assets/logo/hassalaLogo2.png',
                          width: 350,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 25),

                        Text(
                          "Login for $phoneNo",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 25),

                        const Text(
                          "Enter your National ID / Iqama and Password",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // National ID field
                        Material(
                          elevation: 3,
                          shadowColor: const Color(0x22000000),
                          borderRadius: BorderRadius.circular(14),
                          child: TextFormField(
                            controller: nationalIdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'National ID / Iqama',
                              labelStyle: const TextStyle(
                                color: Colors.black45,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Enter your National ID';
                              if (v.length != 10) return 'Must be 10 digits';
                              if (int.tryParse(v) == null)
                                return 'Must be numeric';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        Material(
                          elevation: 3,
                          shadowColor: const Color(0x22000000),
                          borderRadius: BorderRadius.circular(14),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Colors.black45,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Enter your password';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Forget password
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgetPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginParent,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                primary,
                              ),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                Colors.white,
                              ),
                              elevation: MaterialStateProperty.all<double>(6),
                              shape:
                                  MaterialStateProperty.all<
                                    RoundedRectangleBorder
                                  >(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(vertical: 16),
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
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}