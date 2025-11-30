// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart'; // if you don't use it, you can remove this
// import 'package:my_app/core/api_config.dart';

// class ManageKidsScreen extends StatefulWidget {
//   const ManageKidsScreen({super.key});

//   @override
//   State<ManageKidsScreen> createState() => _ManageKidsScreenState();
// }

// class _ManageKidsScreenState extends State<ManageKidsScreen> {
//   List<Map<String, dynamic>> _children = [];
//   bool _loading = true;
//   late int parentId;

//   final TextEditingController password = TextEditingController();

//   String? token;
//   final String baseUrl = ApiConfig.baseUrl;

//   /// To avoid running `didChangeDependencies` logic twice
//   bool _initialized = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_initialized) return;
//     _initialized = true;

//     // Get parentId from navigation arguments
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     parentId = args?['parentId'] ?? 0;

//     _loadToken().then((_) => fetchChildren());
//   }

//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token");
//   }

//   double parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }

//   /// Fetch children for this parent
//   Future<void> fetchChildren() async {
//     if (token == null) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Missing token — please log in again.")),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     // ✅ NEW ENDPOINT (Option 2)
//     final url = Uri.parse("$baseUrl/api/auth/parent/$parentId/children");

//     try {
//       final response = await http.get(
//         url,
//         headers: {"Authorization": "Bearer $token"},
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         // Backend returns either:
//         // 1) a plain List<child>  OR
//         // 2) { "children": [ ... ] }
//         List<dynamic> list;
//         if (decoded is List) {
//           list = decoded;
//         } else if (decoded is Map && decoded["children"] is List) {
//           list = decoded["children"] as List;
//         } else {
//           list = [];
//         }

//         setState(() {
//           _children = list
//               .map<Map<String, dynamic>>(
//                 (c) => {
//                   "childId": c["childId"] ?? c["id"],
//                   "firstName": c["firstName"] ?? c["firstname"] ?? "Unnamed",
//                   "phoneNo": c["phoneNo"] ?? c["phoneno"],
//                   "limitAmount": parseDouble(c["limitAmount"]),
//                   "balance": parseDouble(c["balance"]),
//                 },
//               )
//               .toList();
//           _loading = false;
//         });
//       } else if (response.statusCode == 401) {
//         // Token expired / invalid → clear & send user back to start
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.clear();
//         if (!mounted) return;
//         Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
//       } else {
//         throw Exception(
//           "Failed to load children (code ${response.statusCode})",
//         );
//       }
//     } catch (e) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error fetching children: $e")));
//     }
//   }

//   // =====================================================
//   // POPUP TO UPDATE SPENDING LIMIT
//   // =====================================================
//   void _openEditLimitDialog(Map<String, dynamic> kid) {
//     final limitController = TextEditingController(
//       text: kid["limitAmount"].toString(),
//     );

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           title: Text("Update Limit for ${kid['firstName']}"),
//           content: TextFormField(
//             controller: limitController,
//             keyboardType: TextInputType.number,
//             decoration: const InputDecoration(
//               labelText: "New Spending Limit (SAR)",
//               border: OutlineInputBorder(),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final raw = limitController.text.trim();
//                 final value = double.tryParse(raw);

//                 if (value == null || value <= 0) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Enter a valid amount")),
//                   );
//                   return;
//                 }

//                 await _updateChildLimit(kid["childId"], value);

//                 if (context.mounted) Navigator.pop(context);
//               },
//               child: const Text("Save"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // =====================================================
//   // CALL BACKEND TO UPDATE LIMIT
//   // (kept same endpoint you already use)
//   // =====================================================
//   Future<void> _updateChildLimit(int childId, double newLimit) async {
//     final url = Uri.parse("$baseUrl/api/auth/child/update-limit/$childId");

