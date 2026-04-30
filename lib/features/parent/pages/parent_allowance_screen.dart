import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

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

  int _selectedChildIndex = 0;
  double _savePercentage = 0;
  final TextEditingController _amountController = TextEditingController(
    text: "100",
  );
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
    final l10n = AppLocalizations.of(context)!;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children',
    );

    debugPrint("GET children => $url");

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${token!}'},
      );

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
          _children = data
              .map(
                (c) => {
                  'childId': c['childId'] ?? c['id'],
                  'name': c['firstName'] ?? c['firstname'] ?? 'Unnamed',
                  'defaultSavingRatio':
                      (c['defaultSavingRatio'] ?? 0).toDouble(),
                },
              )
              .toList();

          _childrenLoading = false;
          _selectedChildIndex = 0;

          if (_children.isNotEmpty) {
            final defaultRatio =
                (_children[0]['defaultSavingRatio'] ?? 0.0) as double;
            _savePercentage = defaultRatio.clamp(0.0, 1.0);
          }
        });

        if (_children.isNotEmpty) {
          await _fetchAllowanceSettings(_children[0]['childId']);
        }
      } else {
        setState(() => _childrenLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToLoadChildren(res.statusCode)),
          ),
        );
      }
    } catch (e) {
      setState(() => _childrenLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorFetchingChildren(e.toString()))));
    }
  }

  Future<void> _fetchAllowanceSettings(int childId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/allowance/$childId');
    debugPrint("GET allowance => $url");

    try {
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token!}',
          'Content-Type': 'application/json',
        },
      );

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
        });
      }
    } catch (_) {
      // عادي إذا ما عنده settings
    }
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    if (_children.isEmpty) return;

    final childId = _children[_selectedChildIndex]['childId'];

    final raw = _amountController.text.trim();
    final cleaned = raw.replaceAll(',', '');
    final parsedAmount = double.tryParse(cleaned);

    if (_isAutoTransferEnabled) {
      if (cleaned.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseEnterWeeklyAmount)),
        );
        return;
      }

      if (parsedAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountMustBeNumber)),
        );
        return;
      }

      if (parsedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountMustBeGreaterThanZero)),
        );
        return;
      }
    }

    final amountToSend = _isAutoTransferEnabled ? parsedAmount! : 0.0;

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
          'savingRatio': _savePercentage, 
        }),
      );

      debugPrint("PUT allowance status => ${res.statusCode}");

      if (res.statusCode == 401) {
        await _forceLogout();
        return;
      }

      if (res.statusCode >= 200 && res.statusCode <= 299) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.allowanceSavedSuccess)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed(res.statusCode))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorSaving(e.toString()))));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(child: Text(l10n.noChildrenFound)),
      );
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double saveAmount = amount * _savePercentage;
    final double spendAmount = amount - saveAmount;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.allowanceSetupTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.allowanceSetupSubtitle,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 85,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedChildIndex;

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              _selectedChildIndex = index;
                              final defaultRatio =
                                  (_children[index]['defaultSavingRatio'] ?? 0.0)
                                      as double;
                              _savePercentage = defaultRatio.clamp(0.0, 1.0);
                            });
                            await _fetchAllowanceSettings(
                              _children[index]['childId'],
                            );
                          },
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 16),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsetsDirectional.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? hassalaGreen1
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.person,
                                      size: 26,
                                      color: isSelected
                                          ? hassalaGreen2
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _children[index]['name'],
                                  style: TextStyle(
                                    fontSize: 13,
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

                  const SizedBox(height: 10),

                  Container(
                    margin: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    padding: const EdgeInsetsDirectional.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.weeklyAmountLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _isAutoTransferEnabled ? const Color(0xFF2C3E50) : const Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: InputDecoration(
                            // إستبدال النص بصورة شعار الريال هنا
                            prefixIcon: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8.0, top: 4.0, bottom: 4.0),
                              child: Image.asset(
                                "assets/icons/Sar.png",
                                width: 22,
                                height: 22,
                                color: Colors.grey,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) {
                            if (mounted) setState(() {});
                          },
                        ),
                        
                        const Divider(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.allocationSplitLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.percentSave((_savePercentage * 100).toInt()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hassalaGreen2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildAllocationBox(
                                context,
                                l10n.spend,
                                spendAmount,
                                Icons.shopping_bag_outlined,
                                const Color(0xFF37C4BE),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildAllocationBox(
                                context,
                                l10n.save,
                                saveAmount,
                                Icons.account_balance_wallet_rounded,
                                const Color(0xFF7E57C2),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: hassalaGreen1,
                            inactiveTrackColor: Colors.grey.shade200,
                            thumbColor: hassalaGreen2,
                            overlayColor: hassalaGreen1.withOpacity(0.2),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: _savePercentage,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: l10n.percentSave((_savePercentage * 100).toInt()),
                            onChanged: (value) {
                              setState(() => _savePercentage = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.allowanceSliderInstruction,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    margin: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      activeColor: hassalaGreen1,
                      title: Text(
                        l10n.autoTransferWeekly,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      subtitle: Text(l10n.everySunday, style: const TextStyle(fontSize: 12)),
                      value: _isAutoTransferEnabled,
                      onChanged: (val) =>
                          setState(() => _isAutoTransferEnabled = val),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hassalaGreen1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          l10n.saveSettings,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationBox(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          // إستبدال النص بصورة شعار الريال هنا أيضاً
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/icons/Sar.png",
                width: 14,
                height: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  amount.toStringAsFixed(0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}