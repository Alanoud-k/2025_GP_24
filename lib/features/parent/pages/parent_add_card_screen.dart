import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

enum CardBrand { visa, mastercard, mada }

const kBg = Color(0xFFF7F8FA);
const kPrimary = Color(0xFF67AFAC);
const kTextSecondary = Color(0xFF6E6E6E);

class ParentAddCardScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentAddCardScreen({
    super.key,
    required this.parentId,
    required this.token,
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
  bool _isEditingExpiry = false;
  bool _canSubmit = false;

  String? token;
  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _initialize();

    _cardNumberCtrl.addListener(_onFieldChanged);
    _expiryCtrl.addListener(_onFieldChanged);
    _cvvCtrl.addListener(_onFieldChanged);
    _nameCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    _recheckForm();
    setState(() {});
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/mobile',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // -------- Brand detection --------

  CardBrand _detectBrand(String input) {
    final digits = input.replaceAll(' ', '');
    if (digits.isEmpty) return CardBrand.mada;

    if (digits.startsWith('4')) return CardBrand.visa;

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

    return CardBrand.mada;
  }

  Widget _buildBrandLogo(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return Image.asset(
          'assets/icons/visa.png',
          height: 50,
          fit: BoxFit.contain,
        );
      case CardBrand.mastercard:
        return Image.asset(
          'assets/icons/mastercard.png',
          height: 50,
          fit: BoxFit.contain,
        );
      case CardBrand.mada:
      default:
        return SvgPicture.asset(
          'assets/icons/mada.svg',
          height: 70,
          fit: BoxFit.contain,
        );
    }
  }

  String _maskedCardNumber(String input) {
    final digits = input.replaceAll(' ', '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    if (digits.length <= 4) return '•••• •••• •••• ••••';

    final last4 = digits.substring(digits.length - 4);
    return '•••• •••• •••• $last4';
  }

  // -------- Validation helpers --------

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    final cleaned = value.replaceAll(' ', '');
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Card number must contain digits only';
    }
    if (cleaned.length != 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    final text = value.trim();
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
    if (!regex.hasMatch(text)) {
      return 'Enter a valid expiry date (MM/YY)';
    }

    // extra checks: month <= 12 and year >= 26
    final parts = text.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) {
      return 'Enter a valid expiry date';
    }
    if (month < 1 || month > 12) {
      return 'Enter a valid month';
    }
    if (year < 26) {
      return 'Expiry year must be 26 or later';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'CVV must contain digits only';
    }
    if (value.length != 3) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Name on card is required';
    }

    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(text)) {
      return 'Name must contain English letters only';
    }

    if (text.contains('  ')) {
      return 'Use only one space between first and last name';
    }

    final firstSpace = text.indexOf(' ');
    final lastSpace = text.lastIndexOf(' ');
    if (firstSpace == -1 || firstSpace != lastSpace) {
      return 'Enter first and last name with one space only';
    }

    final parts = text.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length != 2) {
      return 'Enter first and last name only';
    }

    if (parts.any((p) => p.length < 3)) {
      return 'Each name must be at least 3 letters';
    }

    return null;
  }

  void _recheckForm() {
    final valid = _validateCardNumber(_cardNumberCtrl.text) == null &&
        _validateName(_nameCtrl.text) == null &&
        _validateExpiry(_expiryCtrl.text) == null &&
        _validateCVV(_cvvCtrl.text) == null;

    if (valid != _canSubmit && mounted) {
      _canSubmit = valid;
    }
  }

  // -------- Submit to backend --------

  Future<void> _onAddCard() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _recheckForm();
      setState(() {});
      return;
    }

    if (token == null) {
      _forceLogout();
      return;
    }

    setState(() => _isSaving = true);

    final digits = _cardNumberCtrl.text.replaceAll(' ', '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';

    final brandEnum = _detectBrand(_cardNumberCtrl.text);
    final cardBrand = brandEnum == CardBrand.visa
        ? 'visa'
        : brandEnum == CardBrand.mastercard
            ? 'mastercard'
            : 'mada';

    final parts = _expiryCtrl.text.split('/');
    final expMonth = int.parse(parts[0]);
    final expYear = 2000 + int.parse(parts[1]);

    final url = Uri.parse("$baseUrl/api/parent/${widget.parentId}/card");

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'brand': cardBrand,
          'last4': last4,
          'expMonth': expMonth,
          'expYear': expYear,
        }),
      );
      if (res.statusCode == 401) {
        _forceLogout();
        return;
      }
      if (res.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to save card")));
      }
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error while saving card')));
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Card",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEDEDED),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // preview card
                  Container(
                    width: double.infinity,
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF37C4BE),
                          Color(0xFF2EA49E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: _buildBrandLogo(brand),
                        ),
                        const Spacer(),
                        Text(
                          _maskedCardNumber(_cardNumberCtrl.text),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CARD HOLDER',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _nameCtrl.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'EXPIRY DATE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _expiryCtrl.text.isEmpty
                                      ? 'MM/YY'
                                      : _expiryCtrl.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // form
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Card Number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cardNumberCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          validator: _validateCardNumber,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Card Holder Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          keyboardType: TextInputType.name,
                          decoration: _inputDecoration(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z ]'),
                            ),
                          ],
                          validator: _validateName,
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expiry Date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _expiryCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      hint: 'MM/YY',
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(5),
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d/]'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (_isEditingExpiry) return;
                                      _isEditingExpiry = true;

                                      String text = value.replaceAll(' ', '');
                                      if (text.length == 2 &&
                                          !text.contains('/')) {
                                        text = '$text/';
                                      }

                                      _expiryCtrl.value = TextEditingValue(
                                        text: text,
                                        selection:
                                            TextSelection.collapsed(
                                          offset: text.length,
                                        ),
                                      );

                                      _isEditingExpiry = false;
                                      _recheckForm();
                                      setState(() {});
                                    },
                                    validator: _validateExpiry,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CVV',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _cvvCtrl,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    decoration: _inputDecoration(),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    validator: _validateCVV,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // switch + button
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Save card details for future payments',
                          style: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                          ),
                        ),
                      ),
                      Switch(
                        value: _saveSecurely,
                        activeColor: kPrimary,
                        onChanged: (v) {
                          setState(() => _saveSecurely = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          (!_canSubmit || _isSaving) ? null : _onAddCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Add Card",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kPrimary,
          width: 1.8,
        ),
      ),
    );
  }
}
