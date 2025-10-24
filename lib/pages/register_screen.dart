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
        Navigator.pushNamed(context, '/parentLogin');
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
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/logo/hassalaLogo.png', width: 100),
                const SizedBox(height: 20),

                // FIRST NAME
                TextFormField(
                  controller: firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter first name' : null,
                ),

                // LAST NAME
                TextFormField(
                  controller: lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter last name' : null,
                ),

                // NATIONAL ID
                TextFormField(
                  controller: nationalId,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'National ID / Iqama',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a National ID';
                    if (v.length != 10) return 'National ID must be 10 digits';
                    if (int.tryParse(v) == null) return 'Must be numeric';
                    return null;
                  },
                ),

                // DATE OF BIRTH
                TextFormField(
                  controller: dob,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
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
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select date of birth' : null,
                ),

                // PASSWORD
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
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

                const SizedBox(height: 30),

                // CONTINUE BUTTON
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _registerParent,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
