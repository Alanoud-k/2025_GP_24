import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chore_model.dart'; // تأكدي أن مسار المودل صحيح

class ChoreService {
  // ✅ 1. الرابط الأساسي (تأكدي أنه رابط ريلواي الصحيح)
  static const String baseUrl = "https://2025gp24-production.up.railway.app/api/chores";

  // ✅ 2. دالة مساعدة لجلب التوكن (ضرورية لكل الدوال)
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- دوال الجلب (GET) ---

  // جلب مهام طفل محدد
  Future<List<ChoreModel>> getChores(String childId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/child/$childId');
    
    print("🔍 Fetching from: $url"); 
    
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
      print("❌ Error: ${response.statusCode} - ${response.body}");
      throw Exception("Server Error: ${response.statusCode}");
    }
  }

  // جلب جميع مهام العائلة للأب
  Future<List<ChoreModel>> getAllParentChores(String parentId) async {
    final token = await _getToken();
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
      throw Exception("Failed to load family chores");
    }
  }

  // --- دوال الإجراءات (POST / PATCH / PUT) ---

  // إنشاء مهمة جديدة
  Future<void> createChore({
    required String title,
    required String description,
    required int keys,
    required String childId,
    required String parentId,
    String type = 'One-time', 
    String? assignedDay, 
  String? assignedTime, 
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'keys': keys,
        'childId': childId,
        'parentId': parentId,
        'type': type,
        'assignedDay': assignedDay,
        'assignedTime': assignedTime,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create chore: ${response.body}");
    }
  }

  // تحديث حالة المهمة (موافقة / رفض)
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
      throw Exception("Failed to update status");
    }
  }

  // ✅ تعديل تفاصيل المهمة (Edit)
  Future<void> editChore({
    required String choreId,
    required String title,
    required String description,
    required int keys,
  }) async {
    final token = await _getToken(); // الآن ستعمل لأنها داخل الكلاس
    final response = await http.put(
      Uri.parse('$baseUrl/$choreId/details'), // الآن baseUrl معرف
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'keys': keys,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to edit chore details");
    }
  }

// ✅ دالة جديدة لجلب قائمة أطفال الأب
  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    final token = await _getToken();
    // 💡 نستخدم replace لنعود للرابط الرئيسي بدلاً من /api/chores
    final rootUrl = baseUrl.replaceAll('/api/chores', ''); 
    final response = await http.get(
      Uri.parse('$rootUrl/api/auth/parent/$parentId/children'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // السيرفر يعيد قائمة فيها {childId, firstName, ...}
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load children list");
    }
  }

}

