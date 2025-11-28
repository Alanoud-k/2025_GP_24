import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBaseUrl = "https://2025gp24-production.up.railway.app";

Future<Map<String, dynamic>> simulateCardPayment({
  required int childId,
  required int receiverAccountId,
  required double amount,
  required String merchantName,
  required int mcc,
}) async {
  final uri = Uri.parse("$kBaseUrl/api/transaction/simulate-card");

  final res = await http.post(
    uri,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "childId": childId,
      "receiverAccountId": receiverAccountId,
      "amount": amount,
      "merchantName": merchantName,
      "mcc": mcc,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to simulate card payment: ${res.body}");
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return data;
}
