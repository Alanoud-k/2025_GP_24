import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';
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
    // Use addPostFrameCallback to safely access AppLocalizations initially if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      _fetchCard(l10n);
    });
  }

  Future<void> _fetchCard(AppLocalizations l10n) async {
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
        _showErrorBar(l10n.failedToLoadCard);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCard = false;
        _isLoading = false;
      });
      _showErrorBar(l10n.errorLoadingCard);
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
        return 'Card'; // Or localize if you prefer: l10n.card
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

  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final confirmed = await _showConfirmDialog(
      title: l10n.removeCardTitle,
      message: l10n.removeCardMessage,
      confirmText: l10n.remove,
      cancelText: l10n.cancel,
      confirmColor: const Color(0xFFE74C3C),
    );

    if (confirmed) {
      await _deleteCard(l10n);
    }
  }

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

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    Color confirmColor = const Color(0xFFE74C3C),
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
            padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 14),
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

  Future<void> _deleteCard(AppLocalizations l10n) async {
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

      if (res.statusCode == 200 || res.statusCode == 204) {
        _showSuccessBar(l10n.cardRemovedSuccess);
        Navigator.pop(context, true);
      } else if (res.statusCode == 404) {
        Navigator.pop(context, true);
      } else {
        _showErrorBar(l10n.failedToRemoveCard(res.statusCode));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingCard)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading:  IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
        title: Text(
          l10n.myCard,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _hasCard ? _buildHasCardView(l10n) : _buildNoCardView(),
            ),
    );
  }

  Widget _buildHasCardView(AppLocalizations l10n) {
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
                  Text(
                    l10n.paymentMethod,
                    style: const TextStyle(
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
                    child: Text(
                      l10n.active,
                      style: const TextStyle(
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
                      Text(
                        l10n.expires,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
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
        Text(
          l10n.onlyOneCardSaved,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      await _fetchCard(l10n);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.editCard,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => _confirmDelete(l10n),
                  child: Text(
                    l10n.removeCard,
                    style: const TextStyle(
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
  final l10n = AppLocalizations.of(context)!;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.credit_card_off, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text(l10n.noCardFoundTitle, style: TextStyle(fontSize: 18, color: Colors.grey)), // أضف مفتاح ترجمة لهذا
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/addCard'),
          child: Text(l10n.addCard),
        ),
      ],
    ),
  );
}
}