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

  final int parentId = 1; // 👈 replace with logged-in parent ID later

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }

  Future<void> fetchChildren() async {
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/child/$parentId');
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
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openAddChildDialog() {
    final firstName = TextEditingController();
    final nationalId = TextEditingController();
    final phoneNo = TextEditingController();
    final dob = TextEditingController();
    final pin = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Child"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildField(firstName, "First Name"),
                _buildField(
                  nationalId,
                  "National ID",
                  keyboardType: TextInputType.number,
                ),
                _buildField(
                  phoneNo,
                  "Phone Number",
                  keyboardType: TextInputType.number,
                ),
                _buildField(dob, "Date of Birth (YYYY-MM-DD)"),
                _buildField(pin, "PIN (4 digits)", obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await registerChild(
                  firstName.text.trim(),
                  nationalId.text.trim(),
                  phoneNo.text.trim(),
                  dob.text.trim(),
                  pin.text.trim(),
                );
                Navigator.pop(context);
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
    String pin,
  ) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/child/register');
    final body = {
      "parentId": parentId,
      "firstName": firstName,
      "nationalId": int.tryParse(nationalId),
      "phoneNo": phoneNo,
      "DoB": dob,
      "PIN": pin,
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
        fetchChildren();
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

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
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
          ? const Center(child: Text("No children added yet"))
          : ListView.builder(
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
    );
  }
}
