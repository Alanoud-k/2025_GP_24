import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/goal_model.dart';

class GoalsApi {
  final String baseUrl;
  final String token;

  GoalsApi(this.baseUrl, this.token);

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  String _extractError(http.Response r) {
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
      }
    } catch (_) {}
    return 'Status ${r.statusCode}: ${r.body}';
  }

  // LIST GOALS
  Future<List<Goal>> listGoals(int childId) async {
    final url = Uri.parse('$baseUrl/api/children/$childId/goals');
    final r = await http.get(url, headers: _headers);

    if (r.statusCode != 200) {
      throw Exception("List goals failed: ${r.body}");
    }

    final data = jsonDecode(r.body) as List;
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  // CREATE GOAL
  Future<void> createGoal({
    required int childId,
    required String goalName,
    required double targetAmount,
    String description = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/goals');

    final r = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "childId": childId,
        "goalName": goalName,
        "targetAmount": targetAmount,
        "description": description,
      }),
    );

    if (r.statusCode != 201) {
      throw Exception("Create goal failed: ${r.body}");
    }
  }

  // GET ONE GOAL
  Future<Goal> getGoalById(int goalId) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId');

    final r = await http.get(url, headers: _headers);

    if (r.statusCode != 200) {
      throw Exception("Get goal failed: ${r.body}");
    }

    final data = jsonDecode(r.body);
    return Goal.fromJson(data);
  }

  // ADD MONEY TO GOAL (Saving → Goal)
  Future<void> addMoneyToGoal({
    required int childId,
    required int goalId,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId/move-in');

    final r = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({"childId": childId, "amount": amount}),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_extractError(r));
    }
  }

  // MOVE MONEY FROM GOAL (Goal → Saving)
  Future<void> moveMoneyFromGoal({
    required int childId,
    required int goalId,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId/move-out');

    final r = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({"childId": childId, "amount": amount}),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_extractError(r));
    }
  }

  // UPDATE GOAL
  Future<void> updateGoal({
    required int goalId,
    required String goalName,
    required double targetAmount,
    String description = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId');

    final r = await http.put(
      url,
      headers: _headers,
      body: jsonEncode({
        "goalName": goalName,
        "targetAmount": targetAmount,
        "description": description,
      }),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception("Update goal failed: ${r.body}");
    }
  }

  // DELETE GOAL
  Future<void> deleteGoal(int goalId) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId');

    final r = await http.delete(url, headers: _headers);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception("Delete goal failed: ${r.body}");
    }
  }

  // REDEEM COMPLETED GOAL → Spending
  Future<void> redeemGoal({required int childId, required int goalId}) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId/redeem');

    final r = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({"childId": childId}),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_extractError(r));
    }
  }
}
