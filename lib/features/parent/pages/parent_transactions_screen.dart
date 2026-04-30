import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/l10n/app_localizations.dart';

class ParentTransactionsScreen extends StatefulWidget {
  final int parentId;
  final String token;
  final String baseUrl;

  const ParentTransactionsScreen({
    super.key,
    required this.parentId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ParentTransactionsScreen> createState() =>
      _ParentTransactionsScreenState();
}

class _ParentTransactionsScreenState extends State<ParentTransactionsScreen> {
  static const Color kPrimary = Color(0xFF37C4BE);
  static const Color kBg = Color(0xFFF7F8FA);
  static const Color kTextDark = Color(0xFF222222);

  bool _isLoading = false;
  String? _errorMessage;
  List<ParentTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTransactions();
    });
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final url = Uri.parse(
        "${widget.baseUrl}/api/parent/${widget.parentId}/transactions",
      );

      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;

        final List<dynamic> list = decoded["data"] ?? [];

        final List<ParentTransaction> items = list
            .map((e) => ParentTransaction.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _transactions = items;
        });
      } else {
        setState(() {
          _errorMessage = l10n.failedToLoadTransactionsCode(res.statusCode.toString());
        });
      }
    } catch (e, stack) {
      debugPrint("Parent _fetchTransactions error: $e\n$stack");

      if (!mounted) return;
      setState(() {
        _errorMessage = l10n.somethingWentWrongError(e.toString());
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Color _amountColor(String type) {
    switch (type.toLowerCase()) {
      case "spend":
      case "transfer_out":
        return const Color(0xFFE57373); // red
      case "deposit":
      case "transfer_in":
        return const Color(0xFF2BBE7A); // green
      default:
        return Colors.black54;
    }
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains("food") || c.contains("restaurant") || c.contains("cafe")) {
      return Icons.restaurant_rounded;
    }
    if (c.contains("pharmacy") || c.contains("health")) {
      return Icons.local_pharmacy_rounded;
    }
    if (c.contains("shopping") || c.contains("store")) {
      return Icons.shopping_bag_rounded;
    }
    if (c.contains("transport")) {
      return Icons.directions_bus_rounded;
    }
    if (c.contains("top-up") || c.contains("wallet") || c.contains("allowance") || c.contains("saving") || c.contains("spending")) {
      return Icons.account_balance_wallet_rounded;
    }
    if (c.contains("child") || c.contains("transfer")) {
      return Icons.swap_horiz_rounded;
    }
    return Icons.payment_rounded;
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
        leading: IconButton(
          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: kTextDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.transactionsTitle,
          style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _fetchTransactions,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Text(
          l10n.noTransactionsYet,
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return _TransactionCard(
          transaction: tx,
          amountColor: _amountColor(tx.type),
          icon: _categoryIcon(tx.category),
          l10n: l10n,
        );
      },
    );
  }
}

// ===================== MODEL =====================

class ParentTransaction {
  final int id;
  final String type;
  final double amount;
  final String description;
  final String category;
  final DateTime? date;
  final String childName; // 👈 إضافة متغير اسم الطفل

  ParentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.childName, // 👈 إضافته للمُنشئ
  });

  factory ParentTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final raw = json["transactiondate"] ?? json["date"];
    if (raw is String) {
      try {
        parsedDate = DateTime.parse(raw);
      } catch (_) {
        parsedDate = null;
      }
    }

    return ParentTransaction(
      id: json["transactionid"] ?? 0,
      type: json["transactiontype"] ?? "",
      amount: double.tryParse(json["amount"].toString()) ?? 0.0,
      description: json["merchantname"] ?? json["description"] ?? "", 
      category: json["transactioncategory"] ?? "", 
      date: parsedDate,
      childName: json["childName"] ?? "", // 👈 قراءة الاسم من الاستجابة
    );
  }
}

// ===================== UI CARD =====================

class _TransactionCard extends StatelessWidget {
  final ParentTransaction transaction;
  final Color amountColor;
  final IconData icon;
  final AppLocalizations l10n;

  const _TransactionCard({
    required this.transaction,
    required this.amountColor,
    required this.icon,
    required this.l10n,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    final y = date.year.toString().padLeft(4, "0");
    final m = date.month.toString().padLeft(2, "0");
    final d = date.day.toString().padLeft(2, "0");
    return "$y-$m-$d";
  }

  // ✅ دالة لترجمة التصنيفات الأساسية (بما فيها Spending و Saving)
  String _translateCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains("food") || c.contains("restaurant")) return l10n.catFood;
    if (c.contains("education") || c.contains("school")) return l10n.catEducation;
    if (c.contains("entertainment") || c.contains("fun")) return l10n.catEntertainment;
    if (c.contains("shopping") || c.contains("store")) return l10n.catShopping;
    if (c.contains("gift") || c.contains("reward")) return l10n.catGifts;
    if (c.contains("top-up") || c.contains("wallet")) return l10n.walletTopUp;
    if (c.contains("allowance")) return l10n.parentAllowanceCat;
    if (c.contains("saving")) return l10n.savingLabel; // 👈 ترجمة Saving
    if (c.contains("spending")) return l10n.spendingLabel; // 👈 ترجمة Spending
    return category; 
  }

  // ✅ تمرير اسم الطفل في الدالة
  String _translateDescription(String desc, double amount, String childName) {
    final d = desc.toLowerCase();
    
    if (d.contains("parent allowance") || d.contains("allowance")) {
        final formattedAmount = amount.toStringAsFixed(2);
        
        // 👈 إذا كان الاسم موجوداً استخدمه، وإلا استخدم الكلمة الاحتياطية
        final nameToDisplay = childName.isNotEmpty ? childName : l10n.childFallbackName;
        
        return l10n.transferToChildMessage(formattedAmount, nameToDisplay);
    }
    
    if (d.contains("transfer to child") || d.contains("money transfer")) return l10n.moneyTransfer;
    if (d.contains("deposit")) return l10n.deposit;
    if (d.contains("refund")) return l10n.refund;
    if (d.contains("moyasar")) return l10n.moyasar;
    
    return desc; 
  }

  @override
  Widget build(BuildContext context) {
    const Color kTextDark = Color(0xFF222222);
    final dateText = _formatDate(transaction.date);
    
    // 👈 تحديث الاستدعاء هنا لتمرير transaction.childName
    String desc = _translateDescription(transaction.description.trim(), transaction.amount, transaction.childName);
    if (desc.isEmpty) desc = l10n.defaultTransaction;

    String cat = _translateCategory(transaction.category.trim());
    if (cat.isEmpty) cat = l10n.defaultCategory;
    
    final subtitle = dateText.isEmpty
        ? cat
        : "$cat • $dateText";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade100,
            ),
            child: Icon(icon, size: 22, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/Sar.png',
                width: 14,
                height: 14,
                color: amountColor,
              ),
              const SizedBox(width: 4),
              Text(
                transaction.amount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}