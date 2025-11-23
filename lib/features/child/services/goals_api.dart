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

  // List goals for a child
  Future<List<Goal>> listGoals(int childId) async {
    final url = Uri.parse('$baseUrl/api/children/$childId/goals');
    print("LIST GOALS URL => $url");

    final r = await http.get(url, headers: _headers);

    print("LIST GOALS STATUS => ${r.statusCode}");
    if (r.statusCode != 200) {
      print("LIST GOALS RESPONSE => ${r.body}");
      throw Exception("List goals failed: ${r.body}");
    }

    final data = jsonDecode(r.body) as List;
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  // Create goal
  Future<void> createGoal({
    required int childId,
    required String goalName,
    required double targetAmount,
    String description = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/goals');

    print("CREATE GOAL URL => $url");
    print(
        "CREATE GOAL BODY => {childId:$childId, goalName:$goalName, targetAmount:$targetAmount, description:$description}");

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

    print("CREATE GOAL STATUS => ${r.statusCode}");
    print("CREATE GOAL RESPONSE => ${r.body}");

    if (r.statusCode != 201) {
      throw Exception("Create goal failed: ${r.body}");
    }
  }

  // Get single goal by id
  Future<Goal> getGoalById(int goalId) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId');
    print("GET GOAL URL => $url");

    final r = await http.get(url, headers: _headers);

    print("GET GOAL STATUS => ${r.statusCode}");
    if (r.statusCode != 200) {
      print("GET GOAL RESPONSE => ${r.body}");
      throw Exception("Get goal failed: ${r.body}");
    }

    final data = jsonDecode(r.body);
    return Goal.fromJson(data);
  }

  // Add money to goal (from saving balance)
  Future<void> addMoneyToGoal({
    required int childId,
    required int goalId,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId/add-money');
    print("ADD MONEY URL => $url");
    print("ADD MONEY BODY => {childId:$childId, amount:$amount}");

    final r = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "childId": childId,
        "amount": amount,
      }),
    );

    print("ADD MONEY STATUS => ${r.statusCode}");
    print("ADD MONEY RESPONSE => ${r.body}");

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception("Add money to goal failed: ${r.body}");
    }
  }

  // Move money out from goal back to saving balance
  Future<void> moveMoneyFromGoal({
    required int childId,
    required int goalId,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId/move-money');
    print("MOVE MONEY URL => $url");
    print("MOVE MONEY BODY => {childId:$childId, amount:$amount}");

    final r = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "childId": childId,
        "amount": amount,
      }),
    );

    print("MOVE MONEY STATUS => ${r.statusCode}");
    print("MOVE MONEY RESPONSE => ${r.body}");

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception("Move money from goal failed: ${r.body}");
    }
  }

  // Update goal (name, description, target)
  Future<void> updateGoal({
    required int goalId,
    required String goalName,
    required double targetAmount,
    String description = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/goals/$goalId');
    print("UPDATE GOAL URL => $url");
    print(
        "UPDATE GOAL BODY => {goalName:$goalName, targetAmount:$targetAmount, description:$description}");

    final r = await http.put(
      url,
      headers: _headers,
      body: jsonEncode({
        "goalName": goalName,
        "targetAmount": targetAmount,
        "description": description,
      }),
    );

    print("UPDATE GOAL STATUS => ${r.statusCode}");
    print("UPDATE GOAL RESPONSE => ${r.body}");

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception("Update goal failed: ${r.body}");
    }
  }
}
