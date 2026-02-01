import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final nationalId = TextEditingController();
  final dob = TextEditingController();
  final password = TextEditingController();
  final securityAnswer = TextEditingController();
  final confirmPassword = TextEditingController(); // ✅ NEW: confirm password

  String phoneNo = '';
  bool _obscure = true;
  bool _obscureConfirm = true; // ✅ NEW: toggle confirm field
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    phoneNo = args?['phoneNo'] ?? '';
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    nationalId.dispose();
    dob.dispose();
    password.dispose();
    confirmPassword.dispose(); // ✅ NEW
    securityAnswer.dispose();
    super.dispose();
  }

  void _showErrorBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE74C3C), // 🔴 soft red
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ OPTIONAL (keep for success)
  void _showSuccessBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPasswordRequirementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Password Requirements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• At least 8 characters"),
              Text("• One uppercase letter"),
              Text("• One lowercase letter"),
              Text("• One number (0-9)"),
              Text("• One special character (!@#\$%^&*)"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String? _nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return "Required field";
    }
    if (v.trim().length < 2) {
      return "Must be at least 2 letters";
    }
    if (!RegExp(r'^[A-Za-z]+$').hasMatch(v.trim())) {
      return "Letters only (A–Z)";
    }
    return null;
  }

  // ✅ NEW: National ID / Iqama validation (10 digits)
  String? _nationalIdValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Required field";
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return "National ID / Iqama must be 10 digits";
    }
    return null;
  }

  // ✅ NEW: Confirm password validation
  String? _confirmPasswordValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Confirm your password";
    if (value != password.text.trim()) return "Passwords do not match";
    return null;
  }

  Future<void> _registerParent() async {
    if (!_formKey.currentState!.validate()) return;
    // ✅ NEW: stop double submissions
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/register-parent');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName.text.trim(),
          'lastName': lastName.text.trim(),
          'nationalId': int.tryParse(nationalId.text.trim()),
          'DoB': dob.text.trim(),
          'phoneNo': phoneNo.trim(),
          'password': password.text.trim(),
          'securityAnswer': securityAnswer.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ✅ CHANGED: success bar style (optional, keep if you want)
        _showSuccessBar("Registered successfully! Please log in.");

        Navigator.pushReplacementNamed(
          context,
          '/parentLogin',
          arguments: {'phoneNo': phoneNo},
        );
      } else {
        // ✅ CHANGED: backend error popup now uses red Hassala bar
        final decoded = jsonDecode(response.body);
        _showErrorBar(decoded['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (!mounted) return;
      // ✅ CHANGED: network error uses same red bar
      _showErrorBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const hassalaGreen1 = Color(0xFF37C4BE);
    const hassalaGreen2 = Color(0xFF2EA49E);

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
              /// ← زر الرجوع
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
                              const SizedBox(height: 20),

                              Transform.translate(
                                offset: const Offset(0, 70),
                                child: Image.asset(
                                  'assets/logo/hassalaLogo5.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.70,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                "Create Your Account",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),

                              const SizedBox(height: 20),

                              _field(
                                firstName,
                                "First Name",
                                validator: _nameValidator,
                              ),
                              const SizedBox(height: 15),

                              _field(
                                lastName,
                                "Last Name",
                                validator: _nameValidator,
                              ),
                              const SizedBox(height: 15),

                              _field(
                                nationalId,
                                "National ID / Iqama",
                                keyboardType: TextInputType.number,
                                validator: _nationalIdValidator,
                              ),
                              const SizedBox(height: 15),

                              _buildDateField(),
                              const SizedBox(height: 15),

                              Material(
                                elevation: 10,
                                shadowColor: Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                                child: TextFormField(
                                  controller: password,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    // ✅ NEW: show info dialog button (optional)
                                    prefixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.black54,
                                      ),
                                      onPressed: () =>
                                          _showPasswordRequirementsDialog(
                                            context,
                                          ),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 26,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return "Enter password";
                                    if (v.length < 8)
                                      return "At least 8 characters";
                                    if (!RegExp(
                                      r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*])',
                                    ).hasMatch(v)) {
                                      return "Must include upper/lower/number/special";
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 15),

                              // ✅ NEW: CONFIRM PASSWORD FIELD
                              Material(
                                elevation: 10,
                                shadowColor: Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                                child: TextFormField(
                                  controller: confirmPassword,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    hintText: "Confirm Password",
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 26,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: _confirmPasswordValidator,
                                ),
                              ),

                              const SizedBox(height: 15),

                              _field(
                                securityAnswer,
                                "Security Question Answer",
                                suffix: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey,
                                ),
                              ),

                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text(
                                  "What’s the name of the street where you lived as a child?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

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
                                    onPressed: _registerParent,
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
                                    child: const Text(
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

                              const SizedBox(height: 20),
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

  Widget _field(
    controller,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        validator:
            validator ??
            (v) => v == null || v.isEmpty ? "Required field" : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Material(
      elevation: 10,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: TextFormField(
        controller: dob,
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Date of Birth",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        onTap: () async {
          FocusScope.of(context).unfocus();

          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
          );

          if (picked != null) {
            dob.text = picked.toIso8601String().split('T').first;
          }
        },
        validator: (v) => v == null || v.isEmpty ? "Select date" : null,
      ),
    );
  }
}
