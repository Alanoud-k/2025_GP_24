import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parent_child_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

class ParentSelectChildScreen extends StatefulWidget {
  final int parentId;
  final String token;
  const ParentSelectChildScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentSelectChildScreen> createState() =>
      _ParentSelectChildScreenState();
}

class _ParentSelectChildScreenState extends State<ParentSelectChildScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _kids = [];
  String? token;

  static const String baseUrl = "http://10.0.2.2:3000";

  @override
  void initState() {
    super.initState();
    checkAuthStatus(context); // ✅ NEW
    _loadToken().then((_) => _fetchChildren());
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
  }

  Future<void> _fetchChildren() async {
    await checkAuthStatus(context);
    if (token == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication error: Missing token.")),
      );
      return;
    }

    try {
      final url = Uri.parse(
        "$baseUrl/api/auth/parent/${widget.parentId}/children",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token", // 🔥 JWT applied
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          _kids = data.map((child) {
            return {
              "id": child["childId"],
              "name": child["firstName"] ?? "Unnamed",
              "balance": double.tryParse(child["balance"].toString()) ?? 0.0,
            };
          }).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to load children (Code: ${response.statusCode})",
            ),
          ),
        );
      }
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching children: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Child"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _kids.isEmpty
          ? const Center(child: Text("No children found"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                itemCount: _kids.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final kid = _kids[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal.shade300,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      title: Text(
                        kid["name"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "Balance: ${kid["balance"].toStringAsFixed(2)} SAR",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentChildOverviewScreen(
                              parentId: widget.parentId,
                              childId:
                                  kid["id"], // ✅ ensure this is a valid number
                              childName: kid["name"],
                              token: widget.token,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
