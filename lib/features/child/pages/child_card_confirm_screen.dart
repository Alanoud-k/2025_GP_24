import 'package:flutter/material.dart';

class ChildCardConfirmScreen extends StatefulWidget {
  final int childId;
  final int receiverAccountId;
  final String token;
  final String baseUrl;

  // معلومات البطاقة القادمة من صفحة السكان/الإدخال
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  const ChildCardConfirmScreen({
    super.key,
    required this.childId,
    required this.receiverAccountId,
    required this.token,
    required this.baseUrl,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
  });

  @override
  State<ChildCardConfirmScreen> createState() => _ChildCardConfirmScreenState();
}

class _ChildCardConfirmScreenState extends State<ChildCardConfirmScreen> {
  bool _isConfirming = false;
  String? _errorMessage;

  Future<void> _confirmCard() async {
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      // TODO: هنا اربطي مع الـ backend حقكم
      // مثال (عدلي الـ endpoint حسب سيرفركم):
      //
      // final url = Uri.parse(
      //   "${widget.baseUrl}/api/child/${widget.childId}/card",
      // );
      // final res = await http.post(
      //   url,
      //   headers: {
      //     "Content-Type": "application/json",
      //     "Authorization": "Bearer ${widget.token}",
      //   },
      //   body: jsonEncode({
      //     "receiverAccountId": widget.receiverAccountId,
      //     "cardNumber": widget.cardNumber,
      //     "expiryDate": widget.expiryDate,
      //   }),
      // );
      //
      // if (res.statusCode != 200 && res.statusCode != 201) {
      //   throw Exception("Failed with status ${res.statusCode}");
      // }

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      Navigator.pop(context, true); // نرجع للشاشة السابقة مع نجاح
    } catch (e) {
      setState(() {
        _errorMessage = "Something went wrong while linking the card.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFF67AFAC);
    const Color kBg = Color(0xFFF7F8FA);

    final maskedCard = widget.cardNumber.length >= 4
        ? "•••• •••• •••• ${widget.cardNumber.substring(widget.cardNumber.length - 4)}"
        : widget.cardNumber;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Confirm card',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Review card details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Make sure the information is correct before linking it to the child wallet.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                      color: Colors.black.withOpacity(0.15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Child card",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      maskedCard,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Expiry",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.expiryDate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Type",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Child wallet card",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConfirming ? null : _confirmCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Confirm and link card",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
