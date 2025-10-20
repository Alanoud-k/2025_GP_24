import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({Key? key}) : super(key: key);

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Center(
              child: Image.asset('assets/logo/hassalaLogo.png', width: 100),
            ),
            const SizedBox(height: 30),
            const Text(
              "Please Enter Mobile Number",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+966 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                final phone = phoneController.text.trim();

                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your phone number'),
                    ),
                  );
                  return;
                }

                try {
                  // use 10.0.2.2 to reach localhost from the Android emulator
                  final response = await http.post(
                    Uri.parse('http://10.0.2.2:3000/api/auth/check-user'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'phoneNo': phone}),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);

                    if (data['exists'] == true) {
                      if (data['role'] == 'Parent') {
                        Navigator.pushNamed(context, '/parentLogin');
                      } else {
                        Navigator.pushNamed(context, '/childLogin');
                      }
                    } else {
                      Navigator.pushNamed(context, '/register');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Server error. Please try again later.'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },

              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
