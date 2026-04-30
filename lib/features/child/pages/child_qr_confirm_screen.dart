import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/l10n/app_localizations.dart';
import 'child_homepage_screen.dart'; // ✅ add this at the top

class ChildQrConfirmScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  final String qrToken;
  final String merchantName;
  final double amount;
  final DateTime expiresAt;

  const ChildQrConfirmScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
    required this.qrToken,
    required this.merchantName,
    required this.amount,
    required this.expiresAt,
  });

  @override
  State<ChildQrConfirmScreen> createState() => _ChildQrConfirmScreenState();
}

class _ChildQrConfirmScreenState extends State<ChildQrConfirmScreen> {
  bool _paying = false;
  String? _error;

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  // ======================
  // Riyal icon (SAR symbol)
  // Make sure pubspec.yaml includes: assets/icons/Sar.png
  // ======================
  Widget _sarIcon({double size = 18}) {
    return Image.asset(
      'assets/icons/Sar.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }

  String _formatNow() => _formatDateTime(DateTime.now());

  Uri _confirmUrl() {
    // When you build the backend, keep it consistent with the scan screen.
    // Recommended convention:
    //   GET  {baseUrl}/api/qr/resolve?token=...
    //   POST {baseUrl}/api/qr/confirm
    //
    // If you decide NOT to use /api, just change this to: '${widget.baseUrl}/qr/confirm'
    return Uri.parse('${widget.baseUrl}/api/qr/confirm');
  }

  Future<void> _confirmPay() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      final expired = DateTime.now().isAfter(widget.expiresAt);
      if (expired) {
        throw Exception(l10n.qrExpiredError);
      }

      //final url = _confirmUrl();
      final url = Uri.parse('${widget.baseUrl}/api/qr/confirm');
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"token": widget.qrToken, "childId": widget.childId}),
      );

      if (res.statusCode != 200) {
        // Backend not implemented yet / different response shape:
        // Show best-effort error message
        try {
          final body = jsonDecode(res.body);
          throw Exception(
            body['error'] ?? l10n.paymentFailedError(res.statusCode),
          );
        } catch (_) {
          throw Exception(l10n.paymentFailedError(res.statusCode));
        }
      }

      final paidAt = _formatNow();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EA49E).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF2EA49E),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.paidStatus,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Summary rows (kid-friendly)
                  _summaryRow(context, l10n.merchantLabel, widget.merchantName),
                  _amountSummaryRow(context, widget.amount), // ✅ amount + Riyal icon

                  _summaryRow(context, l10n.timeLabel, paidAt),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // 1) close the success sheet
                        Navigator.pop(context);

                        // 2) go to ChildShell and clear the stack so they can’t press Pay again
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/childShell',
                          (route) => false,
                          arguments: {
                            'childId': widget.childId,
                            'token': widget.token,
                            'baseUrl': widget.baseUrl,
                          },
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EA49E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.doneButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================
  // Amount row with Riyal icon (used in the success popup)
  // ======================
  Widget _amountSummaryRow(BuildContext context, double amount) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              l10n.amountLabel,
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  amount.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 6),
                _sarIcon(size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expired = DateTime.now().isAfter(widget.expiresAt);

    const primary = Color(0xFF37C4BE);
    const bg1 = Color(0xFFF7FAFC);
    const bg2 = Color(0xFFE6F4F3);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.confirmPaymentTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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
          child: Padding(
            padding: const EdgeInsetsDirectional.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔥 TOP AMOUNT CARD
                Container(
                  padding: const EdgeInsetsDirectional.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF37C4BE), Color(0xFF6EE7DF)],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.aboutToPay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.amount.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // ✅ WHITE RIYAL ICON
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            child: _sarIcon(size: 26),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 DETAILS CARD
                Container(
                  padding: const EdgeInsetsDirectional.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _summaryRow(context, l10n.merchantLabel, widget.merchantName),
                      const SizedBox(height: 10),
                      _amountSummaryRow(context, widget.amount),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.expiresAtLabel(_formatDateTime(widget.expiresAt)),
                              style: TextStyle(
                                color: expired ? Colors.red : Colors.black54,
                                fontWeight: expired
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ❌ ERROR BOX
                if (_error != null)
                  Container(
                    padding: const EdgeInsetsDirectional.all(12),
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

                const Spacer(),

                // 🔥 PAY BUTTON
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_paying || expired) ? null : _confirmPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _paying ? l10n.processingStatus : l10n.payNowButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // CANCEL BUTTON
                OutlinedButton(
                  onPressed: _paying ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(l10n.cancelButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
