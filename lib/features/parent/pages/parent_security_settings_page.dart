import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

class ParentSecuritySettingsPage extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentSecuritySettingsPage({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentSecuritySettingsPage> createState() =>
      _ParentSecuritySettingsPageState();
}

class _ParentSecuritySettingsPageState
    extends State<ParentSecuritySettingsPage> {
  List<dynamic> children = [];
  bool isLoadingChildren = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    await _loadToken();
    await fetchChildren();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
  }

  Future<bool> _handleExpired(int statusCode) async {
    if (statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return true;
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
      return true;
    }
    return false;
  }

  Future<void> fetchChildren() async {
    setState(() => isLoadingChildren = true);

    if (token == null) {
      _showError("Missing token — please log in again");
      return;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children',
    );

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          children = data is List ? data : data["children"] ?? [];
        });
      } else {
        _showError("Failed to load children");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => isLoadingChildren = false);
    }
  }

  // -------------------------------------------------------------
  // CHANGE PARENT PASSWORD
  // -------------------------------------------------------------
  void _showChangeParentPasswordDialog() {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Current Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showPasswordRequirements(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm New Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("Change"),
                  onPressed: () async {
                    final newPass = newPassword.text.trim();

                    if (newPass != confirmPassword.text.trim()) {
                      _showError("Passwords do not match");
                      return;
                    }

                    if (!_validatePassword(newPass)) {
                      _showError("Password does not meet requirements");
                      return;
                    }

                    final success = await _changeParentPassword(
                      currentPassword.text.trim(),
                      newPass,
                    );

                    if (success && mounted) Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _changeParentPassword(
    String currentPassword,
    String newPassword,
  ) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/password",
    );

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      if (await _handleExpired(response.statusCode)) return false;

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccess("Password changed successfully");
        return true;
      } else {
        _showError(body["error"] ?? "Failed to change password");
        return false;
      }
    } catch (e) {
      _showError("Error: $e");
      return false;
    }
  }

  // -------------------------------------------------------------
  // CHANGE CHILD PASSWORD
  // -------------------------------------------------------------
  void _showChangeChildPasswordDialog() {
    String? selectedChild;
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Change Child Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Select Child",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedChild,
                  items: children.map((c) {
                    return DropdownMenuItem<String>(
                      value: c["id"].toString(),
                      child: Text(c["firstName"]),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setStateDialog(() => selectedChild = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showPasswordRequirements(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("Change"),
                onPressed: selectedChild == null
                    ? null
                    : () async {
                        final newPass = newPassword.text.trim();

                        if (newPass != confirmPassword.text.trim()) {
                          _showError("Passwords do not match");
                          return;
                        }

                        if (!_validatePassword(newPass)) {
                          _showError("Password does not meet requirements");
                          return;
                        }

                        final success = await _changeChildPassword(
                          int.parse(selectedChild!),
                          newPass,
                        );

                        if (success && mounted) Navigator.pop(context);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _changeChildPassword(int childId, String newPassword) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/auth/child/$childId/password",
    );

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"newPassword": newPassword}),
      );

      if (await _handleExpired(response.statusCode)) return false;

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccess("Child password changed successfully");
        return true;
      } else {
        _showError(body["error"] ?? "Failed to change password");
        return false;
      }
    } catch (e) {
      _showError("Error: $e");
      return false;
    }
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle("Security"),

          _securityCard(
            icon: Icons.lock_outline,
            title: "Change password",
            onTap: () => _showChangeParentPasswordDialog(),
          ),

          const SizedBox(height: 14),

          _securityCard(
            icon: Icons.child_care_outlined,
            title: "Change child password",
            onTap: children.isEmpty
                ? null
                : () => _showChangeChildPasswordDialog(),
          ),

          if (children.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                "No children found",
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _securityCard({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.15),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // -------------------------------------------------------------
  // SNACKBARS
  // -------------------------------------------------------------
  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // -------------------------------------------------------------
  // PASSWORD REQUIREMENTS + VALIDATION
  // -------------------------------------------------------------
  bool _validatePassword(String pass) {
    return RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*]).{8,}$',
    ).hasMatch(pass);
  }

  void _showPasswordRequirements(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Password Requirements"),
        content: const Text(
          "• At least 8 characters\n"
          "• One uppercase letter\n"
          "• One lowercase letter\n"
          "• One number\n"
          "• One special character (!@#\$%^&*)",
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
