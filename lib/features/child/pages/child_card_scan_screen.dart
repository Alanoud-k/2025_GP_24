import 'package:flutter/material.dart';
import 'child_card_confirm_screen.dart';

class ChildCardScanScreen extends StatefulWidget {
  final int childId;
  final int receiverAccountId;
  final String token;
  final String baseUrl;

  const ChildCardScanScreen({
    super.key,
    required this.childId,
    required this.receiverAccountId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ChildCardScanScreen> createState() => _ChildCardScanScreenState();
}

class _ChildCardScanScreenState extends State<ChildCardScanScreen> {
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    // Fake scan delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        isScanning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFF67AFAC);
    const Color kBg = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
        title: const Text(
          "Scan to pay",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    offset: const Offset(0, 14),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 120,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isScanning ? "Scanning QR code..." : "QR code scanned",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "In the real version this screen will scan the merchant QR. "
                    "For now we will use fake details for testing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isScanning)
                    const CircularProgressIndicator(color: kPrimary)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          // Example fake data after scan
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChildCardConfirmScreen(
                                childId: widget.childId,
                                receiverAccountId: widget.receiverAccountId,
                                token: widget.token,
                                baseUrl: widget.baseUrl,
                                initialMerchant: "STARBUCKS RIYADH",
                                initialMcc: "5814",
                                initialAmount: "30.50",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
