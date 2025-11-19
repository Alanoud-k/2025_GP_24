import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Top-level enums & constants

enum CardBrand { visa, mastercard, other }

// Hassalah colors
const kBg = Color(0xFFF7F8FA);
const kPrimary = Color(0xFF67AFAC);
const kPrimaryDark = Color(0xFF4B8F8C);
const kCard = Color(0xFF9FE5E2);
const kTextSecondary = Color(0xFF6E6E6E);

const String kBaseUrl = 'http://10.0.2.2:3000';

// Screen

class ParentAddCardScreen extends StatefulWidget {
  final int parentId; // parent id from home page

  const ParentAddCardScreen({
    super.key,
    required this.parentId,
  });

  @override
  State<ParentAddCardScreen> createState() => _ParentAddCardScreenState();
}

class _ParentAddCardScreenState extends State<ParentAddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _saveSecurely = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // Card brand detection logic

  CardBrand _detectBrand(String input) {
    final digits = input.replaceAll(' ', '');
    if (digits.isEmpty) return CardBrand.other;

    // Visa: starts with 4
    if (digits.startsWith('4')) return CardBrand.visa;

    // Mastercard: 51–55 or 2221–2720
    if (digits.length >= 2) {
      final firstTwo = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (firstTwo >= 51 && firstTwo <= 55) return CardBrand.mastercard;
    }
    if (digits.length >= 4) {
      final firstFour = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (firstFour >= 2221 && firstFour <= 2720) {
        return CardBrand.mastercard;
      }
    }

    return CardBrand.other;
  }

  Widget _buildBrandChip(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        );
      case CardBrand.mastercard:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Mastercard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        );
      case CardBrand.other:
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card, size: 16),
              SizedBox(width: 4),
              Text(
                'Card',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
    }
  }

  String _maskedCardNumber(String input) {
    final digits = input.replaceAll(' ', '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    if (digits.length <= 8) return '•••• •••• •••• ••••';

    final first4 = digits.substring(0, 4);
    final last4 = digits.substring(digits.length - 4);
    return '$first4 •••• $last4';
  }

  String _last4(String input) {
    final digits = input.replaceAll(' ', '');
    if (digits.length < 4) return '••••';
    return digits.substring(digits.length - 4);
  }

  Future<void> _onAddCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final digits = _cardNumberCtrl.text.replaceAll(' ', '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';

    final brandEnum = _detectBrand(_cardNumberCtrl.text);
    final cardBrand = brandEnum == CardBrand.visa
        ? 'visa'
        : brandEnum == CardBrand.mastercard
            ? 'mastercard'
            : 'other';

    int expMonth = 1;
    int expYear = 0;
    if (_expiryCtrl.text.contains('/')) {
      final parts = _expiryCtrl.text.split('/');
      if (parts.length == 2) {
        expMonth = int.tryParse(parts[0]) ?? 1;
        final yy = int.tryParse(parts[1]) ?? 0;
        expYear = yy < 100 ? 2000 + yy : yy;
      }
    }

    final url = Uri.parse(
      '$kBaseUrl/api/parent/${widget.parentId}/card',
    );

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cardBrand': cardBrand,
          'last4': last4,
          'expMonth': expMonth,
          'expYear': expYear,
        }),
      );

      if (res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save card')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while saving card')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = _detectBrand(_cardNumberCtrl.text);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header + preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // back + title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Add New Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // card preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimaryDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // brand + expiry + last4
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBrandChip(brand),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _expiryCtrl.text.isEmpty
                                      ? 'MM/YY'
                                      : _expiryCtrl.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _last4(_cardNumberCtrl.text),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _maskedCardNumber(_cardNumberCtrl.text),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'Cardholder Name'
                              : _nameCtrl.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Debit Card',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Card number
                      TextFormField(
                        controller: _cardNumberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildBrandChip(brand),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Required';
                          }
                          final cleaned = v.replaceAll(' ', '');
                          if (cleaned.length < 12) {
                            return 'Enter a valid card number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryCtrl,
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                labelText: 'Expiry Date',
                                hintText: 'MM/YY',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvCtrl,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Name on Card',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _saveSecurely,
                        onChanged: (v) {
                          setState(() => _saveSecurely = v ?? true);
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Securely save card and details (demo only)',
                          style: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom button
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onAddCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Saving...' : 'Add Card',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
