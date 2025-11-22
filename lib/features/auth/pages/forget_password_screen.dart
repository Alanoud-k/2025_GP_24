// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ForgetPasswordScreen extends StatefulWidget {
// const ForgetPasswordScreen({super.key});

// @override
// State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
// }

// class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
// final phoneController = TextEditingController();
// bool _isLoading = false;

// @override
// void dispose() {
// phoneController.dispose();
// super.dispose();
// }

// void _onContinue() async {
// var phone = phoneController.text.trim();

// if (phone.isEmpty) {
// ScaffoldMessenger.of(context).showSnackBar(
// const SnackBar(content: Text('Please enter your phone number')),
// );
// return;
// }

// if (phone.startsWith('+966')) {
// phone = phone.replaceFirst('+966', '0');
// }
// if (phone.startsWith('966')) {
// phone = phone.replaceFirst('966', '0');
// }

// final phonePattern = RegExp(r'^05\d{8}$');
// if (!phonePattern.hasMatch(phone)) {
// ScaffoldMessenger.of(context).showSnackBar(
// const SnackBar(content: Text('Invalid phone number format')),
// );
// return;
// }

// setState(() => _isLoading = true);

// try {
// final response = await http.post(
// //Uri.parse('http://10.0.2.2:3000/api/auth/check-user'),
// //Uri.parse('http://localhost:3000/api/auth/forgot-password'),
// Uri.parse('http://10.0.2.2:3000/api/auth/forgot-password'),
// headers: {'Content-Type': 'application/json'},
// body: jsonEncode({'phoneNo': phone}),
// );

// setState(() => _isLoading = false);

// if (!mounted) return;

// if (response.statusCode == 200) {
// if (mounted) {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(
// content: Text('A new password was sent to your phone number. You can change it later in Settings.'),
// backgroundColor: Colors.green,
// ),
// );
// }
// } else {
// final data = jsonDecode(response.body);
// if (mounted) {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(
// content: Text('❌ ${data['error']}'),
// backgroundColor: Colors.red,
// ),
// );
// }
// }
// } catch (e) {
// setState(() => _isLoading = false);
// if (mounted) {
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(content: Text('Error connecting to server: $e')),
// );
// }
// }
// }

// @override
// Widget build(BuildContext context) {
// const primary = Color(0xFF1ABC9C);

// return Scaffold(
// appBar: AppBar(
// leading: const BackButton(color: Colors.black87),
// backgroundColor: Colors.transparent,
// elevation: 0,
// ),
// body: Container(
// decoration: const BoxDecoration(
// gradient: LinearGradient(
// begin: Alignment.topCenter,
// end: Alignment.bottomCenter,
// colors: [Color(0xFFF7F8FA), Color(0xFFE9E9E9)],
// stops: [0.64, 1.0],
// ),
// ),
// child: SafeArea(
// child: Center(
// child: ConstrainedBox(
// constraints: const BoxConstraints(maxWidth: 380),
// child: Padding(
// padding: const EdgeInsets.symmetric(horizontal: 24),
// child: SingleChildScrollView(
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.center,
// children: [
// const SizedBox(height: 10),

// // --- الشعار ---
// Image.asset(
// 'assets/logo/hassalaLogo2.png',
// width: 350,
// fit: BoxFit.contain,
// ),
// const SizedBox(height: 25),

// // --- النص الرئيسي ---
// const Text(
// "Enter Your Phone Number",
// textAlign: TextAlign.center,
// style: TextStyle(
// fontSize: 18,
// fontWeight: FontWeight.w500,
// color: Color(0xFF222222),
// ),
// ),
// const SizedBox(height: 30),

// // --- Phone Number ---
// Material(
// elevation: 3,
// shadowColor: const Color(0x22000000),
// borderRadius: BorderRadius.circular(14),
// child: TextField(
// controller: phoneController,
// keyboardType: TextInputType.phone,
// decoration: InputDecoration(
// labelText: 'Phone Number',
// labelStyle: const TextStyle(
// color: Colors.black45,
// fontSize: 16,
// ),
// filled: true,
// fillColor: Colors.white,
// contentPadding: const EdgeInsets.symmetric(
// horizontal: 16,
// vertical: 16,
// ),
// border: OutlineInputBorder(
// borderRadius: BorderRadius.circular(14),
// borderSide: BorderSide.none,
// ),
// ),
// ),
// ),
// const SizedBox(height: 40),

