import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api_config.dart';

class ChildNotificationsScreen extends StatefulWidget {
  final int childId;
  final String token;

  const ChildNotificationsScreen({
    super.key,
    required this.childId,
    required this.token,
  });

  @override
  State<ChildNotificationsScreen> createState() =>
      _ChildNotificationsScreenState();
}

class _ChildNotificationsScreenState extends State<ChildNotificationsScreen> {
  bool _loading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _markAllRead();

    /// FIX: mark read
    super.dispose();
  }

  Future<void> _markAllRead() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/mark-read/child/${widget.childId}",
    );

    await http.post(url, headers: {"Authorization": "Bearer ${widget.token}"});
  }

  Future<void> _fetchNotifications() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/child/${widget.childId}",
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
    } catch (err) {
      setState(() => _loading = false);
    }
  }

  /// NEW: same styling as parent notifications
  IconData _icon(String type) {
    switch (type) {
      case "REQUEST_APPROVED":
        return Icons.check_circle_rounded;
      case "REQUEST_DECLINED":
        return Icons.cancel_rounded;
      case "MONEY_TRANSFER":
        return Icons.swap_horiz_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case "REQUEST_APPROVED":
        return Colors.green;
      case "REQUEST_DECLINED":
        return Colors.red;
      case "MONEY_TRANSFER":
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xffF7F8FA),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                final type = n["type"];

                return Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// NEW ICON
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _color(type).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon(type), color: _color(type), size: 22),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n["message"],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              (n["createdAt"] ?? "")
                                  .toString()
                                  .replaceFirst("T", " ")
                                  .split(".")
                                  .first,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
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
    );
  }
}
