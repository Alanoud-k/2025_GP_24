import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ManageKidsScreen extends StatefulWidget {
  const ManageKidsScreen({super.key});

  @override
  State<ManageKidsScreen> createState() => _ManageKidsScreenState();
}

class _ManageKidsScreenState extends State<ManageKidsScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;
  late int parentId;

  final TextEditingController password = TextEditingController();

  String? token;
  final String baseUrl = ApiConfig.baseUrl;

  bool _initialized = false;

  // --- Constants for Styles ---
  static const Color hassalaGreen1 = Color(0xFF37C4BE);
  static const Color hassalaGreen2 = Color(0xFF2EA49E);
  static const Color bgColor = Color(0xFFF7FAFC);
  static const Color textDark = Color(0xFF2C3E50);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    parentId = args?['parentId'] ?? 0;

    _loadToken().then((_) => fetchChildren());
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> fetchChildren() async {
    final l10n = AppLocalizations.of(context)!;
    if (token == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.missingToken)),
      );
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse("$baseUrl/api/auth/parent/$parentId/children");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded["children"] is List) {
          list = decoded["children"] as List;
        } else {
          list = [];
        }

        setState(() {
          _children = list
              .map<Map<String, dynamic>>(
                (c) => {
                  "childId": c["childId"] ?? c["id"],
                  "firstName": c["firstName"] ?? c["firstname"] ?? l10n.childFallbackName,
                  "phoneNo": c["phoneNo"] ?? c["phoneno"],
                  "limitAmount": parseDouble(c["limitAmount"]),
                  "balance": parseDouble(c["balance"]),
                  "defaultSavingRatio": parseDouble(c["defaultSavingRatio"]),
                },
              )
              .toList();
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
      } else {
        throw Exception(
          l10n.failedToLoadChildren(response.statusCode),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorFetchingChildren(e.toString()))));
    }
  }

  // --- Styled Edit Limit Dialog ---
  void _openEditLimitDialog(Map<String, dynamic> kid) {
    final limitController = TextEditingController(
      text: kid["limitAmount"].toString(),
    );
    final l10n = AppLocalizations.of(context)!;
    double savingRatio = kid["defaultSavingRatio"] ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.circular(20).resolve(Directionality.of(context)),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.updateSpendingLimit,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.setNewLimitFor(kid['firstName']),
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  context: context,
                  controller: limitController,
                  label: l10n.newSpendingLimitSar,
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.defaultSavingSplit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      children: [
                        Slider(
                          value: savingRatio,
                          min: 0,
                          max: 1,
                          divisions: 20,
                          activeColor: hassalaGreen1,
                          label: "${(savingRatio * 100).round()}%",
                          onChanged: (value) {
                            setStateDialog(() {
                              savingRatio = value;
                            });
                          },
                        ),
                        Text(
                          l10n.savingSpendingSplit(
                            (savingRatio * 100).round(),
                            ((1 - savingRatio) * 100).round(),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final raw = limitController.text.trim();
                          final value = double.tryParse(raw);

                          if (value == null || value <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.enterValidAmount),
                              ),
                            );
                            return;
                          }

                          await _updateChildSettings(
                            kid["childId"],
                            value,
                            savingRatio,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hassalaGreen1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.saveBtn,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
  }

  Future<void> _updateChildSettings(
    int childId,
    double newLimit,
    double savingRatio,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final url = Uri.parse("$baseUrl/api/auth/child/update-limit/$childId");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "limitAmount": newLimit,
          "defaultSavingRatio": savingRatio,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.childSettingsUpdated),
            backgroundColor: hassalaGreen2,
          ),
        );
        await fetchChildren();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err["error"] ?? l10n.failedToUpdateChildSettings),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${l10n.errorPrefix}: $e")));
    }
  }

  // --- Styled Add Child Dialog ---
  void _openAddChildDialog() {
    final formKey = GlobalKey<FormState>();
    final firstName = TextEditingController();
    final nationalId = TextEditingController();
    final phoneNo = TextEditingController();
    final dob = TextEditingController();
    final limitAmount = TextEditingController();
    double savingRatio = 0.0;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.circular(20).resolve(Directionality.of(context)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24.0),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.addNewChild,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                _buildModernTextField(
                      context: context,
                      controller: firstName,
                      label: l10n.firstNameLabel,
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterFirstName;
                        // السماح بالحروف العربية والإنجليزية والمسافات
                        if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v.trim())) {
                          return l10n.lettersOnly;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      context: context,
                      controller: nationalId,
                      label: l10n.nationalIdLabel,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterNationalId;
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                          return l10n.mustBe10Digits;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      context: context,
                      controller: phoneNo,
                      label: l10n.phoneNumber,
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.enterPhoneNumber;
                        if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
                          return l10n.phoneHelp;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Date Picker Field
                    TextFormField(
                      controller: dob,
                      readOnly: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: l10n.dateOfBirthLabel,
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadiusDirectional.circular(12).resolve(Directionality.of(context)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? l10n.selectDateOfBirth
                          : null,
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2010),
                          firstDate: DateTime(2007),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: hassalaGreen1,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          dob.text = pickedDate
                              .toIso8601String()
                              .split("T")
                              .first;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      context: context,
                      controller: password,
                      label: l10n.password,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterPasswordVal;
                        if (v.length < 8) return l10n.passwordMinLength;
                        if (!RegExp(
                          r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
                        ).hasMatch(v)) {
                          return l10n.passwordRequirements;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      context: context,
                      controller: limitAmount,
                      label: l10n.spendingLimitSar,
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterLimit;
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return l10n.invalidAmount;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.defaultSavingSplit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return Column(
                          children: [
                            Slider(
                              value: savingRatio,
                              min: 0,
                              max: 1,
                              divisions: 20,
                              activeColor: hassalaGreen1,
                              label: "${(savingRatio * 100).round()}%",
                              onChanged: (value) {
                                setStateDialog(() {
                                  savingRatio = value;
                                });
                              },
                            ),
                            Text(
                              l10n.savingSpendingSplit(
                                (savingRatio * 100).round(),
                                ((1 - savingRatio) * 100).round(),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hassalaGreen1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final enteredPhone = phoneNo.text.trim();
                              final exists = await phoneExists(enteredPhone);
                              if (exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.phoneAlreadyLinked),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final success = await registerChild(
                                firstName.text.trim(),
                                nationalId.text.trim(),
                                enteredPhone,
                                dob.text.trim(),
                                password.text.trim(),
                                limitAmount.text.trim(),
                                savingRatio,
                              );

                              if (success && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              l10n.addNewChild,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> phoneExists(String phone) async {
    final url = Uri.parse("$baseUrl/api/auth/check-user");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({"phoneNo": phone}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["exists"] == true;
      }
    } catch (e) {
      debugPrint("Phone check failed: $e");
    }
    return false;
  }

  Future<bool> registerChild(
    String firstName,
    String nationalId,
    String phoneNo,
    String dob,
    String password,
    String limitAmount,
    double savingRatio,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.missingToken)),
      );
      return false;
    }

    final url = Uri.parse("$baseUrl/api/auth/child/register");
    final body = {
      "parentId": parentId,
      "firstName": firstName,
      "nationalId": int.tryParse(nationalId),
      "phoneNo": phoneNo,
      "dob": dob,
      "password": password,
      "limitAmount": double.tryParse(limitAmount),
      "defaultSavingRatio": savingRatio,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (!mounted) return true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.childAddedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        await fetchChildren();
        return true;
      } else {
        final data = jsonDecode(response.body);
        final message = data['error'] ?? l10n.failedToAddChild;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${l10n.errorPrefix}: $e")));
      }
      return false;
    }
  }

  // --- Helper: Modern Text Field ---
  Widget _buildModernTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadiusDirectional.circular(12).resolve(Directionality.of(context)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadiusDirectional.circular(12).resolve(Directionality.of(context)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadiusDirectional.circular(12).resolve(Directionality.of(context)),
          borderSide: const BorderSide(color: hassalaGreen1, width: 1.5),
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddChildDialog,
        backgroundColor: hassalaGreen1,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.manageChildren,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Content List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: hassalaGreen1),
                      )
                    : _children.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.family_restroom_outlined,
                              size: 80,
                              color: Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noChildrenAdded,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _children.length,
                        itemBuilder: (context, index) {
                          final kid = _children[index];
                          return Container(
                            margin: const EdgeInsetsDirectional.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () => _openEditLimitDialog(kid),
                              leading: Container(
                                padding: const EdgeInsetsDirectional.all(10),
                                decoration: BoxDecoration(
                                  color: hassalaGreen2.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: hassalaGreen2,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                kid["firstName"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsetsDirectional.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.phoneDisplay(kid["phoneNo"]),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 14,
                                          color: hassalaGreen1,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.limitDisplay(kid["limitAmount"].toStringAsFixed(0)),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: hassalaGreen1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.edit_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
