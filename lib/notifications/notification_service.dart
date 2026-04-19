import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hassala_high',
    'Hassala Notifications',
    description: 'High importance notifications',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // لو تبين تفتحين صفحة معينة عند الضغط على الإشعار، نخليه لاحقاً
      },
    );

    // ✅ مهم جداً لأندرويد 8+ (قناة الإشعارات)
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }

    // ✅ لما يجي FCM والبرنامج مفتوح (foreground) نطلع Local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showFromMessage(message);
    });
  }

  Future<void> requestPermissions() async {
    // Android 13+ يحتاج صلاحية
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

   
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showFromMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Hassala';

    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
  Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // طلب الصلاحيات
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // جلب التوكن
  String? token = await messaging.getToken();

  print("🔥 FCM TOKEN:");
  print(token);

  // تحديث التوكن لو تغير
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print("🔄 NEW TOKEN:");
    print(newToken);
  });
}


Future<void> sendTokenToServer({
  required String authToken,
  int? parentId,
  int? childId,
}) async {
  final messaging = FirebaseMessaging.instance;
  final fcmToken = await messaging.getToken();

  if (fcmToken == null) return;

  final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications/save-device-token');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'parentId': parentId,
      'childId': childId,
      'fcmToken': fcmToken,
    }),
  );

  debugPrint("SAVE TOKEN STATUS: ${response.statusCode}");
  debugPrint("SAVE TOKEN BODY: ${response.body}");
}
}