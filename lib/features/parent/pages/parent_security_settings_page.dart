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
  // Hassala palette
  static const Color kBg1 = Color(0xFFF7FAFC);
  static const Color kBg2 = Color(0xFFE6F4F3);
  static const Color kTextDark = Color(0xFF2C3E50);
  static const Color kGreen1 = Color(0xFF37C4BE);
  static const Color kGreen2 = Color(0xFF2EA49E);

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

  /*Future<bool> _handleExpired(int statusCode) async {
    if (statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return true;
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
      return true;
    }
    return false;
  }*/
  Future<bool> _handleExpired(http.Response res) async {
    if (res.statusCode != 401) return false;

    String msg = "";
    try {
      final data = jsonDecode(res.body);
      msg = (data["message"] ?? data["error"] ?? "").toString().toLowerCase();
    } catch (_) {
      msg = res.body.toLowerCase();
    }

    // Only logout if it REALLY looks like token/session issue
    final looksLikeTokenIssue =
        msg.contains("token") ||
        msg.contains("jwt") ||
        msg.contains("expired") ||
        msg.contains("unauthorized") ||
        msg.contains("invalid signature");

    if (!looksLikeTokenIssue) {
      // 401 but not a token issue → treat as normal error (e.g. wrong password)
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return true;
    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    return true;
  }

  Future<void> fetchChildren() async {
    setState(() => isLoadingChildren = true);

    if (token == null) {
      _showErrorBar("Missing token — please log in again");
      setState(() => isLoadingChildren = false);
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

      //if (await _handleExpired(response.statusCode)) return;
      if (await _handleExpired(response)) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          children = data is List ? data : (data["children"] ?? []);
        });
      } else {
        _showErrorBar("Failed to load children");
      }
    } catch (e) {
      _showErrorBar("Error: $e");
    } finally {
      if (mounted) setState(() => isLoadingChildren = false);
    }
  }

  //////////////////////////////////////////////////////////////
  String _extractMessage(
    http.Response res, {
    String fallback = "Something went wrong",
  }) {
    try {
      final data = jsonDecode(res.body);

      // common keys your backend might return
      final msg =
          data["error"] ?? data["message"] ?? data["msg"] ?? data["details"];

      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }

      return fallback;
    } catch (_) {
      // body might not be JSON
      final raw = res.body.toString().trim();
      return raw.isNotEmpty ? raw : fallback;
    }
  }

  // -------------------------------------------------------------
  // CHANGE PARENT PASSWORD (UI only - backend untouched)
  // -------------------------------------------------------------
  void _showChangeParentPasswordDialog() {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;
    bool busy = false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> onSubmit() async {
              if (busy) return;
              if (!formKey.currentState!.validate()) return;

              final success = await _changeParentPassword(
                currentPassword.text.trim(),
                newPassword.text.trim(),
              );

              if (success && mounted) Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // grabber
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),

                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kGreen1.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: kGreen1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Change password",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel("Current password"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: currentPassword,
                          obscureText: !showCurrent,
                          textInputAction: TextInputAction.next,
                          decoration: _hassalaFieldDeco(
                            hint: "Enter current password",
                            prefix: Icons.key_rounded,
                            suffix: IconButton(
                              onPressed: () =>
                                  setModal(() => showCurrent = !showCurrent),
                              icon: Icon(
                                showCurrent
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return "Required";
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel("New password"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPassword,
                          obscureText: !showNew,
                          textInputAction: TextInputAction.next,
                          decoration: _hassalaFieldDeco(
                            hint: "Create a strong password",
                            prefix: Icons.lock_outline_rounded,
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: "Requirements",
                                  onPressed: () =>
                                      _showPasswordRequirements(context),
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setModal(() => showNew = !showNew),
                                  icon: Icon(
                                    showNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          validator: (v) {
                            final pass = (v ?? "").trim();
                            if (pass.isEmpty) return "Required";
                            if (!_validatePassword(pass))
                              return "Doesn't meet requirements";
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel("Confirm new password"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPassword,
                          obscureText: !showConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => onSubmit(),
                          decoration: _hassalaFieldDeco(
                            hint: "Re-enter new password",
                            prefix: Icons.verified_user_outlined,
                            suffix: IconButton(
                              onPressed: () =>
                                  setModal(() => showConfirm = !showConfirm),
                              icon: Icon(
                                showConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (v) {
                            final c = (v ?? "").trim();
                            if (c.isEmpty) return "Required";
                            if (c != newPassword.text.trim())
                              return "Passwords do not match";
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // requirements pill
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black12.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: kGreen2,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Use 8+ chars with uppercase, lowercase, number, and special character.",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kTextDark,
                                    side: BorderSide(
                                      color: Colors.black12.withOpacity(0.12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!.validate())
                                            return;
                                          setModal(() => busy = true);
                                          try {
                                            await onSubmit();
                                          } finally {
                                            if (ctx.mounted)
                                              setModal(() => busy = false);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen1,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Change",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorBar(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessBar(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2EA49E), // Hassala green
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

      //if (await _handleExpired(response.statusCode)) return false;
      if (await _handleExpired(response)) return false;

      //final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccessBar("Password changed successfully");
        return true;
      }
      final msg = _extractMessage(
        response,
        fallback: "Failed to change password",
      );
      _showErrorBar(msg);
      return false;
    } catch (_) {
      _showErrorBar("Network error. Please try again.");
      return false;
    }
  }

  // -------------------------------------------------------------
  // CHANGE CHILD PASSWORD (UI only - backend untouched)
  // -------------------------------------------------------------
  void _showChangeChildPasswordDialog() {
    String? selectedChild;
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    bool showNew = false;
    bool showConfirm = false;
    bool busy = false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> onSubmit() async {
              if (busy) return;
              if (!formKey.currentState!.validate()) return;

              final success = await _changeChildPassword(
                int.parse(selectedChild!),
                newPassword.text.trim(),
              );

              if (success && mounted) Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // grabber
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),

                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kGreen2.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.child_care_rounded,
                                color: kGreen2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Change child password",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel("Select child"),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedChild,
                          isExpanded: true,
                          decoration: _hassalaFieldDeco(
                            hint: "Choose",
                            prefix: Icons.person_outline_rounded,
                          ),
                          items: children.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['childId'].toString(),
                              child: Text(
                                (c['firstName'] ?? 'Child').toString(),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setModal(() => selectedChild = v),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Required" : null,
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel("New password"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPassword,
                          obscureText: !showNew,
                          decoration: _hassalaFieldDeco(
                            hint: "Create a strong password",
                            prefix: Icons.lock_outline_rounded,
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: "Requirements",
                                  onPressed: () =>
                                      _showPasswordRequirements(context),
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setModal(() => showNew = !showNew),
                                  icon: Icon(
                                    showNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          validator: (v) {
                            final pass = (v ?? "").trim();
                            if (pass.isEmpty) return "Required";
                            if (!_validatePassword(pass))
                              return "Doesn't meet requirements";
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel("Confirm password"),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPassword,
                          obscureText: !showConfirm,
                          decoration: _hassalaFieldDeco(
                            hint: "Re-enter new password",
                            prefix: Icons.verified_user_outlined,
                            suffix: IconButton(
                              onPressed: () =>
                                  setModal(() => showConfirm = !showConfirm),
                              icon: Icon(
                                showConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (v) {
                            final c = (v ?? "").trim();
                            if (c.isEmpty) return "Required";
                            if (c != newPassword.text.trim())
                              return "Passwords do not match";
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kTextDark,
                                    side: BorderSide(
                                      color: Colors.black12.withOpacity(0.12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: (busy || children.isEmpty)
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!.validate())
                                            return;
                                          setModal(() => busy = true);
                                          try {
                                            await onSubmit();
                                          } finally {
                                            if (ctx.mounted)
                                              setModal(() => busy = false);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen2,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Change",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

      // if (await _handleExpired(response.statusCode)) return false;
      if (await _handleExpired(response)) return false;
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccessBar("Child password changed successfully");
        return true;
      } else {
        _showErrorBar(
          _extractMessage(response, fallback: "Failed to change password"),
        );
        return false;
      }
    } catch (e) {
      _showErrorBar("Error: $e");
      return false;
    }
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBg1, kBg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kTextDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Security Settings",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              _sectionTitle("Security"),

              _securityCard(
                icon: Icons.lock_rounded,
                title: "Change password",
                subtitle: "Update your parent account password",
                color: kGreen1,
                onTap: _showChangeParentPasswordDialog,
              ),

              const SizedBox(height: 14),

              _securityCard(
                icon: Icons.child_care_rounded,
                title: "Change child password",
                subtitle: children.isEmpty
                    ? "Add a child first to manage passwords"
                    : "Reset a child account password",
                color: kGreen2,
                onTap: children.isEmpty ? null : _showChangeChildPasswordDialog,
              ),

              const SizedBox(height: 16),

              if (isLoadingChildren)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
                ),

              /* if (!isLoadingChildren && children.isEmpty)
                Center(
                  child: Column(
                    children: const [
                      SizedBox(height: 10),
                      Icon(
                        Icons.family_restroom_outlined,
                        size: 80,
                        color: Colors.black12,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "No children found",
                        style: TextStyle(fontSize: 15, color: Colors.black38),
                      ),
                    ],
                  ),
                ),*/
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // UI Helpers
  // -------------------------------------------------------------
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: kTextDark,
        ),
      ),
    );
  }

  Widget _securityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: onTap == null ? Colors.black26 : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  static Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  static InputDecoration _hassalaFieldDeco({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: Icon(prefix, color: kGreen2),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black12.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kGreen2, width: 1.2),
      ),
    );
  }

  // -------------------------------------------------------------
  // Snackbars
  // -------------------------------------------------------------
  /*void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }*/

  // -------------------------------------------------------------
  // PASSWORD REQUIREMENTS + VALIDATION (unchanged)
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
