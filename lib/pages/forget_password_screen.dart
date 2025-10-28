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
bool _isLoading = false;

@override
void dispose() {
phoneController.dispose();
super.dispose();
}

void _onContinue() async {
var phone = phoneController.text.trim();

if (phone.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please enter your phone number')),
);
return;
}

if (phone.startsWith('+966')) {
phone = phone.replaceFirst('+966', '0');
}
if (phone.startsWith('966')) {
phone = phone.replaceFirst('966', '0');
}

final phonePattern = RegExp(r'^05\d{8}$');
if (!phonePattern.hasMatch(phone)) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Invalid phone number format')),
);
return;
}

setState(() => _isLoading = true);

try {
final response = await http.post(
//Uri.parse('http://10.0.2.2:3000/api/auth/check-user'),
//Uri.parse('http://localhost:3000/api/auth/forgot-password'),
Uri.parse('http://10.0.2.2:3000/api/auth/forgot-password'),
headers: {'Content-Type': 'application/json'},
body: jsonEncode({'phoneNo': phone}),
);

setState(() => _isLoading = false);

if (!mounted) return;

if (response.statusCode == 200) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('✅ Password reset successful!'),
backgroundColor: Colors.green,
),
);
}
} else {
final data = jsonDecode(response.body);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('❌ ${data['error']}'),
backgroundColor: Colors.red,
),
);
}
}
} catch (e) {
setState(() => _isLoading = false);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error connecting to server: $e')),
);
}
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
backgroundColor: WidgetStateProperty.all<Color>(
primary,
),
foregroundColor: WidgetStateProperty.all<Color>(
Colors.white,
),
elevation: WidgetStateProperty.all<double>(6),
shadowColor: WidgetStateProperty.all<Color>(
primary.withValues(alpha: 0.35),
),
padding: WidgetStateProperty.all<EdgeInsets>(
const EdgeInsets.symmetric(vertical: 16),
),
shape:
WidgetStateProperty.all<RoundedRectangleBorder>(
RoundedRectangleBorder(
borderRadius: BorderRadius.circular(22),
),
),
textStyle: WidgetStateProperty.all<TextStyle>(
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