// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'parent_child_overview_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';
// import 'package:my_app/core/api_config.dart';

// class ParentSelectChildScreen extends StatefulWidget {
//   final int parentId;
//   final String token;
//   const ParentSelectChildScreen({
//     super.key,
//     required this.parentId,
//     required this.token,
//   });

//   @override
//   State<ParentSelectChildScreen> createState() =>
//       _ParentSelectChildScreenState();
// }

// class _ParentSelectChildScreenState extends State<ParentSelectChildScreen> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _kids = [];
//   String? token;
//   late final String baseUrl = ApiConfig.baseUrl;

//   //static const String baseUrl = "http://10.0.2.2:3000";

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     await checkAuthStatus(context);
//     await _loadToken();
//     await _fetchChildren();
//   }

//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token") ?? widget.token;
//   }

//   Future<bool> _handleExpired(int statusCode) async {
//     if (statusCode == 401) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();

//       if (!mounted) return true;
//       Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//       return true;
//     }
//     return false;
//   }

//   Future<void> _fetchChildren() async {
//     await checkAuthStatus(context);
//     if (token == null) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Authentication error: Missing token.")),
//       );
//       return;
//     }

//     try {
//       final url = Uri.parse(
//         "$baseUrl/api/auth/parent/${widget.parentId}/children",
//       );

//       final response = await http.get(
//         url,
//         headers: {"Authorization": "Bearer $token"},
//       );

//       if (!mounted) return;
//       if (await _handleExpired(response.statusCode)) return;

//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);

//         setState(() {
//           _kids = data.map((child) {
//             return {
//               "id": child["childId"],
//               "name": child["firstName"] ?? "Unnamed",
//               "saving": child["saving"] ?? 0.0,
//               "spend": child["spend"] ?? 0.0,
//               "balance": child["balance"] ?? 0.0,
//             };
//           }).toList();
//           _loading = false;
//         });
//       } else {
//         setState(() => _loading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Failed to load children (Code: ${response.statusCode})",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() => _loading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error fetching children: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const bg1 = Color(0xFFF7FAFC);
//     const bg2 = Color(0xFFE6F4F3);
//     const hassalaGreen = Color(0xFF2EA49E);

//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [bg1, bg2],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// --- Back Button + Title ---
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 10,
//                 ),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         // decoration: BoxDecoration(
//                         //   color: Colors.white,
//                         //   shape: BoxShape.circle,
//                         //   boxShadow: [
//                         //     BoxShadow(
//                         //       color: Colors.black12.withOpacity(0.08),
//                         //       blurRadius: 6,
//                         //     ),
//                         //   ],
//                         // ),
//                         child: const Icon(
//                           Icons.arrow_back,
//                           color: Colors.black87,
//                           size: 24,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     const Text(
//                       "Select Child",
//                       style: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                         color: Color(0xFF2C3E50),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 10),

//               /// --- Section Tag ---
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black12.withOpacity(0.08),
//                         blurRadius: 6,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       Icon(
//                         Icons.family_restroom,
//                         size: 20,
//                         color: hassalaGreen,
//                       ),
//                       SizedBox(width: 6),
//                       Text(
//                         "Your Children",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF2C3E50),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               /// --- Children List ---
//               Expanded(
//                 child: _loading
//                     ? const Center(child: CircularProgressIndicator())
//                     : _kids.isEmpty
//                     ? Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: const [
//                           Icon(Icons.child_care, size: 90, color: Colors.grey),
//                           SizedBox(height: 20),
//                           Text(
//                             "No children found",
//                             style: TextStyle(fontSize: 18, color: Colors.grey),
//                           ),
//                         ],
//                       )
//                     : ListView.builder(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         itemCount: _kids.length,
//                         itemBuilder: (context, index) {
//                           final kid = _kids[index];
//                           return GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => ParentChildOverviewScreen(
//                                     parentId: widget.parentId,
//                                     childId: kid["id"],
//                                     childName: kid["name"],
//                                     token: widget.token,
//                                   ),
//                                 ),
//                               );
//                             },
//                             child: Container(
//                               margin: const EdgeInsets.only(bottom: 14),
//                               padding: const EdgeInsets.all(16),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(22),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black12.withOpacity(0.1),
//                                     blurRadius: 10,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               child: Row(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(14),
//                                     decoration: BoxDecoration(
//                                       color: hassalaGreen.withOpacity(0.15),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.person,
//                                       size: 28,
//                                       color: hassalaGreen,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 16),

