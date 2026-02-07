import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChildQrConfirmScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  final String qrToken;
  final String merchantName;
  final double amount;
  final DateTime expiresAt;

  const ChildQrConfirmScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
    required this.qrToken,
    required this.merchantName,
    required this.amount,
    required this.expiresAt,
  });

  @override
  State<ChildQrConfirmScreen> createState() => _ChildQrConfirmScreenState();
}

class _ChildQrConfirmScreenState extends State<ChildQrConfirmScreen> {
  bool _paying = false;
  String? _error;

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  Uri _confirmUrl() {
    // When you build the backend, keep it consistent with the scan screen.
    // Recommended convention:
    //   GET  {baseUrl}/api/qr/resolve?token=...
    //   POST {baseUrl}/api/qr/confirm
    //
    // If you decide NOT to use /api, just change this to: '${widget.baseUrl}/qr/confirm'
    return Uri.parse('${widget.baseUrl}/api/qr/confirm');
  }

  Future<void> _confirmPay() async {
    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      final expired = DateTime.now().isAfter(widget.expiresAt);
      if (expired) {
        throw Exception('This QR request has expired.');
      }

      //final url = _confirmUrl();
      final url = Uri.parse('${widget.baseUrl}/api/qr/confirm');
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"token": widget.qrToken, "childId": widget.childId}),
      );

      if (res.statusCode != 200) {
        // Backend not implemented yet / different response shape:
        // Show best-effort error message
        try {
          final body = jsonDecode(res.body);
          throw Exception(
            body['error'] ?? 'Payment failed (${res.statusCode}).',
          );
        } catch (_) {
          throw Exception('Payment failed (${res.statusCode}).');
        }
      }

      final data = jsonDecode(res.body);
      if (!mounted) return;

      final txnId = data["transactionId"]?.toString() ?? "-";

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Paid ✅'),
          content: Text('Transaction ID: $txnId'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to scan
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = DateTime.now().isAfter(widget.expiresAt);
    final expiresText = _formatDateTime(widget.expiresAt);

    const bg1 = Color(0xFFF7FAFC);
    const bg2 = Color(0xFFE6F4F3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.merchantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.payments_rounded,
                            color: Color(0xFF2EA49E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Amount: ${widget.amount.toStringAsFixed(2)} SAR',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: expired ? Colors.red : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expires: $expiresText',
                            style: TextStyle(
                              color: expired ? Colors.red : Colors.black54,
                              fontWeight: expired
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_rounded,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Token: ${widget.qrToken}',
                              style: const TextStyle(color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                ElevatedButton(
                  onPressed: (_paying || expired) ? null : _confirmPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EA49E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_paying ? 'Paying...' : 'Pay Now'),
                ),

                const SizedBox(height: 10),

                OutlinedButton(
                  onPressed: _paying ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2EA49E),
                    side: const BorderSide(color: Color(0xFF2EA49E)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
