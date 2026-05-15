// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:my_app/core/api_config.dart';
// import 'package:my_app/l10n/app_localizations.dart';

// class ChildNotificationsScreen extends StatefulWidget {
//   final int childId;
//   final String token;

//   const ChildNotificationsScreen({
//     super.key,
//     required this.childId,
//     required this.token,
//   });

//   @override
//   State<ChildNotificationsScreen> createState() =>
//       _ChildNotificationsScreenState();
// }

// class _ChildNotificationsScreenState
//     extends State<ChildNotificationsScreen> {
//   bool _loading = true;
//   bool _markingRead = false;
//   List<dynamic> _notifications = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchNotifications();
//   }

//   Future<void> _markAllRead() async {
//     if (_markingRead) return;
//     _markingRead = true;

//     final url = Uri.parse(
//       "${ApiConfig.baseUrl}/api/notifications/mark-read/child/${widget.childId}",
//     );

//     try {
//       await http.post(
//         url,
//         headers: {"Authorization": "Bearer ${widget.token}"},
//       );
//     } catch (_) {
//       // تجاهل
//     } finally {
//       _markingRead = false;
//     }
//   }

//   Future<void> _fetchNotifications() async {
//     final url = Uri.parse(
//       "${ApiConfig.baseUrl}/api/notifications/child/${widget.childId}",
//     );

//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer ${widget.token}",
//           "Content-Type": "application/json",
//         },
//       );

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final list = jsonDecode(response.body);

//         setState(() {
//           _notifications = (list is List) ? list : [];
//           _loading = false;
//         });
//       } else {
//         setState(() => _loading = false);
//       }
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _loading = false);
//     }
//   }

//   Widget _sarIcon({double size = 14, Color? color}) {
//     return Image.asset(
//       'assets/icons/Sar.png',
//       width: size,
//       height: size,
//       color: color,
//     );
//   }

//   Widget _messageWithSar(String message) {
//     final reg = RegExp(
//       r'\b(requested|sent you|for)\b\s*(?:SAR|SR|﷼)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
//       caseSensitive: false,
//     );

//     final match = reg.firstMatch(message);

//     const baseStyle = TextStyle(
//       fontSize: 15,
//       fontWeight: FontWeight.w600,
//       color: Color(0xFF2C3E50),
//     );

//     if (match == null) {
//       return Text(message, style: baseStyle);
//     }

//     final amountStr = match.group(2)!;
//     final amountStart = message.indexOf(amountStr, match.start);
//     if (amountStart == -1) {
//       return Text(message, style: baseStyle);
//     }

//     final before = message.substring(0, amountStart);
//     final after = message.substring(amountStart + amountStr.length);

//     return Text.rich(
//       TextSpan(
//         children: [
//           TextSpan(text: before, style: baseStyle),
//           WidgetSpan(
//             alignment: PlaceholderAlignment.middle,
//             child: Padding(
//               padding: const EdgeInsetsDirectional.only(end: 4),
//               child: _sarIcon(size: 14, color: const Color(0xFF2C3E50)),
//             ),
//           ),
//           TextSpan(
//             text: amountStr,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFF2C3E50),
//             ),
//           ),
//           TextSpan(text: after, style: baseStyle),
//         ],
//       ),
//     );
//   }

//   IconData _icon(String type) {
//     switch (type) {
//       case "REQUEST_APPROVED":
//         return Icons.check_circle_rounded;
//       case "REQUEST_DECLINED":
//         return Icons.cancel_rounded;
//       case "MONEY_TRANSFER":
//         return Icons.swap_horiz_rounded;
//       case "CHORE_ASSIGNED":
//         return Icons.assignment_add;
//       case "CHORE_APPROVED":
//         return Icons.verified;
//       case "CHORE_REJECTED":
//         return Icons.assignment_return;
//       default:
//         return Icons.notifications_rounded;
//     }
//   }

//   Color _color(String type) {
//     switch (type) {
//       case "REQUEST_APPROVED":
//         return Colors.green;
//       case "REQUEST_DECLINED":
//         return Colors.red;
//       case "MONEY_TRANSFER":
//         return Colors.teal;
//       case "CHORE_ASSIGNED":
//         return Colors.purple;
//       case "CHORE_APPROVED":
//         return Colors.orange;
//       case "CHORE_REJECTED":
//         return Colors.red;
//       default:
//         return Colors.blueGrey;
//     }
//   }

