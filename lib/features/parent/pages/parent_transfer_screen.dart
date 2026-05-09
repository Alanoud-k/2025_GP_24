import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ParentTransferScreen extends StatefulWidget {
  final int parentId;
  final int childId;
  final String childName;
  final String childBalance;
  final String token;

  final double? initialAmount;
  final int? requestId;

  const ParentTransferScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.childBalance,
    required this.token,
    this.initialAmount,
    this.requestId,
  });

  @override
  State<ParentTransferScreen> createState() => _ParentTransferScreenState();
}

class _ParentTransferScreenState extends State<ParentTransferScreen> {
  final TextEditingController _amount = TextEditingController();
  double savingPercentage = 0;
  String? token;
  late final String baseUrl = ApiConfig.baseUrl;

  String parentCurrentBalance = "...";

  @override
  void initState() {
    super.initState();
    _initialize();

    if (widget.initialAmount != null) {
      _amount.text = widget.initialAmount.toString();
      savingPercentage = 0;
    }
  }

  double get _currentParsedAmount {
    if (_amount.text.trim().isEmpty) return 0.0;
    return double.tryParse(_amount.text) ?? 0.0;
  }

  double get _calculatedSavingAmount => _currentParsedAmount * (savingPercentage / 100);
  double get _calculatedSpendingAmount => _currentParsedAmount * ((100 - savingPercentage) / 100);

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    await _loadToken();
    await _fetchParentBalance();
    await _fetchChildDefaultRatio();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
  }

  Future<void> _fetchParentBalance() async {
    try {
      final url = Uri.parse('$baseUrl/api/parent/${widget.parentId}');
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final b = data['walletbalance'] ?? data['balance'] ?? 0;
        final double val = (b is num)
            ? b.toDouble()
            : double.tryParse(b.toString()) ?? 0.0;

        if (mounted) {
          setState(() {
            parentCurrentBalance = val.toStringAsFixed(2);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching parent balance: $e");
    }
  }

  Widget _sarIcon({double size = 14, Color? color}) {
    return Image.asset(
      'assets/icons/Sar.png',
      width: size,
      height: size,
      color: color,
    );
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
        duration: const Duration(milliseconds: 4000),
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
        duration: const Duration(milliseconds: 3500),
      ),
    );
  }

  Future<void> _fetchChildDefaultRatio() async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/auth/parent/${widget.parentId}/children',
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List children = jsonDecode(response.body);

        final child = children.firstWhere(
          (c) => c["childId"] == widget.childId,
          orElse: () => null,
        );

        if (child != null) {
          final ratio = (child["defaultSavingRatio"] ?? 0) as num;

          if (mounted && widget.initialAmount == null) {
            setState(() {
              savingPercentage = ratio * 100;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching child ratio: $e");
    }
  }

  Future<void> _transfer(AppLocalizations l10n) async {
    if (_amount.text.trim().isEmpty || double.tryParse(_amount.text) == null) {
      _showErrorBar(l10n.pleaseEnterValidAmount);
      return;
    }

    final url = Uri.parse('$baseUrl/api/auth/transfer');
    final amount = double.parse(_amount.text);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'parentId': widget.parentId,
          'childId': widget.childId,
          'amount': amount,
          'savePercentage': savingPercentage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final double save = (data['saveAmount'] as num).toDouble();
        final double spend = (data['spendAmount'] as num).toDouble();

        if (widget.requestId != null) {
          await _markRequestAsApproved(widget.requestId!);
        }

        _showSuccess(save, spend, l10n);
      } else {
        String message = l10n.transferFailed;
        try {
          final decoded = jsonDecode(response.body);
          message = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : message;
        } catch (_) {}
        _showErrorBar(message);
      }
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }
    } catch (e) {
      debugPrint("Transfer error: $e");
      _showErrorBar(l10n.networkErrorTryAgain);
    }
  }

  Future<void> _markRequestAsApproved(int reqId) async {
    try {
      final url = Uri.parse('$baseUrl/api/money-requests/update');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({"requestId": reqId, "status": "Approved"}),
      );
    } catch (e) {
      debugPrint("Error auto-approving request: $e");
    }
  }

  void _showSuccess(double save, double spend, AppLocalizations l10n) {
    const kTextDark = Color(0xFF2C3E50);
    const kGreen1 = Color(0xFF37C4BE);
    const kGreen2 = Color(0xFF2EA49E);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen1.withOpacity(0.14),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 34,
                    color: kGreen2,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  l10n.transferSuccessful,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kTextDark,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      _successRow(
                        label: l10n.savingLabel,
                        value: save,
                        valueColor: kGreen2,
                      ),
                      const SizedBox(height: 8),
                      _successRow(
                        label: l10n.spendingLabel,
                        value: spend,
                        valueColor: Colors.amber.shade700,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  l10n.updateChildWalletPrompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context, true);
    });
  }

  static Widget _successRow({
    required String label,
    required double value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade700,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 6),
            Image.asset(
              'assets/icons/Sar.png',
              width: 14,
              height: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool showSar = false,
  }) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    if (showSar) ...[
                      const SizedBox(width: 6),
                      _sarIcon(size: 14, color: Colors.grey),
                    ],
                  ],
                ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          l10n.transferTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context), // 👈 هذا ما سيعيدك لصفحة اختيار الطفل!
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoCard(
              icon: Icons.groups_2_rounded,
              title: l10n.fromParent,
              subtitle: l10n.balanceAmount(parentCurrentBalance),
              color: Colors.teal,
              showSar: true,
            ),
            _infoCard(
              icon: Icons.person_rounded,
              title: l10n.toChild(widget.childName),
              subtitle: l10n.balanceAmount(widget.childBalance),
              color: Colors.amber,
              showSar: true,
            ),
            const SizedBox(height: 30),

            // Amount Input
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩\.]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        String text = newValue.text
                            .replaceAll('٠', '0')
                            .replaceAll('١', '1')
                            .replaceAll('٢', '2')
                            .replaceAll('٣', '3')
                            .replaceAll('٤', '4')
                            .replaceAll('٥', '5')
                            .replaceAll('٦', '6')
                            .replaceAll('٧', '7')
                            .replaceAll('٨', '8')
                            .replaceAll('٩', '9');
                        return newValue.copyWith(
                          text: text,
                          selection: newValue.selection,
                        );
                      }),
                    ],
                    textAlign: TextAlign.center,
                    onChanged: (_) {
                      setState(() {});
                    },
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "00.00",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsetsDirectional.only(
                        end: 34,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 2,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: _sarIcon(size: 18, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Save/Spend Split Slider
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    l10n.splitSavingSpending,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Spending Text + Value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.spendPercentage((100 - savingPercentage).toStringAsFixed(0)),
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _calculatedSpendingAmount.toStringAsFixed(2),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sarIcon(size: 10, color: Colors.grey.shade600),
                            ],
                          ),
                        ],
                      ),
                      
                      // Saving Text + Value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.savePercentage(savingPercentage.toStringAsFixed(0)),
                            style: const TextStyle(
                              color: Color(0xFF7E57C2),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _calculatedSavingAmount.toStringAsFixed(2),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sarIcon(size: 10, color: Colors.grey.shade600),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: savingPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: const Color(0xFF2EA49E),
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (value) {
                      setState(() {
                        savingPercentage = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _transfer(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EA49E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  l10n.continue_, 
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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