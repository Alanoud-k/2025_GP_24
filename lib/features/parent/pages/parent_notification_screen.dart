// lib/screens/parent_notifications_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api_config.dart';

class ParentNotificationsScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentNotificationsScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  bool _loading = true;
  List<dynamic> _notifications = [];

  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // ✅ لا نستخدم dispose للـ mark-read
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _markParentRead() async {
    if (_markingRead) return;
    _markingRead = true;

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/mark-read/parent/${widget.parentId}",
    );

    try {
      await http.post(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      // ✅ حدّث محليًا عشان الـ UI يبين مقروء
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n["isread"] = true;
        }
      });
    } catch (_) {
      // تجاهل (مو لازم نكسر الصفحة)
    } finally {
      _markingRead = false;
    }
  }

  Future<void> _fetchNotifications() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/parent/${widget.parentId}",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);

        setState(() {
          _notifications = (list is List) ? list : [];
          _loading = false;
        });

        // ✅ بعد ما تجيبهم وتعرضهم: سوِ mark-all-read
        // (هذا يحقق: "يصير unread لين أشوف الصفحة")
        await _markParentRead();
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null) return "";
    final raw = value.toString();
    // ISO: 2025-11-29T20:15:32.123Z
    return raw.replaceFirst('T', ' ').split('.').first;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'REWARD_REDEEMED':
        return Colors.purple;
      case 'MONEY_REQUEST':
        return Colors.orange;
      case 'MONEY_TRANSFER':
        return Colors.teal;
      case 'REQUEST_APPROVED':
        return Colors.green;
      case 'REQUEST_DECLINED':
        return Colors.red;
      case "CHORE_COMPLETED":
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'REWARD_REDEEMED':
        return Icons.card_giftcard;
      case 'MONEY_REQUEST':
        return Icons.attach_money_rounded;
      case 'MONEY_TRANSFER':
        return Icons.swap_horiz_rounded;
      case 'REQUEST_APPROVED':
        return Icons.check_circle_rounded;
      case 'REQUEST_DECLINED':
        return Icons.cancel_rounded;
      case "CHORE_COMPLETED":
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget _sarIcon({double size = 14, Color? color}) {
    return Image.asset(
      'assets/icons/Sar.png',
      width: size,
      height: size,
      color: color,
    );
  }

  Widget _messageAmountInline(String message) {
    final match =
        RegExp(r'^(.*?)(\d+(?:\.\d{1,2})?)\s*$').firstMatch(message);

    const baseStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF2C3E50),
    );

    if (match == null) {
      return Text(message, style: baseStyle);
    }

    final prefix = match.group(1) ?? "";
    final amount = match.group(2) ?? "";

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: baseStyle),
        Text(amount, style: baseStyle),
        const SizedBox(width: 6),
        _sarIcon(size: 14, color: const Color(0xFF2C3E50)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // ✅ زر اختياري: Mark all read يدويًا (لو تبينه)
          IconButton(
            tooltip: "Mark all as read",
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _notifications.isEmpty ? null : _markParentRead,
          ),
        ],
      ),
      backgroundColor: const Color(0xffF7F8FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final type = (n["type"] ?? "").toString();
                      final color = _typeColor(type);

                      final isRead = (n["isread"] == true);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          // ✅ Unread background
                          color: isRead
                              ? Colors.white
                              : const Color(0xFFEAF7F6),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: isRead
                              ? null
                              : Border.all(
                                  color: const Color(0xFF37C4BE)
                                      .withOpacity(0.35),
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon circle
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_typeIcon(type),
                                  color: color, size: 22),
                            ),
                            const SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // message
                                  _messageAmountInline(
                                    (n["message"] ?? "").toString(),
                                  ),

                                  const SizedBox(height: 6),

                                  // child name (اختياري)
                                  if (n["childName"] != null &&
                                      (n["childName"].toString().trim().isNotEmpty))
                                    Text(
                                      "Child: ${n["childName"]}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                  const SizedBox(height: 6),

                                  // time
                                  Text(
                                    _formatCreatedAt(n["createdAt"]),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ Unread dot
                            if (!isRead) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF37C4BE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}