import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parent_child_overview_screen.dart';

class ParentSelectChildScreen extends StatefulWidget {
  final int parentId;
  const ParentSelectChildScreen({super.key, required this.parentId});

  @override
  State<ParentSelectChildScreen> createState() =>
      _ParentSelectChildScreenState();
}

class _ParentSelectChildScreenState extends State<ParentSelectChildScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _kids = [];

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      print('🔍 Fetching children for parentId: ${widget.parentId}');
      print('URL: http://10.0.2.2:3000/api/parent/${widget.parentId}/children');

      final url = Uri.parse(
        'http://10.0.2.2:3000/api/auth/parent/${widget.parentId}/children',
      );

      final response = await http.get(url);

      if (!mounted) return; // ✅ prevents setState() on disposed widget

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _kids = data.map((child) {
            return {
              "id": child["childid"],
              "name": child["firstname"] ?? "Unnamed",
              "balance": double.tryParse(child["balance"].toString()) ?? 0.0,
            };
          }).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load children")),
        );
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
                              childId: kid["id"],
                              childName: kid["name"],
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
