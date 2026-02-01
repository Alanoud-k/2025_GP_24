/*import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_config.dart';

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _loading = false;

  bool get _canContinue => !_loading && phoneController.text.trim().isNotEmpty;

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
    const hassalaLinkColor = Color(0xFF2EA49E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      /// Logo
                      Transform.translate(
                        offset: const Offset(0, 40),
                        child: Image.asset(
                          'assets/logo/hassalaLogo5.png',
                          width: MediaQuery.of(context).size.width * 0.9,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Welcome
                      const Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Subtitle
                      const Text(
                        "Please enter your mobile number",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// Input
                      Material(
                        elevation: 10,
                        shadowColor: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '05XXXXXXXX',
                              hintStyle: TextStyle(
                                color: Colors.black38,
                                fontSize: 16,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// Terms
                      Text.rich(
                        TextSpan(
                          text: 'By clicking "Continue", you agree to our ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms',
                              style: const TextStyle(
                                color: hassalaLinkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Data Privacy Policy',
                              style: const TextStyle(
                                color: hassalaLinkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 35),

                      /// Button
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _canContinue
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF37C4BE),
                                      Color(0xFF2EA49E),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.4),
                                      Colors.grey.withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ElevatedButton(
                            onPressed: _canContinue ? _onContinuePressed : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
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
    );
  }

  // API LOGIC (unchanged)
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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['exists'] == true) {
          Navigator.pushNamed(
            context,
            data['role'] == 'Parent' ? '/parentLogin' : '/childLogin',
            arguments: {'phoneNo': phone},
          );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}*/
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_config.dart';

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  // ✅ NEW: use Form validation like Register screen
  final _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();

  bool _loading = false;
  bool _showPhoneHelp = false; // ✅ NEW: toggle help under field

  bool get _canContinue => !_loading;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // ✅ NEW: Hassala-style red popup for BACKEND/NETWORK errors only
  void _showErrorBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ NEW: inline validator (same idea as registration)
  String? _phoneValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Please enter your mobile number';
    if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
      return 'Enter a valid Saudi phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const hassalaLinkColor = Color(0xFF2EA49E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Form(
                    // ✅ NEW: Form wrapper
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        /// Logo
                        Transform.translate(
                          offset: const Offset(0, 40),
                          child: Image.asset(
                            'assets/logo/hassalaLogo5.png',
                            width: MediaQuery.of(context).size.width * 0.9,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Welcome
                        const Text(
                          "Welcome",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Subtitle
                        const Text(
                          "Please enter your mobile number",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// ✅ CHANGED: TextField -> TextFormField + validator + error style
                        Material(
                          elevation: 10,
                          shadowColor: Colors.black12,
                          borderRadius: BorderRadius.circular(20),
                          child: TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            validator: _phoneValidator, // ✅ NEW
                            decoration: InputDecoration(
                              hintText: '05XXXXXXXX',
                              hintStyle: const TextStyle(
                                color: Colors.black38,
                                fontSize: 16,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              filled: true,
                              fillColor: Colors.white,

                              // ✅ NEW: inline error UI (similar to your form)
                              errorStyle: const TextStyle(
                                color: Color(0xFFE74C3C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),

                              // ✅ NEW: show red border when invalid
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE74C3C),
                                  width: 1.4,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE74C3C),
                                  width: 1.4,
                                ),
                              ),

                              // ✅ NEW: info (!) icon to show requirements
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPhoneHelp
                                      ? Icons.info
                                      : Icons.info_outline,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _showPhoneHelp = !_showPhoneHelp,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // ✅ NEW: small help box under field (optional)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: !_showPhoneHelp
                              ? const SizedBox(height: 0)
                              : Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF2EA49E,
                                      ).withOpacity(0.25),
                                    ),
                                  ),
                                  child: const Text(
                                    "Number must be 10 digits and start with 05.\nExample: 05XXXXXXXX",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2C3E50),
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 25),

                        /// Terms
                        Text.rich(
                          TextSpan(
                            text: 'By clicking "Continue", you agree to our ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms',
                                style: const TextStyle(
                                  color: hassalaLinkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // optional route
                                  },
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Data Privacy Policy',
                                style: const TextStyle(
                                  color: hassalaLinkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // optional route
                                  },
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 35),

                        /// Button
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _canContinue
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF37C4BE),
                                        Color(0xFF2EA49E),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.withOpacity(0.4),
                                        Colors.grey.withOpacity(0.3),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _onContinuePressed,
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
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
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
      ),
    );
  }

  // ✅ CHANGED: validation now uses Form (no quick grey snackbar)
  Future<void> _onContinuePressed() async {
    FocusScope.of(context).unfocus();

    // ✅ NEW: triggers red border + inline error text
    if (!_formKey.currentState!.validate()) return;

    final phone = phoneController.text.trim();

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('$kBaseUrl/api/auth/check-user');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['exists'] == true) {
          Navigator.pushNamed(
            context,
            data['role'] == 'Parent' ? '/parentLogin' : '/childLogin',
            arguments: {'phoneNo': phone},
          );
        } else {
          Navigator.pushNamed(
            context,
            '/register',
            arguments: {'phoneNo': phone},
          );
        }
      } else {
        // ✅ backend/server error -> red floating bar
        _showErrorBar(
          'Server error (${response.statusCode}). Please try again later.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      // ✅ network error -> red floating bar
      _showErrorBar('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
