// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';

// class ManageKidsScreen extends StatefulWidget {
//   const ManageKidsScreen({super.key});

//   @override
//   State<ManageKidsScreen> createState() => _ManageKidsScreenState();
// }

// class _ManageKidsScreenState extends State<ManageKidsScreen> {
//   List children = [];
//   bool _loading = true;
//   late int parentId;

//   final TextEditingController password = TextEditingController();

//   String? token;
//   static const String baseUrl = "http://10.0.2.2:3000";

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     checkAuthStatus(context);

//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     parentId = args?['parentId'] ?? 0;

//     print('📱 ManageKidsScreen received parentId: $parentId');

//     _loadToken().then((_) => fetchChildren());
//   }

//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token");
//   }

//   Future<void> fetchChildren() async {
//     if (token == null) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Missing token — please log in again.")),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     final url = Uri.parse("$baseUrl/api/auth/parent/$parentId/children");

//     try {
//       final response = await http.get(
//         url,
//         headers: {"Authorization": "Bearer $token"},
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         setState(() {
//           children = decoded is List ? decoded : [];
//           _loading = false;
//         });
//       } else {
//         throw Exception(
//           "Failed to load children (code ${response.statusCode})",
//         );
//       }
//       if (response.statusCode == 401) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.clear(); // clear token, ids, role
//         if (context.mounted) {
//           Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//         }
//         return;
//       }
//     } catch (e) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error fetching children: $e")));
//     }
//   }

//   void _openAddChildDialog() {
//     final _formKey = GlobalKey<FormState>();
//     final firstName = TextEditingController();
//     final nationalId = TextEditingController();
//     final phoneNo = TextEditingController();
//     final dob = TextEditingController();
//     final limitAmount = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Add Child"),
//           content: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
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
//                   const SizedBox(height: 10),

//                   _buildValidatedField(
//                     controller: nationalId,
//                     label: "National ID",
//                     keyboardType: TextInputType.number,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Enter National ID';
//                       if (v.length != 10) return 'Must be 10 digits';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 10),

//                   _buildValidatedField(
//                     controller: phoneNo,
//                     label: "Phone Number",
//                     keyboardType: TextInputType.phone,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Enter phone number';
//                       if (!RegExp(r'^05\d{8}$').hasMatch(v)) {
//                         return 'Invalid format (must start with 05)';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 10),

//                   // 🎯 Date Picker
//                   TextFormField(
//                     controller: dob,
//                     readOnly: true,
//                     decoration: const InputDecoration(
//                       labelText: "Date of Birth",
//                       border: OutlineInputBorder(),
//                       suffixIcon: Icon(Icons.calendar_today),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) {
//                         return 'Select date of birth';
//                       }
//                       return null;
//                     },
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
//                   const SizedBox(height: 10),

//                   _buildValidatedField(
//                     controller: password,
//                     label: "Password",
//                     obscureText: true,
//                     keyboardType: TextInputType.number,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Enter password';
//                       if (v.length < 8) return 'Must be at least 8 characters';
//                       if (!RegExp(
//                         r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
//                       ).hasMatch(v)) {
//                         return 'Use upper, lower, number & special character';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 10),

//                   TextFormField(
//                     controller: limitAmount,
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(
//                       labelText: "Spending Limit Amount (SAR)",
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty)
//                         return 'Enter a spending limit';
//                       final value = double.tryParse(v);
//                       if (value == null || value <= 0)
//                         return 'Enter a valid amount';
//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 if (!_formKey.currentState!.validate()) return;

//                 await registerChild(
//                   firstName.text.trim(),
//                   nationalId.text.trim(),
//                   phoneNo.text.trim(),
//                   dob.text.trim(),
//                   password.text.trim(),
//                   limitAmount.text.trim(),
//                 );

//                 if (context.mounted) Navigator.pop(context);
//               },
//               child: const Text("Add"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> registerChild(
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
//       return;
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
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Child added successfully!")),
//         );
//         fetchChildren(); // Refresh
//       } else {
//         final data = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data['error'] ?? 'Failed to add child')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

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
//         border: const OutlineInputBorder(),
//       ),
//       validator: validator,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primary = Color(0xFF1ABC9C);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Manage Kids"),
//         backgroundColor: primary,
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: primary,
//         onPressed: _openAddChildDialog,
//         child: const Icon(Icons.add),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : children.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Icon(Icons.family_restroom, size: 80, color: Colors.grey),
//                   SizedBox(height: 20),
//                   Text(
//                     "No children added yet",
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//           : RefreshIndicator(
//               onRefresh: fetchChildren,
//               child: ListView.builder(
//                 itemCount: children.length,
//                 itemBuilder: (context, index) {
//                   final kid = children[index];
//                   return Card(
//                     margin: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     child: ListTile(
//                       leading: const Icon(Icons.person_outline),
//                       title: Text(kid['firstName'] ?? 'Unnamed'),
//                       subtitle: Text('Phone: ${kid['phoneNo'] ?? '—'}'),
//                     ),
//                   );
//                 },
//               ),
//             ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

class ManageKidsScreen extends StatefulWidget {
  const ManageKidsScreen({super.key});

  @override
  State<ManageKidsScreen> createState() => _ManageKidsScreenState();
}

class _ManageKidsScreenState extends State<ManageKidsScreen> {
  List children = [];
  bool _loading = true;
  late int parentId;

  final TextEditingController password = TextEditingController();

  String? token;
  static const String baseUrl = "http://10.0.2.2:3000";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkAuthStatus(context);

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    parentId = args?['parentId'] ?? 0;

    _loadToken().then((_) => fetchChildren());
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
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
        setState(() {
          children = decoded is List ? decoded : [];
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
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

  void _openAddChildDialog() {
    final _formKey = GlobalKey<FormState>();
    final firstName = TextEditingController();
    final nationalId = TextEditingController();
    final phoneNo = TextEditingController();
    final dob = TextEditingController();
    final limitAmount = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            "Add Child",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF2C3E50),
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildValidatedField(
                    controller: firstName,
                    label: "First Name",
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter first name';
                      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v)) {
                        return 'Letters only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildValidatedField(
                    controller: nationalId,
                    label: "National ID",
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter National ID';
                      if (v.length != 10) return 'Must be 10 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildValidatedField(
                    controller: phoneNo,
                    label: "Phone Number",
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter phone number';
                      if (!RegExp(r'^05\d{8}$').hasMatch(v)) {
                        return 'Invalid format (must start with 05)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date of Birth
                  TextFormField(
                    controller: dob,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      filled: true,
                      fillColor: const Color(0xFFFDFDFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select date of birth' : null,
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2010),
                        firstDate: DateTime(2007),
                        lastDate: DateTime.now(),
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

                  _buildValidatedField(
                    controller: password,
                    label: "Password",
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter password';
                      if (v.length < 8) {
                        return 'Must be at least 8 characters';
                      }
                      if (!RegExp(
                        r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])',
                      ).hasMatch(v)) {
                        return 'Use upper, lower, number & special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: limitAmount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Spending Limit (SAR)",
                      filled: true,
                      fillColor: const Color(0xFFFDFDFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter a spending limit';
                      }
                      final value = double.tryParse(v);
                      if (value == null || value <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37C4BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                await registerChild(
                  firstName.text.trim(),
                  nationalId.text.trim(),
                  phoneNo.text.trim(),
                  dob.text.trim(),
                  password.text.trim(),
                  limitAmount.text.trim(),
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> registerChild(
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
      return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Child added successfully!")),
        );
        fetchChildren();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to add child')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    const hassalaGreen1 = Color(0xFF37C4BE);
    const hassalaGreen2 = Color(0xFF2EA49E);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddChildDialog,
        backgroundColor: hassalaGreen1,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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
              // ====== HEADER ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 26,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Manage Children",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ====== YOUR CHILDREN TAG ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.family_restroom,
                        size: 20,
                        color: Color(0xFF2EA49E),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Your Children",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ====== CHILDREN LIST ======
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : children.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.family_restroom,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "No children added yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchChildren,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: children.length,
                          itemBuilder: (context, index) {
                            final kid = children[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2EA49E,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF2EA49E),
                                  ),
                                ),
                                title: Text(
                                  kid['firstName'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                subtitle: Text(
                                  'Phone: ${kid['phoneNo'] ?? '—'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.family_restroom, size: 90, color: Color(0xFFB0BEC5)),
            SizedBox(height: 20),
            Text(
              "No children added yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF607D8B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Tap the + button to add your first child account.",
              style: TextStyle(fontSize: 14, color: Color(0xFF90A4AE)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _childCard(dynamic kid) {
    const hassalaGreen2 = Color(0xFF2EA49E);

    final name = kid['firstName'] ?? 'Unnamed';
    final phone = kid['phoneNo'] ?? '—';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF37C4BE), hassalaGreen2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Text(
          'Phone: $phone',
          style: const TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      ),
    );
  }
}
