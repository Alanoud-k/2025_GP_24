import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'package:my_app/core/api_config.dart';
import 'parent_add_card_screen.dart';

const kBg = Color(0xFFF7F8FA);
const kPrimary = Color(0xFF67AFAC);

class ParentMyCardScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentMyCardScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentMyCardScreen> createState() => _ParentMyCardScreenState();
}

class _ParentMyCardScreenState extends State<ParentMyCardScreen> {
  bool _isLoading = false;
  bool _hasCard = false;

  String? _brand;
  String? _last4;
  int? _expMonth;
  int? _expYear;

  String get token => widget.token;
  int get parentId => widget.parentId;
  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchCard();
  }

  Future<void> _fetchCard() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("$baseUrl/api/parent/$parentId/card");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final brand = data['brand'] as String?;
        final last4 = data['last4']?.toString();
        final expMonthRaw = data['expMonth'];
        final expYearRaw = data['expYear'];

        final expMonth = expMonthRaw is int
            ? expMonthRaw
            : int.tryParse(expMonthRaw?.toString() ?? '');
        final expYear = expYearRaw is int
            ? expYearRaw
            : int.tryParse(expYearRaw?.toString() ?? '');

        final hasRealCard =
            last4 != null &&
            last4.isNotEmpty &&
            brand != null &&
            brand.isNotEmpty;

        setState(() {
          _hasCard = hasRealCard;
          _brand = brand;
          _last4 = last4;
          _expMonth = expMonth;
          _expYear = expYear;
          _isLoading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _hasCard = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasCard = false;
          _isLoading = false;
        });
        _showErrorBar('Failed to load card');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCard = false;
        _isLoading = false;
      });
      _showErrorBar('Error while loading card');
    }
  }

  String _brandLabel() {
    switch (_brand) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'mada':
        return 'Mada';
      default:
        return 'Card';
    }
  }

  Widget _brandLogo() {
    switch (_brand) {
      case 'visa':
        return Image.asset(
          'assets/icons/visa.png',
          height: 28,
          fit: BoxFit.contain,
        );
      case 'mastercard':
        return Image.asset(
          'assets/icons/mastercard.png',
          height: 28,
          fit: BoxFit.contain,
        );
      default:
        return SvgPicture.asset(
          'assets/icons/mada.svg',
          height: 28,
          fit: BoxFit.contain,
        );
    }
  }

  String _formattedExpiry() {
    if (_expMonth == null || _expYear == null) return 'MM/YY';
    final mm = _expMonth!.toString().padLeft(2, '0');
    final yy = (_expYear! % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  Future<void> _confirmDelete() async {
    final confirmed = await _showConfirmDialog(
      title: "Remove card?",
      message:
          "Are you sure you want to remove this card? You can add a new one later.",
      confirmText: "Remove",
      confirmColor: const Color(0xFFE74C3C),
    );

    if (confirmed) {
      await _deleteCard();
    }
  }

  // ✅ Unified Hassala Snackbars
  void _showErrorBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2EA49E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ Unified Hassala-style confirm dialog (teal)
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    String cancelText = "Cancel",
    Color confirmColor = const Color(0xFFE74C3C), // red for destructive
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF37C4BE).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.credit_card_off_rounded,
                        color: Color(0xFF2EA49E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2C3E50),
                            side: BorderSide(
                              color: Colors.black12.withOpacity(0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            cancelText,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
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

    return result ?? false;
  }

  Future<void> _deleteCard() async {
    final url = Uri.parse("$baseUrl/api/parent/$parentId/card");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      // Debug prints to see what backend returns
      // تشوفينها في debug console في VS Code / Android Studio
      print('DELETE status: ${res.statusCode}');
      if (res.body.isNotEmpty) {
        print('DELETE body: ${res.body}');
      }

      if (res.statusCode == 200 || res.statusCode == 204) {
        _showSuccessBar('Card removed successfully');
        Navigator.pop(context, true);
        //Navigator.pop(context, true);
      } else if (res.statusCode == 404) {
        // No card already → اعتبرها نجاح وارجعي للهوم
        Navigator.pop(context, true);
      } else {
        _showErrorBar('Failed to remove card (code: ${res.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      print('DELETE error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while removing card')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'My Card',
          style: TextStyle(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _hasCard ? _buildHasCardView() : _buildNoCardView(),
            ),
    );
  }

  Widget _buildHasCardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F4F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _brandLogo(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _last4 != null ? '•••• ${_last4!}' : '•••• ••••',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _brandLabel(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Expires',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formattedExpiry(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
        const Text(
          'Only one card can be saved for this parent account.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const Spacer(),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentAddCardScreen(
                          parentId: parentId,
                          token: token,
                        ),
                      ),
                    );
                    if (updated == true && mounted) {
                      await _fetchCard();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Edit Card',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'Remove Card',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoCardView() {
    Future.microtask(() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    });
    return const SizedBox.shrink();
  }
}
