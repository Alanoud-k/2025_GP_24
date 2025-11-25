import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

class ParentSecuritySettingsPage extends StatefulWidget {
  final int parentId;
  final String token; // ✅ JWT added

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
      _showErrorSnackbar("Missing token — please log in again");
      setState(() => isLoadingChildren = false);
      return;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}", // ✅ JWT included
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          children = data is List ? data : data["children"] ?? [];
        });
      } else {
        _showErrorSnackbar('Failed to load children');
      }
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    } finally {
      setState(() => isLoadingChildren = false);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.info_outline, size: 18),
                    onPressed: () => _showPasswordRequirementsDialog(context),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = newPasswordController.text;

                // التحقق من تطابق كلمات المرور
                if (newPassword != confirmPasswordController.text) {
                  _showErrorSnackbar('Passwords do not match');
                  return;
                }

                // التحقق من شروط كلمة المرور
                if (!_validatePassword(newPassword)) {
                  _showErrorSnackbar(
                    'Password does not meet requirements. Tap the info icon for details.',
                  );
                  return;
                }

                await _changeParentPassword(
                  currentPasswordController.text,
                  newPassword,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeParentPassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (token == null) return _forceLogout();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parent/${widget.parentId}/password',
    );

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (await _handleExpired(response.statusCode)) return;

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Password changed successfully');
      } else if (response.statusCode == 401) {
        _showErrorSnackbar('Current password is incorrect');
      } else {
        _showErrorSnackbar('Failed to change password');
      }
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showChangeChildPasswordDialog(BuildContext context) {
    String? selectedChildId;
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Change Child Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Child Selection Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Child',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: selectedChildId,
                    items: children.map<DropdownMenuItem<String>>((child) {
                      return DropdownMenuItem<String>(
                        value: child['id'].toString(),
                        child: Text(child['firstName']),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedChildId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.info_outline, size: 18),
                        onPressed: () =>
                            _showPasswordRequirementsDialog(context),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedChildId == null
                      ? null
                      : () async {
                          final newPassword = newPasswordController.text;

                          if (newPassword.isEmpty) {
                            _showErrorSnackbar('Please enter new password');
                            return;
                          }

                          if (newPassword != confirmPasswordController.text) {
                            _showErrorSnackbar('Passwords do not match');
                            return;
                          }

                          // التحقق من شروط كلمة المرور
                          if (!_validatePassword(newPassword)) {
                            _showErrorSnackbar(
                              'Password does not meet requirements. Tap the info icon for details.',
                            );
                            return;
                          }

                          await _changeChildPassword(
                            int.parse(selectedChildId!),
                            newPassword,
                          );
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeChildPassword(int childId, String newPassword) async {
    if (token == null) return _forceLogout();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/child/$childId/password');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer ${widget.token}", // ✅ JWT added
        },
        body: jsonEncode({'newPassword': newPassword}),
      );
      if (await _handleExpired(response.statusCode)) return;

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Child password changed successfully');
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackbar('Failed: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    }
  }
  // --------------------- FORCE LOGOUT ---------------------

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
  }

  //------------------------------------------------------------
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Security settings'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                child: Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Change Password Card
              _buildSecurityCard(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              const SizedBox(height: 16),

              // Change Child Password Card
              _buildSecurityCard(
                icon: Icons.child_care_outlined,
                title: 'Change child password',
                onTap: isLoadingChildren || children.isEmpty
                    ? null
                    : () => _showChangeChildPasswordDialog(context),
              ),

              // Show loading or empty state
              if (isLoadingChildren)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No children found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: onTap == null ? Colors.grey : Colors.teal,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: onTap == null ? Colors.grey : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: onTap == null ? Colors.grey : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

// دالة التحقق من شروط كلمة المرور
bool _validatePassword(String password) {
  if (password.length < 8) {
    return false;
  }
  if (!RegExp(
    r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
  ).hasMatch(password)) {
    return false;
  }
  return true;
}

// دالة لعرض رسالة الخطأ
void _showPasswordRequirementsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Password Requirements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• At least 8 characters'),
            Text('• One uppercase letter (A-Z)'),
            Text('• One lowercase letter (a-z)'),
            Text('• One number (0-9)'),
            Text('• One special character (!@#\$%^&*)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
