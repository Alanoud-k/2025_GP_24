class ChoreModel {
  final String id;
  final String title;
  final String? description;
  final int keys;
  final String status;
  final String childId;
  final String type; // ✅ جديد

  ChoreModel({
    required this.id,
    required this.title,
    this.description,
    required this.keys,
    required this.status,
    required this.childId,
    required this.type, // ✅
  });

  factory ChoreModel.fromJson(Map<String, dynamic> json) {
    return ChoreModel(
      id: json['_id'].toString(),
      title: json['title'] ?? 'No Title',
      description: json['description'],
      keys: json['keys'] ?? 0,
      status: json['status'] ?? 'Pending',
      childId: (json['childId'] ?? '').toString(),
      type: json['type'] ?? 'One-time', // ✅ قراءة النوع
    );
  }
}