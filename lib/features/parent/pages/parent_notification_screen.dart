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

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _markParentRead();

    /// NEW
    super.dispose();
  }

  Future<void> _markParentRead() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/mark-read/parent/${widget.parentId}",
    );
    await http.post(url, headers: {"Authorization": "Bearer ${widget.token}"});
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

      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null) return "";
    final raw = value.toString();
    // Typical ISO string: 2025-11-29T20:15:32.123Z
    final cleaned = raw.replaceFirst('T', ' ').split('.').first;
    return cleaned;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'MONEY_REQUEST':
        return Colors.orange;
      case 'MONEY_TRANSFER':
        return Colors.teal;
      case 'REQUEST_APPROVED':
        return Colors.green;
      case 'REQUEST_DECLINED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'MONEY_REQUEST':
        return Icons.attach_money_rounded;
      case 'MONEY_TRANSFER':
        return Icons.swap_horiz_rounded;
      case 'REQUEST_APPROVED':
        return Icons.check_circle_rounded;
      case 'REQUEST_DECLINED':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon(type), color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // message
                              Text(
                                n["message"] ?? "",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // optional child name
                              if (n["childName"] != null)
                                Text(
                                  n["childName"],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              const SizedBox(height: 4),
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
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
