// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart'; // ✅ ADD THIS

// class ParentAllowanceScreen extends StatefulWidget {
//   final int parentId;
//   final String token;

//   const ParentAllowanceScreen({
//     super.key,
//     required this.parentId,
//     required this.token,
//   });

//   @override
//   State<ParentAllowanceScreen> createState() => _ParentAllowanceScreenState();
// }

// class _ParentAllowanceScreenState extends State<ParentAllowanceScreen> {
//   bool _loading = true;
//   String? token;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAuth();
//   }

//   Future<void> _initializeAuth() async {
//     await checkAuthStatus(context);

//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;

//     if (token == null || token!.isEmpty) {
//       _forceLogout();
//       return;
//     }

//     if (mounted) setState(() => _loading = false);
//   }

//   void _forceLogout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();

//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
//     }
//   }

//   Future<void> _handleAuth() async {
//     await checkAuthStatus(context); // ✅ redirects if token expired
//     if (mounted) {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         backgroundColor: Color(0xFFF7F8FA),
//         body: Center(child: CircularProgressIndicator(color: Colors.teal)),
//       );
//     }

//     return const Scaffold(
//       backgroundColor: Color(0xFFF7F8FA),
//       body: SafeArea(
//         child: Center(
//           child: Text(
//             "Allowance page is empty for now.",
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.black54,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:my_app/core/api_config.dart'; // ✅ NEW

class ParentAllowanceScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentAllowanceScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentAllowanceScreen> createState() => _ParentAllowanceScreenState();
}

class _ParentAllowanceScreenState extends State<ParentAllowanceScreen> {
  bool _loading = true;
  String? token;

  // --- State Variables for UI ---
  int _selectedChildIndex = 0;
  double _savePercentage = 0.20; // Default 20% Savings
  final TextEditingController _amountController =
      TextEditingController(text: "100");
  bool _isAutoTransferEnabled = true;

  List<Map<String, dynamic>> _children = [];
  bool _childrenLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await checkAuthStatus(context);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    debugPrint("ALLOWANCE ApiConfig.baseUrl = ${ApiConfig.baseUrl}");

    if (token == null || token!.isEmpty) {
      await _forceLogout();
      return;
    }

    if (mounted) setState(() => _loading = false);
    await _fetchChildren();
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
  }

  Future<void> _fetchChildren() async {
    final url = Uri.parse(
  '${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children',
);


    debugPrint("GET children => $url");

    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer ${token!}',
      });

      debugPrint("GET children status => ${res.statusCode}");

      if (res.statusCode == 401) {
        await _forceLogout();
        return;
      }

      if (res.statusCode == 200) {
final decoded = jsonDecode(res.body);
final List data = (decoded is List)
    ? decoded
    : (decoded is Map && decoded["children"] is List)
        ? decoded["children"]
        : [];

        setState(() {
        _children = data.map((c) => {
  'childId': c['childId'] ?? c['id'],
  'name': c['firstName'] ?? c['firstname'] ?? 'Unnamed',
}).toList();


          _childrenLoading = false;
          _selectedChildIndex = 0;
        });

        if (_children.isNotEmpty) {
          await _fetchAllowanceSettings(_children[0]['childId']);
        }
      } else {
  setState(() => _childrenLoading = false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to load children (${res.statusCode})')),
  );
}

    } catch (e) {
      setState(() => _childrenLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading children: $e')),
      );
    }
  }

  Future<void> _fetchAllowanceSettings(int childId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/allowance/$childId');
    debugPrint("GET allowance => $url");

    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer ${token!}',
        'Content-Type': 'application/json',
      });

      debugPrint("GET allowance status => ${res.statusCode}");

      if (res.statusCode == 401) {
        await _forceLogout();
        return;
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _isAutoTransferEnabled = data['isEnabled'] ?? false;
          _amountController.text = (data['amount'] ?? 100).toString();

          final sp = (data['savePercentage'] ?? 20).toDouble();
          _savePercentage = (sp / 100.0).clamp(0.0, 1.0);
        });
      }
    } catch (_) {
      // عادي إذا ما عنده settings
    }
  }

  Future<void> _saveSettings() async {
    if (_children.isEmpty) return;

    final childId = _children[_selectedChildIndex]['childId'];

    final raw = _amountController.text.trim();
    final cleaned = raw.replaceAll(',', '');
    final parsedAmount = double.tryParse(cleaned);

    // Validation
    if (_isAutoTransferEnabled) {
      if (cleaned.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter weekly amount')),
        );
        return;
      }

      if (parsedAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be a number')),
        );
        return;
      }

      if (parsedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than 0')),
        );
        return;
      }
    }

    final amountToSend = _isAutoTransferEnabled ? parsedAmount! : 0.0;
    final savePctInt = (_savePercentage * 100).round().clamp(0, 100);

    final url = Uri.parse('${ApiConfig.baseUrl}/api/allowance/$childId');
    debugPrint("PUT allowance => $url");

    try {
      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer ${token!}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'isEnabled': _isAutoTransferEnabled,
          'amount': amountToSend,
          'savePercentage': savePctInt,
        }),
      );

      debugPrint("PUT allowance status => ${res.statusCode}");

      if (res.statusCode == 401) {
        await _forceLogout();
        return;
      }

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allowance Saved ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed (${res.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const hassalaGreen1 = Color(0xFF37C4BE);
    const hassalaGreen2 = Color(0xFF2EA49E);

    if (_loading || _childrenLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF37C4BE)),
        ),
      );
    }

    if (_children.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: Text("No children found")),
      );
    }

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double saveAmount = amount * _savePercentage;
    double spendAmount = amount - saveAmount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Allowance Setup",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Teach them to save by splitting their weekly allowance.",
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _children.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedChildIndex;

                      return GestureDetector(
                        onTap: () async {
                          setState(() => _selectedChildIndex = index);
                          await _fetchAllowanceSettings(
                            _children[index]['childId'],
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? hassalaGreen1
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: isSelected
                                        ? hassalaGreen2
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _children[index]['name'],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF2C3E50)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Weekly Amount",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountController,
                        enabled: _isAutoTransferEnabled, // ✅ NEW
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        decoration: const InputDecoration(
                          prefixText: "SAR  ",
                          prefixStyle:
                              TextStyle(fontSize: 20, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const Divider(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Allocation Split",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            "${(_savePercentage * 100).toInt()}% Save",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hassalaGreen2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAllocationBox(
                            "Spend",
                            spendAmount,
                            Icons.shopping_bag_outlined,
                            const Color(0xFF37C4BE),
                          ),
                          _buildAllocationBox(
                            "Save",
                            saveAmount,
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF7E57C2),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: hassalaGreen1,
                          inactiveTrackColor: Colors.grey.shade200,
                          thumbColor: hassalaGreen2,
                          overlayColor: hassalaGreen1.withOpacity(0.2),
                          trackHeight: 6.0,
                        ),
                        child: Slider(
                          value: _savePercentage,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: "${(_savePercentage * 100).toInt()}% Save",
                          onChanged: (value) {
                            setState(() => _savePercentage = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Adjust the slider to teach your child how much to save from their allowance automatically.",
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SwitchListTile(
                    activeColor: hassalaGreen1,
                    title: const Text(
                      "Auto-transfer Weekly",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    subtitle: const Text("Every Sunday"),
                    value: _isAutoTransferEnabled,
                    onChanged: (val) =>
                        setState(() => _isAutoTransferEnabled = val),
                  ),
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hassalaGreen1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Save Settings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationBox(
      String label, double amount, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.38,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${amount.toStringAsFixed(0)} SAR",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
