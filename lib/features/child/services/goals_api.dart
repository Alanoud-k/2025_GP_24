import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';

class GoalsApi {
  final String baseUrl;
  final String token;

  GoalsApi(this.baseUrl, this.token);

  Future<List<Goal>> listGoals(int childId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/children/$childId/goals'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (r.statusCode != 200) throw Exception("List goals failed");
    final data = jsonDecode(r.body) as List;
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  Future<void> createGoal({
    required int childId,
    required String goalName,
    required double targetAmount,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/goals'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "childId": childId,
        "goalName": goalName,
        "targetAmount": targetAmount,
      }),
    );

    if (r.statusCode != 201) {
      throw Exception("Create goal failed: ${r.body}");
    }
  }
}
