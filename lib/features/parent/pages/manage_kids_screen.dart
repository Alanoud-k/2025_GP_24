import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManageKidsScreen extends StatefulWidget {
  const ManageKidsScreen({super.key});

  @override
  State<ManageKidsScreen> createState() => _ManageKidsScreenState();
}

class _ManageKidsScreenState extends State<ManageKidsScreen> {
  List children = [];
  bool _loading = true;
  late int parentId;
  final TextEditingController password = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    parentId = args?['parentId'] ?? 0;
    print('📱 ManageKidsScreen received parentId: $parentId');
    fetchChildren(); // ✅ Only called after parentId is ready
  }

  Future<void> fetchChildren() async {
    setState(() => _loading = true);
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/child/$parentId');
    //final url = Uri.parse('http://localhost:3000/api/auth/check-user');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          children = decoded is List ? decoded : [];
          _loading = false;
        });
      } else {
        throw Exception('Failed to load children');
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching children: $e')));
    }
  }

  void _openAddChildDialog() {
    final _formKey = GlobalKey<FormState>();
    final firstName = TextEditingController();
    final nationalId = TextEditingController();
    final phoneNo = TextEditingController();
    final dob = TextEditingController();
    //final password = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Child"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildValidatedField(
                    controller: firstName,
                    label: "First Name",
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter first name';
                      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v)) {
                        return 'Letters only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildValidatedField(
                    controller: nationalId,
                    label: "National ID",
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter National ID';
                      if (v.length != 10) return 'Must be 10 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildValidatedField(
                    controller: phoneNo,
                    label: "Phone Number",
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter phone number';
                      if (!RegExp(r'^05\d{8}$').hasMatch(v)) {
                        return 'Invalid format (must start with 05)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // 🎯 Date Picker
                  TextFormField(
                    controller: dob,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Date of Birth",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Select date of birth';
                      }
                      return null;
                    },
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2010),
                        firstDate: DateTime(2007),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        dob.text = pickedDate
                            .toIso8601String()
                            .split('T')
                            .first;
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildValidatedField(
                    controller: password,
                    label: "Password",
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter password';
                      if (v.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(
                        r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
                      ).hasMatch(v)) {
                        return 'Use upper, lower, number & special character (!@#\$%^&*)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await registerChild(
                  firstName.text.trim(),
                  nationalId.text.trim(),
                  phoneNo.text.trim(),
                  dob.text.trim(),
                  password.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> registerChild(
    String firstName,
    String nationalId,
    String phoneNo,
    String dob,
    String password,
  ) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/child/register');
    final body = {
      "parentId": parentId,
      "firstName": firstName,
      "nationalId": int.tryParse(nationalId),
      "phoneNo": phoneNo,
      "dob": dob,
      "password": password,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Child added successfully!")),
        );
        fetchChildren(); // ✅ Refresh after adding
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to add child')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1ABC9C);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Kids"),
        backgroundColor: primary,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: _openAddChildDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : children.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.family_restroom, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "No children added yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchChildren,
              child: ListView.builder(
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final kid = children[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(kid['firstname'] ?? 'Unnamed'),
                      subtitle: Text('Phone: ${kid['phoneno']}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
