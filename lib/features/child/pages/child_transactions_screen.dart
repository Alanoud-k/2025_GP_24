import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChildTransactionsScreen extends StatefulWidget {
  final int childId;
  final String token;
  final String baseUrl; // Backend URL

  const ChildTransactionsScreen({
    super.key,
    required this.childId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<ChildTransactionsScreen> createState() =>
      _ChildTransactionsScreenState();
}

class _ChildTransactionsScreenState extends State<ChildTransactionsScreen> {
  static const Color kPrimary = Color(0xFF37C4BE);
  static const Color kBg = Color(0xFFF7F8FA);
  static const Color kTextDark = Color(0xFF222222);

  bool _isLoading = false;
  String? _errorMessage;
  List<ChildTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Adjust endpoint path if your backend is different
      final url = Uri.parse(
        "${widget.baseUrl}/api/child/${widget.childId}/transactions",
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
        final decoded = jsonDecode(res.body);

        final List<dynamic> list = decoded["data"] ?? [];
        final items = list
            .map((e) => ChildTransaction.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _transactions = items;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load transactions (${res.statusCode})";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Something went wrong: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _amountColor(String type) {
    switch (type.toLowerCase()) {
      case "spend":
        return const Color(0xFFE57373); // soft red
      case "deposit":
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
    return Icons.payment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextDark),
        title: const Text(
          "Transactions",
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _fetchTransactions,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
      return const Center(
        child: Text(
          "No transactions yet.",
          style: TextStyle(color: Colors.black45, fontSize: 14),
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
        );
      },
    );
  }
}

class ChildTransaction {
  final int id;
  final String type;
  final double amount;
  final String merchantName;
  final String category;
  final DateTime? date;

  ChildTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.merchantName,
    required this.category,
    required this.date,
  });

  factory ChildTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json["transactiondate"] ?? json["date"];
    if (rawDate is String) {
      try {
        parsedDate = DateTime.parse(rawDate);
      } catch (_) {
        parsedDate = null;
      }
    }

    return ChildTransaction(
      id: json["transactionid"] ?? json["id"] ?? 0,
      type: json["transactiontype"] ?? "Spend",
      amount: (json["amount"] is num)
          ? (json["amount"] as num).toDouble()
          : double.tryParse(json["amount"]?.toString() ?? "0") ?? 0.0,
      merchantName: json["merchantname"] ?? "Unknown",
      category: json["transactioncategory"] ?? "Uncategorized",
      date: parsedDate,
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ChildTransaction transaction;
  final Color amountColor;
  final IconData icon;

  const _TransactionCard({
    required this.transaction,
    required this.amountColor,
    required this.icon,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    // Simple format: yyyy-mm-dd
    final y = date.year.toString().padLeft(4, "0");
    final m = date.month.toString().padLeft(2, "0");
    final d = date.day.toString().padLeft(2, "0");
    return "$y-$m-$d";
  }

  @override
  Widget build(BuildContext context) {
    const Color kTextDark = Color(0xFF222222);

    final String dateText = _formatDate(transaction.date);
    final String subtitle = dateText.isEmpty
        ? transaction.category
        : "${transaction.category} • $dateText";

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
          // leading icon container
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
          // title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName,
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // amount
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/Sar.png',
                width: 14,
                height: 14,
                color:
                    amountColor, // remove if your PNG already has the right color
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
