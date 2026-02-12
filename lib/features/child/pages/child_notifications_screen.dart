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
    super.dispose();
  }

  // ---------------- SAR ICON ----------------
  Widget _sarIcon({double size = 14, Color? color}) {
    return Image.asset(
      'assets/icons/Sar.png',
      width: size,
      height: size,
      color: color,
    );
  }

  /// Put Sar.png right before the amount inside the sentence.
  /// Supports:
  /// - "... requested 50"
  /// - "... requested SR 50"
  /// - "... requested SAR 50.00"
  /// - "... requested ﷼ 50"
  Widget _messageWithSar(String message) {
    // No (?i) here — Dart RegExp doesn't support inline flags.
    // We'll use caseSensitive: false.
    final reg = RegExp(
      r'\b(requested|sent you|for)\b\s*(?:SAR|SR|﷼)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );

    final match = reg.firstMatch(message);

    const baseStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF2C3E50),
    );

    if (match == null) {
      return Text(message, style: baseStyle);
    }

    final amountStr = match.group(2)!;

    // Dart Match doesn't support start/end for groups, so we find the amount location manually.
    final amountStart = message.indexOf(amountStr, match.start);
    if (amountStart == -1) {
      return Text(message, style: baseStyle);
    }
    final amountEnd = amountStart + amountStr.length;

    final before = message.substring(0, amountStart);
    final after = message.substring(amountEnd);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before, style: baseStyle),

          // Icon directly before the number
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _sarIcon(size: 14, color: const Color(0xFF2C3E50)),
            ),
          ),

          TextSpan(
            text: amountStr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          TextSpan(text: after, style: baseStyle),
        ],
      ),
    );
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
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case "REQUEST_APPROVED":
        return Icons.check_circle_rounded;
      case "REQUEST_DECLINED":
        return Icons.cancel_rounded;
      case "MONEY_TRANSFER":
        return Icons.swap_horiz_rounded;
      
      case "CHORE_ASSIGNED":
        return Icons.assignment_add; 
      case "CHORE_APPROVED":
        return Icons.verified;

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
        case "CHORE_ASSIGNED":
        return Colors.purple;
      case "CHORE_APPROVED":
        return Colors.orange;
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
                final type = (n["type"] ?? "").toString();
                final message = (n["message"] ?? "").toString();

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
                            _messageWithSar(message),
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
