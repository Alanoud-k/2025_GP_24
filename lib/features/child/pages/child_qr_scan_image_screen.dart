import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'child_qr_confirm_screen.dart';

class ChildQrScanImageScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildQrScanImageScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildQrScanImageScreen> createState() => _ChildQrScanImageScreenState();
}

class _ChildQrScanImageScreenState extends State<ChildQrScanImageScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String? _pickedPath;
  String? _error;

  // Demo QR (generated from backend)
  bool _creatingQr = false;
  String? _demoQrString; // full payload: HASSALA_PAY:1:<token>
  String? _demoToken;
  DateTime? _demoExpiresAt;
  String? _demoMerchantName;
  double? _demoAmount;

  // Inputs for demo QR
  final TextEditingController _merchantCtrl = TextEditingController(
    text: "Demo Merchant",
  );
  final TextEditingController _amountCtrl = TextEditingController(
    text: "10.00",
  );

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String _extractToken(String raw) {
    // Expected format: HASSALA_PAY:1:<token>
    final parts = raw.split(':');
    if (parts.length == 3 && parts[0] == 'HASSALA_PAY' && parts[1] == '1') {
      return parts[2];
    }
    throw Exception('Invalid QR format');
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

  Future<void> _pickAndScan() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        setState(() => _loading = false);
        return;
      }

      setState(() => _pickedPath = file.path);

      // ---- Scan QR from Image using ML Kit ----
      final inputImage = InputImage.fromFilePath(file.path);
      final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

      final barcodes = await scanner.processImage(inputImage);
      await scanner.close();

      if (barcodes.isEmpty) {
        setState(() {
          _loading = false;
          _error = "No QR code found in this image.";
        });
        return;
      }

      final raw = barcodes.first.rawValue ?? '';
      if (raw.isEmpty) {
        setState(() {
          _loading = false;
          _error = "QR detected but unreadable.";
        });
        return;
      }

      await _goToConfirmFromQrRaw(raw);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _goToConfirmFromQrRaw(String raw) async {
    final token = _extractToken(raw);

    // Resolve token from backend (merchant + amount + expiry)
    final info = await _resolveToken(token);

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildQrConfirmScreen(
          childId: widget.childId,
          baseUrl: widget.baseUrl,
          token: widget.token,
          qrToken: token,
          merchantName: (info['merchantname'] ?? '') as String,
          amount: (info['amount'] as num).toDouble(),
          expiresAt: DateTime.parse(info['expiresat'] as String),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _resolveToken(String token) async {
    final url = Uri.parse('${widget.baseUrl}/api/qr/resolve?token=$token');

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      try {
        final body = jsonDecode(res.body);
        throw Exception(body['error'] ?? 'Failed to resolve QR.');
      } catch (_) {
        throw Exception('Failed to resolve QR.');
      }
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _openGenerateDialog() async {
    setState(() => _error = null);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Generate Demo QR",
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
                    labelText: "Merchant name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Amount (SAR)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _creatingQr
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2EA49E),
                          side: const BorderSide(color: Color(0xFF2EA49E)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _creatingQr
                            ? null
                            : () async {
                                await _createDemoQr();
                                if (mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EA49E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(_creatingQr ? "Generating..." : "Generate"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createDemoQr() async {
    setState(() {
      _error = null;
      _creatingQr = true;
      _demoQrString = null;
      _demoToken = null;
      _demoExpiresAt = null;
      _demoMerchantName = null;
      _demoAmount = null;
    });

    try {
      final merchantName = _merchantCtrl.text.trim();
      final amount = double.tryParse(_amountCtrl.text.trim());

      if (merchantName.isEmpty) {
        throw Exception("Please enter merchant name.");
      }
      if (amount == null || amount <= 0) {
        throw Exception("Please enter a valid amount.");
      }

      // Backend endpoint you will implement:
      // POST /api/qr/create
      // Body: { merchantName, amount }
      final url = Uri.parse('${widget.baseUrl}/api/qr/create');

      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"merchantName": merchantName, "amount": amount}),
      );

      if (res.statusCode != 200) {
        try {
          final body = jsonDecode(res.body);
          throw Exception(body['error'] ?? 'Failed to create demo QR.');
        } catch (_) {
          throw Exception('Failed to create demo QR.');
        }
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final token = (data["token"] ?? "").toString();
      final qrString = (data["qrString"] ?? "").toString();
      final expiresAtStr = (data["expiresAt"] ?? data["expiresat"] ?? "")
          .toString();

      if (token.isEmpty || qrString.isEmpty || expiresAtStr.isEmpty) {
        throw Exception("Backend response missing token/qrString/expiresAt.");
      }

      setState(() {
        _demoToken = token;
        _demoQrString = qrString;
        _demoExpiresAt = DateTime.parse(expiresAtStr);
        _demoMerchantName = merchantName;
        _demoAmount = amount;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _creatingQr = false);
    }
  }

  Future<void> _useDemoQr() async {
    if (_demoQrString == null) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await _goToConfirmFromQrRaw(_demoQrString!);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg1 = Color(0xFFF7FAFC);
    const bg2 = Color(0xFFE6F4F3);

    final hasDemo = _demoQrString != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay by QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ removes back arrow
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
                // Scan card
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
                        'Scan a QR image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a QR image from your gallery (emulator-friendly).',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: (_loading || _creatingQr)
                            ? null
                            : _pickAndScan,
                        icon: const Icon(Icons.image_search),
                        label: Text(
                          _loading ? 'Scanning...' : 'Choose QR Image',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EA49E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: (_loading || _creatingQr)
                            ? null
                            : _openGenerateDialog,
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: Text(
                          _creatingQr ? 'Generating...' : 'Generate Demo QR',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2EA49E),
                          side: const BorderSide(color: Color(0xFF2EA49E)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Preview picked image
                if (_pickedPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      File(_pickedPath!),
                      height: 240,
                      fit: BoxFit.cover,
                    ),
                  ),

                // Demo QR card
                if (hasDemo) ...[
                  const SizedBox(height: 16),
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
                        const Text(
                          "Demo QR (Generated)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        QrImageView(data: _demoQrString!, size: 220),
                        const SizedBox(height: 10),
                        if (_demoMerchantName != null && _demoAmount != null)
                          Text(
                            '${_demoMerchantName!} • ${_demoAmount!.toStringAsFixed(2)} SAR',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        const SizedBox(height: 6),
                        if (_demoExpiresAt != null)
                          Text(
                            'Expires: ${_formatDateTime(_demoExpiresAt!)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: (_loading || _creatingQr)
                              ? null
                              : _useDemoQr,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EA49E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Use This QR (Continue)"),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: (_loading || _creatingQr)
                              ? null
                              : () {
                                  setState(() {
                                    _demoQrString = null;
                                    _demoToken = null;
                                    _demoExpiresAt = null;
                                    _demoMerchantName = null;
                                    _demoAmount = null;
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2EA49E),
                            side: const BorderSide(color: Color(0xFF2EA49E)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Clear Demo QR"),
                        ),
                      ],
                    ),
                  ),
                ],

                // Error box
                if (_error != null) ...[
                  const SizedBox(height: 12),
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