//                                   /// --- Child Info ---
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           kid["name"],
//                                           style: const TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.w700,
//                                             color: Color(0xFF2C3E50),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 6),
//                                         Row(
//                                           children: [
//                                             // Riyal icon – Saving balance
//                                             Image.asset(
//                                               "assets/icons/riyal.png",
//                                               height: 16,
//                                             ),
//                                             const SizedBox(width: 4),
//                                             Text(
//                                               kid["saving"].toStringAsFixed(2),
//                                               style: const TextStyle(
//                                                 fontSize: 13,
//                                                 color: Colors.grey,
//                                               ),
//                                             ),

//                                             const SizedBox(width: 14),

//                                             // Riyal icon – Spending balance
//                                             Image.asset(
//                                               "assets/icons/riyal.png",
//                                               height: 16,
//                                             ),
//                                             const SizedBox(width: 4),
//                                             Text(
//                                               kid["spend"].toStringAsFixed(2),
//                                               style: const TextStyle(
//                                                 fontSize: 13,
//                                                 color: Colors.grey,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                   const Icon(
//                                     Icons.arrow_forward_ios,
//                                     size: 18,
//                                     color: Colors.black54,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parent_child_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

class ParentSelectChildScreen extends StatefulWidget {
  final int parentId;
  final String token;
  const ParentSelectChildScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentSelectChildScreen> createState() =>
      _ParentSelectChildScreenState();
}

class _ParentSelectChildScreenState extends State<ParentSelectChildScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _kids = [];
  String? token;
  late final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    await _loadToken();
    await _fetchChildren();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
  }

  Future<bool> _handleExpired(int statusCode) async {
    if (statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return true;
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
      return true;
    }
    return false;
  }

  Future<void> _fetchChildren() async {
    await checkAuthStatus(context);
    if (token == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication error: Missing token.")),
      );
      return;
    }

    try {
      final url = Uri.parse(
        "$baseUrl/api/auth/parent/${widget.parentId}/children",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;
      if (await _handleExpired(response.statusCode)) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          _kids = data.map((child) {
            return {
              "id": child["childId"],
              "name": child["firstName"] ?? "Unnamed",
              "saving": child["saving"] ?? 0.0,
              "spend": child["spend"] ?? 0.0,
              "balance": child["balance"] ?? 0.0,
            };
          }).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to load children (Code: ${response.statusCode})",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching children: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg1 = Color(0xFFF7FAFC);
    const bg2 = Color(0xFFE6F4F3);
    const hassalaGreen = Color(0xFF2EA49E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- Back Button + Title ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Select Child",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// --- Section Tag ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                        color: hassalaGreen,
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

              const SizedBox(height: 20),

              /// --- Children List ---
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _kids.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.child_care, size: 90, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            "No children found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _kids.length,
                        itemBuilder: (context, index) {
                          final kid = _kids[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParentChildOverviewScreen(
                                    parentId: widget.parentId,
                                    childId: kid["id"],
                                    childName: kid["name"],
                                    token: widget.token,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: hassalaGreen.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 28,
                                      color: hassalaGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  /// --- Child Info ---
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          kid["name"],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // ✅✅✅ تم إضافة الأسماء وتوضيحها هنا ✅✅✅
                                        Row(
                                          children: [
                                            const Text(
                                              "Save: ",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Image.asset(
                                              "assets/icons/riyal.png",
                                              height: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              kid["saving"].toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),

                                            const SizedBox(width: 14),

                                            const Text(
                                              "Spend: ",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Image.asset(
                                              "assets/icons/riyal.png",
                                              height: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              kid["spend"].toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                ],
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