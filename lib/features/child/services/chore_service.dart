import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chore_model.dart';

class ChoreService {
  // الرابط الأساسي للسيرفر (تأكدي من مطابقتة لما تستخدمينه في باقي الملفات)
  static const String baseUrl = "http://10.0.2.2:3000/api/chores";

  // دالة مساعدة لجلب التوكن المخزن
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. جلب مهام طفل محدد (التي استخدمناها في صفحة Overview)
  // Future<List<ChoreModel>> getChores(String childId) async {
  //   final token = await _getToken();
  //   final response = await http.get(
  //     Uri.parse('$baseUrl/child/$childId'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     List<dynamic> body = jsonDecode(response.body);
  //     return body.map((item) => ChoreModel.fromJson(item)).toList();
  //   } else {
  //     throw Exception("فشل في جلب مهام الطفل");
  //   }
  // }

  Future<List<ChoreModel>> getChores(String childId) async {
  final token = await _getToken();
  final url = Uri.parse('$baseUrl/child/$childId');
  
  print("🔍 جاري الطلب من الرابط: $url"); // للتأكد من صحة الرابط
  
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> body = jsonDecode(response.body);
    return body.map((item) => ChoreModel.fromJson(item)).toList();
  } else {
    // 💡 هذا السطر سيطبع لكِ في الـ Terminal سبب الرفض (مثلاً 404 أو 500)
    print("❌ خطأ من السيرفر: ${response.statusCode} - ${response.body}");
    throw Exception("السيرفر أعاد خطأ: ${response.statusCode}");
  }
}

  // 2. جلب جميع مهام العائلة للأب (لصفحة ParentChoresScreen العامة)
  Future<List<ChoreModel>> getAllParentChores(String parentId) async {
    final token = await _getToken();
    // ملاحظة: تأكدي أن المسار في Node.js هو /api/chores/parent/:parentId
    final response = await http.get(
      Uri.parse('$baseUrl/parent/$parentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => ChoreModel.fromJson(item)).toList();
    } else {
      throw Exception("فشل في جلب قائمة مهام العائلة");
    }
  }

  // 3. تحديث حالة المهمة (مثل الموافقة على المهمة أو رفضها)
  Future<void> updateChoreStatus(String choreId, String newStatus) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/$choreId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode != 200) {
      throw Exception("فشل في تحديث حالة المهمة");
    }
  }
}