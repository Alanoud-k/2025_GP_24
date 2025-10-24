import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController phoneController = TextEditingController();

  bool get _canContinue => phoneController.text.trim().isNotEmpty;

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
    const primary = Color(0xFF1ABC9C); // اللون الرئيسي (تركوازي)

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
              Color(0xFFF7F8FA), // الأعلى
              Color(0xFFE9E9E9), // الأسفل
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // --- Welcome ---
                    const Text(
                      "Welcome to",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- الشعار بدون خلفية ---
                    Image.asset(
                      'assets/logo/hassalaLogo2.png',
                      width: 350,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 25),

                    // --- النص التوضيحي ---
                    const Text(
                      "Please Enter Mobile Number",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- حقل إدخال رقم الجوال (نفس التصميم) ---
                    Material(
                      elevation: 3,
                      shadowColor: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '+966 ',
                          prefixStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          hintText: "Phone number",
                          hintStyle: const TextStyle(
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

                    const Spacer(),

                    // --- الشروط (أسود) ---
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        'By clicking "Continue", you agree to our Terms and\nData Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- زر Continue (تفاعلي: يتغير لونه/ارتفاعه حسب الإدخال) ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _onContinuePressed : null,
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (states) {
                              if (states.contains(MaterialState.disabled)) {
                                return primary.withOpacity(0.35); // فاتح عند التعطيل
                              }
                              return primary; // غامق عند التفعيل
                            },
                          ),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          elevation: MaterialStateProperty.resolveWith<double>(
                            (states) => states.contains(MaterialState.disabled)
                                ? 0
                                : 6,
                          ),
                          shadowColor: MaterialStateProperty.all<Color>(
                            primary.withOpacity(0.35),
                          ),
                          padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
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
                        child: const Text("Continue"),
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
    );
  }

  // --- عملية التحقق والانتقال ---
  Future<void> _onContinuePressed() async {
    final phoneRaw = phoneController.text.trim();

    if (phoneRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return;
    }

    // يبدأ بـ 5 وطوله 9 أرقام (بدون +966 لأننا نضيفها عند الإرسال)
    final phoneRegex = RegExp(r'^5\d{8}$');
    if (!phoneRegex.hasMatch(phoneRaw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Saudi phone number')),
      );
      return;
    }

    final phone = '+966$phoneRaw';

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/check-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['exists'] == true) {
          if (data['role'] == 'Parent') {
            Navigator.pushNamed(context, '/parentLogin');
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
          const SnackBar(content: Text('Server error. Please try again later.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
