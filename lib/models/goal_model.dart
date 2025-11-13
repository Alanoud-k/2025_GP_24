class Goal {
  final int goalId;
  final String goalName;
  final String? goalDescription;
  final double targetAmount;
  final String goalStatus;
  final double goalBalance; 
  double get progress =>
      targetAmount == 0 ? 0 : (goalBalance / targetAmount).clamp(0, 1);

  Goal({
    required this.goalId,
    required this.goalName,
    this.goalDescription,
    required this.targetAmount,
    required this.goalStatus,
    required this.goalBalance,
  });

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        goalId: j['goalid'] ?? j['goalId'],
        goalName: j['goalname'] ?? j['goalName'],
        goalDescription: j['goaldescription'] ?? j['goalDescription'],
        targetAmount: (j['targetamount'] ?? j['targetAmount'] as num).toDouble(),
        goalStatus: j['goalstatus'] ?? j['goalStatus'],
        goalBalance: (j['balance'] ?? j['goalBalance'] ?? 0 as num).toDouble(),
      );
}
