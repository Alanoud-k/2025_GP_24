import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';

class GoalsApi {
  final String baseUrl;
  GoalsApi(this.baseUrl);

  Future<void> setupWallet(int childId) async {
    return;
  }

  Future<double> getSaveBalance(int childId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/children/$childId/save-balance'),
    );
    if (r.statusCode != 200) throw Exception('Get save balance failed');
    final j = jsonDecode(r.body);
    return (j['balance'] as num).toDouble();
  }

  Future<List<Goal>> listGoals(int childId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/children/$childId/goals'),
    );
    if (r.statusCode != 200) throw Exception('List goals failed');
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'childId': childId,
        'goalName': goalName,
        'targetAmount': targetAmount,
      }),
    );


    // ignore: avoid_print
    print('CreateGoal status: ${r.statusCode}');
    // ignore: avoid_print
    print('CreateGoal body: ${r.body}');

    if (r.statusCode != 201) {
      throw Exception('Create goal failed: ${r.body}');
    }
  }
}