//   String _formatTime(dynamic value) {
//     if (value == null) return "";
//     return value.toString().replaceFirst("T", " ").split(".").first;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return PopScope(
//       onPopInvokedWithResult: (didPop, result) {
//         if (didPop) {
//           _markAllRead();
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(l10n.notifications),
//           backgroundColor: Colors.white,
//           foregroundColor: Colors.black,
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.done_all),
//               onPressed: _notifications.isEmpty
//                   ? null
//                   : () async {
//                       await _markAllRead();
//                       if (!mounted) return;
//                       setState(() {
//                         for (final n in _notifications) {
//                           n["isread"] = true;
//                         }
//                       });
//                     },
//             )
//           ],
//         ),
//         backgroundColor: const Color(0xffF7F8FA),
//         body: _loading
//             ? const Center(child: CircularProgressIndicator())
//             : _notifications.isEmpty
//                 ? Center(child: Text(l10n.noNotifications))
//                 : RefreshIndicator(
//                     onRefresh: _fetchNotifications,
//                     child: ListView.builder(
//                       padding: const EdgeInsetsDirectional.all(16),
//                       itemCount: _notifications.length,
//                       itemBuilder: (_, i) {
//                         final n = _notifications[i];
//                         final type = (n["type"] ?? "").toString();
//                         final message = (n["message"] ?? "").toString();
//                         final isRead = n["isread"] == true;