//     try {
//       final response = await http.put(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({"limitAmount": newLimit}),
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Spending limit updated"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         await fetchChildren(); // refresh UI
//       } else {
//         final err = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(err["error"] ?? "Failed to update limit"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   // =====================================================
//   // ADD CHILD DIALOG + REGISTRATION
//   // =====================================================
//   void _openAddChildDialog() {
//     final formKey = GlobalKey<FormState>();
//     final firstName = TextEditingController();
//     final nationalId = TextEditingController();
//     final phoneNo = TextEditingController();
//     final dob = TextEditingController();
//     final limitAmount = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           backgroundColor: Colors.white,
//           title: const Text(
//             "Add Child",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.w700,
//               fontSize: 20,
//               color: Color(0xFF2C3E50),
//             ),
//           ),
//           content: SingleChildScrollView(
//             child: Form(
//               key: formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildValidatedField(
//                     controller: firstName,
//                     label: "First Name",
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Enter first name';
//                       if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v)) {
//                         return 'Letters only';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _buildValidatedField(
//                     controller: nationalId,
//                     label: "National ID",
//                     keyboardType: TextInputType.number,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Enter National ID';
//                       if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
//                         return 'Must be 10 digits';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _buildValidatedField(
//                     controller: phoneNo,
//                     label: "Phone Number",
//                     keyboardType: TextInputType.phone,
//                     validator: (v) {
//                       final value = v?.trim() ?? '';
//                       if (value.isEmpty) return 'Enter phone number';
//                       if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
//                         return 'Phone must start with 05 and be 10 digits (e.g., 05XXXXXXXX)';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   TextFormField(
//                     controller: dob,
//                     readOnly: true,
//                     decoration: InputDecoration(
//                       labelText: "Date of Birth",
//                       filled: true,
//                       fillColor: const Color(0xFFFDFDFD),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     validator: (v) =>
//                         v == null || v.isEmpty ? 'Select date of birth' : null,
//                     onTap: () async {
//                       FocusScope.of(context).unfocus();
//                       final pickedDate = await showDatePicker(
//                         context: context,
//                         initialDate: DateTime(2010),
//                         firstDate: DateTime(2007),
//                         lastDate: DateTime.now(),
//                       );
//                       if (pickedDate != null) {
//                         dob.text = pickedDate
//                             .toIso8601String()
//                             .split("T")
//                             .first;
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _buildValidatedField(
//                     controller: password,
//                     label: "Password",
//                     obscureText: true,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Enter password';
//                       if (v.length < 8) {
//                         return 'Must be at least 8 characters';
//                       }
//                       if (!RegExp(
//                         r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
//                       ).hasMatch(v)) {
//                         return 'Use upper, lower, number & special character';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   TextFormField(
//                     controller: limitAmount,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: "Spending Limit (SAR)",
//                       filled: true,
//                       fillColor: const Color(0xFFFDFDFD),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) {
//                         return 'Enter a spending limit';
//                       }
//                       final value = double.tryParse(v);
//                       if (value == null || value <= 0) {
//                         return 'Enter a valid amount';
//                       }
//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           actionsPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 10,
//           ),
//           actionsAlignment: MainAxisAlignment.spaceBetween,
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF37C4BE),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//               ),
//               onPressed: () async {
//                 if (!formKey.currentState!.validate()) return;

//                 final enteredPhone = phoneNo.text.trim();

//                 final exists = await phoneExists(enteredPhone);
//                 if (exists) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         "This phone number is already linked to an existing user.",
//                       ),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                   return;
//                 }

//                 final success = await registerChild(
//                   firstName.text.trim(),
//                   nationalId.text.trim(),
//                   enteredPhone,
//                   dob.text.trim(),
//                   password.text.trim(),
//                   limitAmount.text.trim(),
//                 );

