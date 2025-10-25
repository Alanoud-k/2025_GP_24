import 'package:flutter/material.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // مؤقت للتجربة

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A reset link has been sent to ${phoneController.text}'),
        backgroundColor: Colors.green,
      ),
    );
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
            colors: [
              Color(0xFFF7F8FA),
              Color(0xFFE9E9E9),
            ],
            stops: [0.64, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // --- الشعار ---
                      Image.asset(
                        'assets/logo/hassalaLogo2.png',
                        width: 350,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 25),

                      // --- النص الرئيسي ---
                      const Text(
                        "Enter Your Phone Number",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- Phone Number ---
                      Material(
                        elevation: 3,
                        shadowColor: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(14),
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
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
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- زر Continue ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onContinue,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(primary),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            elevation: MaterialStateProperty.all<double>(6),
                            shadowColor: MaterialStateProperty.all<Color>(
                              primary.withOpacity(0.35),
                            ),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            textStyle: MaterialStateProperty.all<TextStyle>(
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Continue"),
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
    );
  }
}
