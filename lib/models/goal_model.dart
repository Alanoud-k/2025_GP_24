class Goal {
  final int goalId;
  final String goalName;
  final double targetAmount;
  final String goalStatus;
  final double goalBalance;

  // حساب التقدم بين 0 و 1
  double get progress =>
      targetAmount == 0 ? 0 : (goalBalance / targetAmount).clamp(0, 1);

  Goal({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.goalStatus,
    required this.goalBalance,
  });

  /// دالة تحويل آمنة لأي قيمة إلى double
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory Goal.fromJson(Map<String, dynamic> j) {
    return Goal(
      goalId: j['goalid'] ?? j['goalId'],
      goalName: j['goalname'] ?? j['goalName'],
      targetAmount: _toDouble(j['targetamount'] ?? j['targetAmount']),
      goalStatus: j['goalstatus'] ?? j['goalStatus'],
      goalBalance: _toDouble(j['balance'] ?? j['goalBalance']),
    );
  }
}
