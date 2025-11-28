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

  /* ============================================================
     GET: List all goals for the child
     GET /api/children/:childId/goals
  ============================================================ */
  Future<List<Goal>> listGoals(int childId) async {
    final url = Uri.parse("$baseUrl/api/children/$childId/goals");
    print("📌 LIST GOALS => $url");

    final res = await http.get(url, headers: _headers);

    print("STATUS: ${res.statusCode}");
    if (res.statusCode != 200) {
      throw Exception("Failed to list goals: ${res.body}");
    }

    final data = jsonDecode(res.body) as List;
    return data.map((j) => Goal.fromJson(j)).toList();
  }

  /* ============================================================
     POST: Create a new goal
     POST /api/goals
  ============================================================ */
  Future<void> createGoal({
    required int childId,
    required String goalName,
    required double targetAmount,
    String description = "",
  }) async {
    final url = Uri.parse("$baseUrl/api/goals");

    print("📌 CREATE GOAL => $url");
    print("BODY => {childId:$childId, name:$goalName, target:$targetAmount}");

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "childId": childId,
        "goalName": goalName,
        "targetAmount": targetAmount,
        "description": description,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("RESPONSE: ${res.body}");

    if (res.statusCode != 201) {
      throw Exception("Create goal failed: ${res.body}");
    }
  }

  /* ============================================================
     GET: retrieve single goal
     GET /api/goals/:goalId
     (optional for details screen)
  ============================================================ */
  Future<Goal> getGoalById(int goalId) async {
    final url = Uri.parse("$baseUrl/api/goals/$goalId");
    print("📌 GET GOAL => $url");

    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch goal: ${res.body}");
    }

    return Goal.fromJson(jsonDecode(res.body));
  }

  /* ============================================================
     POST: Add money to a goal (Saving → GoalAccount)
     POST /api/goals/:goalId/add-money
  ============================================================ */
  Future<void> addMoneyToGoal({
    required int childId,
    required int goalId,
    required double amount,
  }) async {
    final url = Uri.parse("$baseUrl/api/goals/$goalId/add-money");
    print("📌 ADD MONEY => $url");
    print("BODY => {childId:$childId, amount:$amount}");

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({"childId": childId, "amount": amount}),
    );

    print("STATUS: ${res.statusCode}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Add money failed: ${res.body}");
    }
  }

  /* ============================================================
     POST: Move money from goal to saving (Goal → Saving)
     POST /api/goals/:goalId/move-money
  ============================================================ */
  Future<void> moveMoneyFromGoal({
    required int childId,
    required int goalId,
    required double amount,
  }) async {
    final url = Uri.parse("$baseUrl/api/goals/$goalId/move-money");
    print("📌 MOVE MONEY FROM GOAL => $url");

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({"childId": childId, "amount": amount}),
    );

    print("STATUS: ${res.statusCode}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Move money failed: ${res.body}");
    }
  }

  /* ============================================================
     PUT: Update goal details
     PUT /api/goals/:goalId
  ============================================================ */
  Future<void> updateGoal({
    required int goalId,
    required String goalName,
    required double targetAmount,
    String description = "",
  }) async {
    final url = Uri.parse("$baseUrl/api/goals/$goalId");

    print("📌 UPDATE GOAL => $url");

    final res = await http.put(
      url,
      headers: _headers,
      body: jsonEncode({
        "goalName": goalName,
        "targetAmount": targetAmount,
        "description": description,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("RESPONSE: ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Update goal failed: ${res.body}");
    }
  }

  /* ============================================================
     DELETE: Delete a goal (ONLY if balance = 0)
     DELETE /api/goals/:goalId
  ============================================================ */
  Future<void> deleteGoal(int goalId) async {
    final url = Uri.parse("$baseUrl/api/goals/$goalId");

    print("📌 DELETE GOAL => $url");

    final res = await http.delete(url, headers: _headers);

    print("STATUS: ${res.statusCode}");
    print("RESPONSE: ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Delete goal failed: ${res.body}");
    }
  }
}
