// ==================================
// merchant_qr_generate_screen.dart
// ==================================
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class MerchantQrGenerateScreen extends StatefulWidget {
  final String baseUrl;
  final String token;

  // Optional: if you want to pass a fixed merchant name
  final String? defaultMerchantName;

  const MerchantQrGenerateScreen({
    super.key,
    required this.baseUrl,
    required this.token,
    this.defaultMerchantName,
  });

  @override
  State<MerchantQrGenerateScreen> createState() =>
      _MerchantQrGenerateScreenState();
}

class _MerchantQrGenerateScreenState extends State<MerchantQrGenerateScreen> {
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '10.00');

  bool _loading = false;
  String? _error;

  String? _qrString;
  String? _token;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _merchantCtrl.text = widget.defaultMerchantName ?? 'Demo Merchant';
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Uri _createUrl() {
    // When you build the backend, keep this consistent:
    // POST {baseUrl}/api/qr/create
    // If you decide NOT to use /api, change to: '${widget.baseUrl}/qr/create'
    return Uri.parse('${widget.baseUrl}/api/qr/create');
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _qrString = null;
      _token = null;
      _expiresAt = null;
    });

    try {
      final merchantName = _merchantCtrl.text.trim();
      final amount = double.tryParse(_amountCtrl.text.trim());

      if (merchantName.isEmpty) {
        throw Exception('Enter merchant name.');
      }
      if (amount == null || amount <= 0) {
        throw Exception('Enter a valid amount.');
      }

      final res = await http.post(
        _createUrl(),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"merchantName": merchantName, "amount": amount}),
      );

      if (res.statusCode != 200) {
        try {
          final body = jsonDecode(res.body);
          throw Exception(
            body['error'] ?? 'Failed to create QR (${res.statusCode}).',
          );
        } catch (_) {
          throw Exception('Failed to create QR (${res.statusCode}).');
        }
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final qrString = (data['qrString'] ?? '') as String;
      final token = (data['token'] ?? '') as String;
      final expiresAtStr = data['expiresAt']?.toString();

      if (qrString.isEmpty || token.isEmpty || expiresAtStr == null) {
        throw Exception('Backend response missing qrString/token/expiresAt.');
      }

      setState(() {
        _qrString = qrString;
        _token = token;
        _expiresAt = DateTime.parse(expiresAtStr);
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    const bg1 = Color(0xFFF7FAFC);
    const bg2 = Color(0xFFE6F4F3);
    const primary = Color(0xFF2EA49E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Merchant QR (Demo)'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      const Text(
                        'Merchant details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _merchantCtrl,
                        decoration: InputDecoration(
                          labelText: 'Merchant name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (SAR)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      ElevatedButton(
                        onPressed: _loading ? null : _generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(_loading ? 'Generating...' : 'Generate QR'),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_qrString != null) ...[
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
                      children: [
                        QrImageView(data: _qrString!, size: 220),
                        const SizedBox(height: 12),
                        Text(
                          'Token: ${_token ?? "-"}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Expires: ${_expiresAt == null ? "-" : _formatDateTime(_expiresAt!)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _qrString!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
