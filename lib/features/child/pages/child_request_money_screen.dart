//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/utils/check_auth.dart';

class ChildRequestMoneyScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildRequestMoneyScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildRequestMoneyScreen> createState() =>
      _ChildRequestMoneyScreenState();
}

class _ChildRequestMoneyScreenState extends State<ChildRequestMoneyScreen>
    with SingleTickerProviderStateMixin {
  // --- Controllers ---
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  // --- State Variables ---
  bool _submitting = false;
  bool _loadingHistory = true;
  List<dynamic> _requests = [];

  // --- Tabs ---
  late TabController _tabController;

  // --- Colors (Hassala Style) ---
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch history when switching to tab 1
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchHistory();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
      _fetchHistory(); // Load history initially
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // =============================================
  // LOGIC 1: SUBMIT REQUEST (Your Logic)
  // =============================================
  Future<void> _submitRequest() async {
    final amountText = _amountController.text.trim();
    final message = _messageController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }
    if (message.isEmpty) {
      _showSnack('Please enter a message');
      return;
    }

    setState(() => _submitting = true);

    try {
      final url = Uri.parse('${widget.baseUrl}/api/request-money');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          "childId": widget.childId,
          "amount": amount,
          "message": message,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 401) {
        await checkAuthStatus(context);
        return;
      }

      if (response.statusCode == 200) {
        // Success
        await _showSuccessDialog(amount, message);

        // Clear fields
        _amountController.clear();
        _messageController.clear();
        FocusScope.of(context).unfocus();

        // Refresh History & Switch Tab
        if (mounted) {
          await _fetchHistory();
          _tabController.animateTo(1); // Go to History Tab
        }
      } else {
        final serverMsg = _tryReadServerMessage(response.body);
        _showSnack(serverMsg ?? 'Request failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // =============================================
  // LOGIC 2: FETCH HISTORY (New for Tab 2)
  // =============================================
  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final url = Uri.parse(
        '${widget.baseUrl}/api/money-requests/${widget.childId}',
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _requests = jsonDecode(response.body);
            _loadingHistory = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingHistory = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  // --- Helpers (Your Helpers) ---
  String? _tryReadServerMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
      return body.isNotEmpty ? body : null;
    } catch (_) {
      return body.isNotEmpty ? body : null;
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: hassalaGreen1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showSuccessDialog(double amount, String message) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Request Sent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  const Text(
                    'Your request for',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  SarAmount(
                    amount: amount,
                    decimals: 2,
                    iconSize: 18,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'was sent successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, color: Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // =============================================
  // UI BUILD (Tabbed Layout)
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: const Text(
          "Money Requests",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // --- Tab Bar ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [hassalaGreen1, hassalaGreen2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "New Request"),
                Tab(text: "History"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Views ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTab(), // Your Form UI
                _buildHistoryTab(), // New History List
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- View 1: Form (User's Original UI adapted) ---
  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12.withOpacity(0.05),
                ),
              ],
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                DecimalTextInputFormatter(decimalRange: 2),
              ],
              decoration: InputDecoration(
                hintText: "e.g. 50.00",
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/icons/Sar.png',
                    width: 18,
                    height: 18,
                    color: hassalaGreen1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12.withOpacity(0.05),
                ),
              ],
            ),
            child: TextField(
              controller: _messageController,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-Z\u0600-\u06FF\s]"),
                ),
              ],
              decoration: const InputDecoration(
                hintText: "Add a message",
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.chat_bubble_outline,
                  color: hassalaGreen1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: hassalaGreen1,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Request", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  // --- View 2: History List ---
  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: hassalaGreen1),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, size: 80, color: Colors.black12),
            SizedBox(height: 16),
            Text(
              "No requests yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        final statusColor = _getStatusColor(req['requestStatus']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 5),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SarAmount(
                    amount: double.tryParse(req['amount'].toString()) ?? 0.0,
                    decimals: 2,
                    iconSize: 16,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),

                  if (req['requestDescription'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        req['requestDescription'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  req['requestStatus'],
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Allows digits and one dot with fixed decimals.
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  const DecimalTextInputFormatter({required this.decimalRange});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2) return oldValue;
      if (parts[1].length > decimalRange) return oldValue;
    }
    return newValue;
  }
}

class SarAmount extends StatelessWidget {
  final double amount;
  final TextStyle style;
  final double iconSize;
  final Color? iconColor;
  final int decimals;

  const SarAmount({
    super.key,
    required this.amount,
    required this.style,
    this.iconSize = 16,
    this.iconColor,
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/Sar.png',
          width: iconSize,
          height: iconSize,
          color: iconColor ?? style.color,
        ),
        const SizedBox(width: 4),
        Text(amount.toStringAsFixed(decimals), style: style),
      ],
    );
  }
}
