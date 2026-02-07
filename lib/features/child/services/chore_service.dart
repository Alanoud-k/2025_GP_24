import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chore_model.dart';

class ChoreService {
  // الرابط الأساسي (تأكدي أنه ينتهي بـ /api/chores)
static const String baseUrl = "https://2025gp24-production.up.railway.app/api/chores";

  // دالة مساعدة لجلب التوكن
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. جلب مهام طفل محدد
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

  // 2. جلب جميع مهام العائلة للأب
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

  // 3. إنشاء مهمة جديدة (Create Chore)
  Future<void> createChore({
    required String title,
    required String description,
    required int keys,
    required String childId,
    required String parentId,
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
        'type': 'One-time', // قيمة افتراضية
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create chore: ${response.body}");
    }
  }

  // 4. تحديث حالة المهمة (Update Status)
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
}