//                 if (success && context.mounted) {
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text("Add"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<bool> phoneExists(String phone) async {
//     final url = Uri.parse("$baseUrl/api/auth/check-user");

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           if (token != null) "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({"phoneNo": phone}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data["exists"] == true;
//       }
//     } catch (e) {
//       debugPrint("Phone check failed: $e");
//     }

//     return false;
//   }

//   Future<bool> registerChild(
//     String firstName,
//     String nationalId,
//     String phoneNo,
//     String dob,
//     String password,
//     String limitAmount,
//   ) async {
//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Missing token — please log in again.")),
//       );
//       return false;
//     }

//     final url = Uri.parse("$baseUrl/api/auth/child/register");

//     final body = {
//       "parentId": parentId,
//       "firstName": firstName,
//       "nationalId": int.tryParse(nationalId),
//       "phoneNo": phoneNo,
//       "dob": dob,
//       "password": password,
//       "limitAmount": double.tryParse(limitAmount),
//     };

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200) {
//         if (!mounted) return true;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Child added successfully!"),
//             backgroundColor: Colors.green,
//           ),
//         );

//         await fetchChildren();
//         return true;
//       } else {
//         final data = jsonDecode(response.body);
//         final message = data['error'] ?? 'Failed to add child';

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(message), backgroundColor: Colors.red),
//           );
//         }
//         return false;
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error: $e')));
//       }
//       return false;
//     }
//   }

//   // ===============================================
//   // SMALL HELPER FOR TEXT FIELDS
//   // ===============================================
//   Widget _buildValidatedField({
//     required TextEditingController controller,
//     required String label,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         filled: true,
//         fillColor: const Color(0xFFFDFDFD),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//       validator: validator,
//     );
//   }

//   // =====================================================
//   // UI BUILD
//   // =====================================================
//   @override
//   Widget build(BuildContext context) {
//     const hassalaGreen1 = Color(0xFF37C4BE);

//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: _openAddChildDialog,
//         backgroundColor: hassalaGreen1,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 const Text(
//                   "Manage Children",
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: _loading
//                   ? const Center(child: CircularProgressIndicator())
//                   : _children.isEmpty
//                   ? const Center(child: Text("No children added yet"))
//                   : ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: _children.length,
//                       itemBuilder: (context, index) {
//                         final kid = _children[index];

//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(18),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black12.withOpacity(0.08),
//                                 blurRadius: 8,
//                               ),
//                             ],
//                           ),
//                           child: ListTile(
//                             onTap: () => _openEditLimitDialog(kid),
//                             leading: CircleAvatar(
//                               backgroundColor: hassalaGreen1.withOpacity(.2),
//                               child: const Icon(
//                                 Icons.person,
//                                 color: hassalaGreen1,
//                               ),
//                             ),
//                             title: Text(kid["firstName"]),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text("Phone: ${kid["phoneNo"]}"),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   children: [
//                                     Image.asset(
//                                       "assets/icons/riyal.png",
//                                       height: 14,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       "Limit: ${kid["limitAmount"].toStringAsFixed(2)}",
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             trailing: const Icon(Icons.arrow_forward_ios),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

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
    if (token == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token — please log in again.")),
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
                  "firstName": c["firstName"] ?? c["firstname"] ?? "Unnamed",
                  "phoneNo": c["phoneNo"] ?? c["phoneno"],
                  "limitAmount": parseDouble(c["limitAmount"]),
                  "balance": parseDouble(c["balance"]),
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
          "Failed to load children (code ${response.statusCode})",
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching children: $e")));
    }
  }

  // --- Styled Edit Limit Dialog ---
  void _openEditLimitDialog(Map<String, dynamic> kid) {
    final limitController = TextEditingController(
      text: kid["limitAmount"].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Update Spending Limit",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Set a new limit for ${kid['firstName']}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: limitController,
                  label: "New Spending Limit (SAR)",
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
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
                              const SnackBar(
                                content: Text("Enter a valid amount"),
                              ),
                            );
                            return;
                          }

                          await _updateChildLimit(kid["childId"], value);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hassalaGreen1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Save",
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

  Future<void> _updateChildLimit(int childId, double newLimit) async {
    final url = Uri.parse("$baseUrl/api/auth/child/update-limit/$childId");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"limitAmount": newLimit}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Spending limit updated"),
            backgroundColor: hassalaGreen2,
          ),
        );
        await fetchChildren();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err["error"] ?? "Failed to update limit"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Add New Child",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildModernTextField(
                      controller: firstName,
                      label: "First Name",
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter first name';
                        if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v))
                          return 'Letters only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: nationalId,
                      label: "National ID",
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter National ID';
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                          return 'Must be 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: phoneNo,
                      label: "Phone Number",
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter phone number';
                        if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
                          return 'Must be 10 digits (e.g., 05XXXXXXXX)';
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
                        labelText: "Date of Birth",
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Select date of birth'
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
                      controller: password,
                      label: "Password",
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 8) return 'Min 8 chars';
                        if (!RegExp(
                          r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
                        ).hasMatch(v)) {
                          return 'Use upper, lower, number & special char';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: limitAmount,
                      label: "Spending Limit (SAR)",
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter limit';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
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
                                  const SnackBar(
                                    content: Text(
                                      "Phone already linked to user.",
                                    ),
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
                              );

                              if (success && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              "Add Child",
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
  ) async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token — please log in again.")),
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
          const SnackBar(
            content: Text("Child added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        await fetchChildren();
        return true;
      } else {
        final data = jsonDecode(response.body);
        final message = data['error'] ?? 'Failed to add child';
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
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    }
  }

  // --- Helper: Modern Text Field ---
  Widget _buildModernTextField({
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hassalaGreen1, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
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
                    const Text(
                      "Manage Children",
                      style: TextStyle(
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
                          children: const [
                            Icon(
                              Icons.family_restroom_outlined,
                              size: 80,
                              color: Colors.black12,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No children added yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _children.length,
                        itemBuilder: (context, index) {
                          final kid = _children[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                padding: const EdgeInsets.all(10),
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
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Phone: ${kid["phoneNo"]}",
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
                                          "Limit: ${kid["limitAmount"].toStringAsFixed(0)} SAR",
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
