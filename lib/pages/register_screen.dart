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

  late String phoneNo;

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
    super.dispose();
  }

  Future<void> _registerParent() async {
    if (!_formKey.currentState!.validate()) return;

  final url = Uri.parse('http://10.0.2.2:3000/api/auth/register-parent');
//final url = Uri.parse('http://localhost:3000/api/auth/check-user');

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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect to parent login after success
        Navigator.pushNamed(
          context,
          '/parentLogin',
          arguments: {'phoneNo': phoneNo},
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1ABC9C); // نفس اللون التركوازي

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
                child: Form(
                  key: _formKey,
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

                        // --- النص التوضيحي ---
                        const Text(
                          "Register",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // FIRST NAME
                        _buildTextField(
                          controller: firstName,
                          label: 'First name',
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter first name'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // LAST NAME
                        _buildTextField(
                          controller: lastName,
                          label: 'Last name',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter last name' : null,
                        ),
                        const SizedBox(height: 20),

                        // NATIONAL ID
                        _buildTextField(
                          controller: nationalId,
                          label: 'National ID / Iqama',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Enter a National ID';
                            if (v.length != 10)
                              return 'National ID must be 10 digits';
                            if (int.tryParse(v) == null)
                              return 'Must be numeric';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // DATE OF BIRTH
                        _buildDateField(),
                        const SizedBox(height: 20),

                        // PASSWORD
                        _buildTextField(
                          controller: password,
                          label: 'Password',
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter password';
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(
                              r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)',
                            ).hasMatch(v)) {
                              return 'Use at least 1 upper, 1 lower, 1 number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 40),

                        // --- زر Continue ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _registerParent,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                primary,
                              ),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                Colors.white,
                              ),
                              elevation: MaterialStateProperty.all<double>(6),
                              shadowColor: MaterialStateProperty.all<Color>(
                                primary.withOpacity(0.35),
                              ),
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(vertical: 16),
                              ),
                              shape:
                                  MaterialStateProperty.all<
                                    RoundedRectangleBorder
                                  >(
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
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return Material(
      elevation: 3,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black45, fontSize: 16),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField() {
    return Material(
      elevation: 3,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(14),
      child: TextFormField(
        controller: dob,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Date of birth',
          labelStyle: const TextStyle(color: Colors.black45, fontSize: 16),
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
        onTap: () async {
          FocusScope.of(context).unfocus();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              dob.text = picked.toIso8601String().split('T').first;
            });
          }
        },
        validator: (v) =>
            v == null || v.isEmpty ? 'Select date of birth' : null,
      ),
    );
  }
}
