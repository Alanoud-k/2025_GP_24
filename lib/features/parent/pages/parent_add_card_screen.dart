import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

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
  bool _submittedOnce = false;
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

  final Map<String, bool> _touched = {
    'card': false,
    'name': false,
    'expiry': false,
    'cvv': false,
  };

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
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
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
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.errCardNumberRequired;
    }
    final cleaned = value.replaceAll(' ', '');
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return l10n.errCardNumberDigitsOnly;
    }
    if (cleaned.length != 16) {
      return l10n.errCardNumberLength;
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.errExpiryRequired;
    }
    final text = value.trim();
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
    if (!regex.hasMatch(text)) {
      return l10n.errExpiryInvalidFormat;
    }

    final parts = text.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) {
      return l10n.errExpiryInvalid;
    }
    if (month < 1 || month > 12) {
      return l10n.errExpiryMonth;
    }
    if (year < 26) {
      return l10n.errExpiryYear;
    }

    return null;
  }

  String? _validateCVV(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.errCvvRequired;
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return l10n.errCvvDigitsOnly;
    }
    if (value.length != 3) {
      return l10n.errCvvLength;
    }
    return null;
  }

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return l10n.errCardNameRequired;
    }

    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(text)) {
      return l10n.errCardNameLettersOnly;
    }

    if (text.contains('  ')) {
      return l10n.errCardNameSpace;
    }

    final firstSpace = text.indexOf(' ');
    final lastSpace = text.lastIndexOf(' ');
    if (firstSpace == -1 || firstSpace != lastSpace) {
      return l10n.errCardNameOneSpace;
    }

    final parts = text.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length != 2) {
      return l10n.errCardNameFirstLast;
    }

    if (parts.any((p) => p.length < 3)) {
      return l10n.errCardNameMinLength;
    }

    return null;
  }

  void _recheckForm() {
    final valid =
        _validateCardNumber(_cardNumberCtrl.text) == null &&
        _validateName(_nameCtrl.text) == null &&
        _validateExpiry(_expiryCtrl.text) == null &&
        _validateCVV(_cvvCtrl.text) == null;

    if (valid != _canSubmit && mounted) {
      _canSubmit = valid;
    }
  }

  // -------- Submit to backend --------

  Future<void> _onAddCard() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submittedOnce = true);
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
        ).showSnackBar(SnackBar(content: Text(l10n.errFailedToSaveCard)));
      }
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errErrorSavingCard)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = _detectBrand(_cardNumberCtrl.text);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 24,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addNewCardTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEDEDED)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                children: [
                  // preview card
                  Container(
                    width: double.infinity,
                    height: 220,
                    margin: const EdgeInsetsDirectional.only(bottom: 24),
                    padding: const EdgeInsetsDirectional.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF37C4BE), Color(0xFF2EA49E)],
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
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
                          alignment: AlignmentDirectional.topEnd,
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
                                Text(
                                  l10n.cardHolder,
                                  style: const TextStyle(
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
                                Text(
                                  l10n.expiryDate,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _expiryCtrl.text.isEmpty
                                      ? l10n.expiryHint
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
                    autovalidateMode: _submittedOnce
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cardNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cardNumberCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(context: context),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          onTap: () => setState(() => _touched['card'] = true),
                          onChanged: (_) {
                            _touched['card'] = true;
                            _recheckForm();
                            if (_submittedOnce) setState(() {});
                          },
                          validator: (v) {
                            if (!_submittedOnce && _touched['card'] != true)
                              return null;
                            return _validateCardNumber(v);
                          },
                        ),
                        const SizedBox(height: 20),

                        Text(
                          l10n.cardHolderName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          keyboardType: TextInputType.name,
                          decoration: _inputDecoration(context: context),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z ]'),
                            ),
                          ],
                          onTap: () => setState(() => _touched['name'] = true),
                          onChanged: (_) {
                            _touched['name'] = true;
                            _recheckForm();
                            if (_submittedOnce) setState(() {});
                          },
                          validator: (v) {
                            if (!_submittedOnce && _touched['name'] != true)
                              return null;
                            return _validateName(v);
                          },
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.expiryDate,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _expiryCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      context: context,
                                      hint: l10n.expiryHint,
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(5),
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d/]'),
                                      ),
                                    ],
                                    onTap: () => setState(
                                      () => _touched['expiry'] = true,
                                    ),
                                    onChanged: (value) {
                                      _touched['expiry'] = true;

                                      if (_isEditingExpiry) return;
                                      _isEditingExpiry = true;

                                      String text = value.replaceAll(' ', '');
                                      if (text.length == 2 &&
                                          !text.contains('/')) {
                                        text = '$text/';
                                      }

                                      _expiryCtrl.value = TextEditingValue(
                                        text: text,
                                        selection: TextSelection.collapsed(
                                          offset: text.length,
                                        ),
                                      );

                                      _isEditingExpiry = false;
                                      _recheckForm();
                                      if (_submittedOnce) setState(() {});
                                    },
                                    validator: (v) {
                                      if (!_submittedOnce &&
                                          _touched['expiry'] != true)
                                        return null;
                                      return _validateExpiry(v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.cvv,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _cvvCtrl,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    decoration: _inputDecoration(context: context),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    onTap: () =>
                                        setState(() => _touched['cvv'] = true),
                                    onChanged: (_) {
                                      _touched['cvv'] = true;
                                      _recheckForm();
                                      if (_submittedOnce) setState(() {});
                                    },
                                    validator: (v) {
                                      if (!_submittedOnce &&
                                          _touched['cvv'] != true)
                                        return null;
                                      return _validateCVV(v);
                                    },
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
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.saveCardForFuture,
                          style: const TextStyle(fontSize: 13, color: kTextSecondary),
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
                      onPressed: (!_canSubmit || _isSaving) ? null : _onAddCard,
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
                          : Text(
                              l10n.addCard,
                              style: const TextStyle(fontSize: 18),
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

  InputDecoration _inputDecoration({required BuildContext context, String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 14),

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
        borderSide: const BorderSide(color: kPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.8),
      ),

      errorStyle: const TextStyle(
        color: Color(0xFFE74C3C),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