// // --- زر Continue ---
// SizedBox(
// width: double.infinity,
// child: ElevatedButton(
// onPressed: _isLoading ? null : _onContinue,
// style: ButtonStyle(
// backgroundColor: WidgetStateProperty.all<Color>(
// primary,
// ),
// foregroundColor: WidgetStateProperty.all<Color>(
// Colors.white,
// ),
// elevation: WidgetStateProperty.all<double>(6),
// shadowColor: WidgetStateProperty.all<Color>(
// primary.withValues(alpha: 0.35),
// ),
// padding: WidgetStateProperty.all<EdgeInsets>(
// const EdgeInsets.symmetric(vertical: 16),
// ),
// shape:
// WidgetStateProperty.all<RoundedRectangleBorder>(
// RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(22),
// ),
// ),
// textStyle: WidgetStateProperty.all<TextStyle>(
// const TextStyle(
// fontSize: 18,
// fontWeight: FontWeight.w700,
// ),
// ),
// ),
// child: _isLoading
// ? const CircularProgressIndicator(
// color: Colors.white,
// )
// : const Text("Continue"),
// ),
// ),
// const SizedBox(height: 24),
// ],
// ),
// ),
// ),
// ),
// ),
// ),
// ),
// );
// }
// }
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final phoneController = TextEditingController();
  final answerController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _step = 0;
  String phone = '';

  @override
  void dispose() {
    phoneController.dispose();
    answerController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*])').hasMatch(password)) {
      return false;
    }
    return true;
  }

  Future<void> _checkPhone() async {
    phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }

    if (phone.startsWith('+966')) phone = phone.replaceFirst('+966', '0');
    if (phone.startsWith('966')) phone = phone.replaceFirst('966', '0');

    final phoneRegex = RegExp(r'^05\d{8}\$');
    if (!phoneRegex.hasMatch(phone)) {
      _showSnack('Invalid phone number format');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/check-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone}),
      );

      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == true) {
          setState(() => _step = 1);
        } else {
          _showSnack('Phone number not registered');
        }
      } else {
        _showSnack(jsonDecode(response.body)['error'] ?? 'Something went wrong');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e');
    }
  }

  Future<void> _verifyAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty) {
      _showSnack('Please answer the security question');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/verify-security-answer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone, 'answer': answer}),
      );
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        setState(() => _step = 2);
      } else {
        _showSnack(jsonDecode(response.body)['error'] ?? 'Incorrect answer');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e');
    }
  }

  Future<void> _resetPassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('Please enter and confirm your new password');
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Passwords do not match');
      return;
    }
    if (!_validatePassword(newPass)) {
      _showSnack('Password must be at least 8 characters, and include uppercase, lowercase, number, and special character');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone, 'newPassword': newPass}),
      );

      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        _showSnack('Password reset successful. You can now log in.', isSuccess: true);
        Navigator.pushReplacementNamed(context, '/mobile');
      } else {
        _showSnack(jsonDecode(response.body)['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Image.asset('assets/logo/hassalaLogo2.png', width: 350, fit: BoxFit.contain),
                      const SizedBox(height: 25),
                      Text(
                        _step == 0
                            ? "Enter Your Phone Number"
                            : _step == 1
                                ? "Security Question"
                                : "Set New Password",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_step == 0)
                        _buildInput(phoneController, 'Phone Number', keyboardType: TextInputType.phone),
                      if (_step == 1)
                        Column(
                          children: [
                            const Text(
                              "What’s the name of the street where you lived as a child?",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 16),
                            _buildInput(answerController, 'Your Answer'),
                          ],
                        ),
                      if (_step == 2)
                        Column(
                          children: [
                            _buildInput(newPasswordController, 'New Password', obscure: true),
                            const SizedBox(height: 16),
                            _buildInput(confirmPasswordController, 'Confirm Password', obscure: true),
                          ],
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _step == 0
                                  ? _checkPhone
                                  : _step == 1
                                      ? _verifyAnswer
                                      : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_step == 0
                                  ? 'Continue'
                                  : _step == 1
                                      ? 'Verify Answer'
                                      : 'Reset Password'),
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

  Widget _buildInput(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, bool obscure = false}) {
    return Material(
      elevation: 3,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black45, fontSize: 16),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}