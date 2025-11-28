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
  // لو حابة تضيفين سكان بالكاميرا بعدين، نخلي المتغيرات جاهزة
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _goToConfirmScreen() {
    final cardNumber = _cardNumberController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if (cardNumber.isEmpty || expiry.isEmpty || cvv.isEmpty) {
      setState(() {
        _errorMessage = "Please fill all card details.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildCardConfirmScreen(
          childId: widget.childId,
          receiverAccountId: widget.receiverAccountId,
          token: widget.token,
          baseUrl: widget.baseUrl,
          cardNumber: cardNumber,
          expiryDate: expiry,
          cvv: cvv,
        ),
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Add Card',
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
                "Child card details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Enter the card information or connect it to the child wallet.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // مستطيل كأنه placeholder للسكان/الكاميرا
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 40,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Card scan area",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "You can add card details manually below.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // رقم البطاقة
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Card number",
                  hintText: "XXXX XXXX XXXX XXXX",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: "Expiry date",
                        hintText: "MM/YY",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "CVV",
                        hintText: "XXX",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

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
                  onPressed: _isLoading ? null : _goToConfirmScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Continue",
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
