import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

class ChildSecuritySettingsPage extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildSecuritySettingsPage({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildSecuritySettingsPage> createState() =>
      _ChildSecuritySettingsPageState();
}

class _ChildSecuritySettingsPageState extends State<ChildSecuritySettingsPage> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });
  }

  // -------------------------------------------------------------------
  // Show Change Password Dialog
  // -------------------------------------------------------------------
  void _showChangePasswordDialog() {
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    bool hideNew = true;
    bool hideConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  // NEW PASSWORD
                  TextField(
                    controller: newController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(() {
                          hideNew = !hideNew;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CONFIRM PASSWORD
                  TextField(
                    controller: confirmController,
                    obscureText: hideConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideConfirm ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(() {
                          hideConfirm = !hideConfirm;
                        }),
                      ),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Change'),
                  onPressed: () async {
                    final newPass = newController.text.trim();
                    final confirmPass = confirmController.text.trim();

                    // VALIDATION
                    if (newPass != confirmPass) {
                      _showError('Passwords do not match');
                      return;
                    }
                    if (!_validatePassword(newPass)) {
                      _showError(
                        'Password must include upper, lower, number & symbol.',
                      );
                      return;
                    }

                    // Attempt update
                    final ok = await _changeChildPassword(newPass);

                    if (ok && mounted) Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // Send Change Password Request
  // -------------------------------------------------------------------
  Future<bool> _changeChildPassword(String newPassword) async {
    if (_isUpdating) return false;
    setState(() => _isUpdating = true);

    final url = Uri.parse(
      '${widget.baseUrl}/api/auth/child/${widget.childId}/password',
    );

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          // Only new password is required for child → backend accepts this
          'newPassword': newPassword,
        }),
      );

      setState(() => _isUpdating = false);

      // TOKEN EXPIRED?
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return false;
      }

      // SUCCESS
      if (response.statusCode == 200) {
        _showSuccess('Password changed successfully');
        return true;
      }

      // ERROR — try decode JSON
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        _showError("Unexpected server error (${response.statusCode})");
        return false;
      }

      _showError(body['error'] ?? 'Failed to change password');
      return false;
    } catch (e) {
      setState(() => _isUpdating = false);
      _showError('Error: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------
  bool _validatePassword(String p) {
    if (p.length < 8) return false;
    return RegExp(
      r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
    ).hasMatch(p);
  }

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

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text(
          'Security settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
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
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),

              _buildSecurityCard(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: _showChangePasswordDialog,
              ),

              if (_isUpdating)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
          child: Icon(icon, color: Colors.teal, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