//                         return Container(
//                           padding: const EdgeInsetsDirectional.all(14),
//                           margin: const EdgeInsetsDirectional.only(bottom: 12),
//                           decoration: BoxDecoration(
//                             color: isRead
//                                 ? Colors.white
//                                 : const Color(0xFFEAF7F6),
//                             borderRadius: BorderRadius.circular(14),
//                             border: isRead
//                                 ? null
//                                 : Border.all(
//                                     color: const Color(0xFF37C4BE)
//                                         .withOpacity(0.3),
//                                   ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black12.withOpacity(0.05),
//                                 blurRadius: 6,
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   color: _color(type).withOpacity(0.12),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Icon(
//                                   _icon(type),
//                                   color: _color(type),
//                                   size: 22,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     _messageWithSar(message),
//                                     const SizedBox(height: 5),
//                                     Text(
//                                       _formatTime(n["createdAt"]),
//                                       style: const TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.black54,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               if (!isRead)
//                                 Container(
//                                   width: 8,
//                                   height: 8,
//                                   decoration: const BoxDecoration(
//                                     color: Color(0xFF37C4BE),
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

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

class _ChildNotificationsScreenState
    extends State<ChildNotificationsScreen> {
  bool _loading = true;
  bool _markingRead = false;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _markAllRead() async {
    if (_markingRead) return;
    _markingRead = true;

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/notifications/mark-read/child/${widget.childId}",
    );

    try {
      await http.post(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
    } catch (_) {} finally {
      _markingRead = false;
    }
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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        setState(() {
          _notifications = (list is List) ? list : [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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

  String _localizeMessage(String msg) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!isArabic) return msg;

    String t = msg;
    
    // أولاً: ترجمة عبارات الطلب (مع مراعاة التذكير "عليه/رفضه")
    t = t.replaceAll(RegExp(r'Your request was approved for', caseSensitive: false), 'تم قبول طلبك لمبلغ');
    t = t.replaceAll(RegExp(r'Your request was declined for', caseSensitive: false), 'تم رفض طلبك لمبلغ');
    t = t.replaceAll(RegExp(r'Your request for', caseSensitive: false), 'طلبك لمبلغ'); // 👈 الجملة المطلوبة
    t = t.replaceAll(RegExp(r'Your parent approved your request for', caseSensitive: false), 'وافق والدك على طلبك لمبلغ');
    t = t.replaceAll(RegExp(r'Your parent declined your request for', caseSensitive: false), 'رفض والدك طلبك لمبلغ');
    
    // ثانياً: ترجمة عبارات المهام (مع مراعاة التأنيث "عليها/رفضها")
    t = t.replaceAll(RegExp(r'You have a new chore:', caseSensitive: false), 'لديك مهمة جديدة:');
    t = t.replaceAll(RegExp(r'A new chore was assigned', caseSensitive: false), 'تم تعيين مهمة جديدة');
    t = t.replaceAll(RegExp(r'new chore assigned', caseSensitive: false), 'تم تعيين مهمة جديدة');
    t = t.replaceAll(RegExp(r'chore assigned', caseSensitive: false), 'تم تعيين مهمة');
    t = t.replaceAll(RegExp(r'Your chore', caseSensitive: false), 'مهمتك');
    t = t.replaceAll(RegExp(r'chore rejected', caseSensitive: false), 'تم رفض المهمة');
    t = t.replaceAll(RegExp(r'chore approved', caseSensitive: false), 'تمت الموافقة على المهمة');
    t = t.replaceAll(RegExp(r'was approved!', caseSensitive: false), 'تمت الموافقة عليها!');
    t = t.replaceAll(RegExp(r'was approved', caseSensitive: false), 'تم قبولها');
    t = t.replaceAll(RegExp(r'was rejected\.', caseSensitive: false), 'تم رفضها.');
    t = t.replaceAll(RegExp(r'was rejected', caseSensitive: false), 'تم رفضها');
    
    // ثالثاً: التحويلات والعملة والملاحظات
    t = t.replaceAll(RegExp(r'Your parent sent you', caseSensitive: false), 'أرسل لك والدك');
    t = t.replaceAll(RegExp(r'Check notes\.', caseSensitive: false), 'راجع الملاحظات.');
    t = t.replaceAll(RegExp(r'SAR', caseSensitive: false), 'ر.س');
    
    return t;
  }

  Widget _messageWithSar(String message) {
    final localizedMsg = _localizeMessage(message);
    final reg = RegExp(
      r'(requested|sent you|for|لمبلغ|والدك|طلبك)\s*(?:SAR|SR|﷼|ر\.س)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );

    final match = reg.firstMatch(localizedMsg);
    const baseStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50));

    if (match == null) return Text(localizedMsg, style: baseStyle);

    final amountStr = match.group(2)!;
    final amountStart = localizedMsg.indexOf(amountStr, match.start);
    if (amountStart == -1) return Text(localizedMsg, style: baseStyle);

    final before = localizedMsg.substring(0, amountStart);
    final after = localizedMsg.substring(amountStart + amountStr.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before, style: baseStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(padding: const EdgeInsetsDirectional.only(end: 4), child: _sarIcon(size: 14, color: const Color(0xFF2C3E50))),
          ),
          TextSpan(text: amountStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
          TextSpan(text: after, style: baseStyle),
        ],
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case "REQUEST_APPROVED": return Icons.check_circle_rounded;
      case "REQUEST_DECLINED": return Icons.cancel_rounded;
      case "MONEY_TRANSFER": return Icons.swap_horiz_rounded;
      case "CHORE_ASSIGNED": return Icons.assignment_add;
      case "CHORE_APPROVED": return Icons.verified;
      case "CHORE_REJECTED": return Icons.assignment_return;
      default: return Icons.notifications_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case "REQUEST_APPROVED": return Colors.green;
      case "REQUEST_DECLINED": return Colors.red;
      case "MONEY_TRANSFER": return Colors.teal;
      case "CHORE_ASSIGNED": return Colors.purple;
      case "CHORE_APPROVED": return Colors.orange;
      case "CHORE_REJECTED": return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return "";
    return value.toString().replaceFirst("T", " ").split(".").first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) { if (didPop) _markAllRead(); },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _notifications.isEmpty ? null : () async {
                await _markAllRead();
                if (!mounted) return;
                setState(() { for (final n in _notifications) { n["isread"] = true; } });
              },
            )
          ],
        ),
        backgroundColor: const Color(0xffF7F8FA),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(child: Text(l10n.noNotifications))
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsetsDirectional.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final type = (n["type"] ?? "").toString();
                        final message = (n["message"] ?? "").toString();
                        final isRead = n["isread"] == true;

                        return Container(
                          padding: const EdgeInsetsDirectional.all(14),
                          margin: const EdgeInsetsDirectional.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : const Color(0xFFEAF7F6),
                            borderRadius: BorderRadius.circular(14),
                            border: isRead ? null : Border.all(color: const Color(0xFF37C4BE).withOpacity(0.3)),
                            boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: _color(type).withOpacity(0.12), shape: BoxShape.circle),
                                child: Icon(_icon(type), color: _color(type), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _messageWithSar(message),
                                    const SizedBox(height: 5),
                                    Text(_formatTime(n["createdAt"]), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF37C4BE), shape: BoxShape.circle)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}