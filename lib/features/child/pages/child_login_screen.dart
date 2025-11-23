// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/core/api_config.dart';

// class ChildLoginScreen extends StatefulWidget {
//   const ChildLoginScreen({super.key});

//   @override
//   State<ChildLoginScreen> createState() => _ChildLoginScreenState();
// }

// class _ChildLoginScreenState extends State<ChildLoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController passwordController = TextEditingController();

//   bool _isLoading = false;
//   late String phoneNo;
//   String firstName = '';

//   String get _baseUrl => ApiConfig.baseUrl;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     phoneNo = (args?['phoneNo'] ?? '') as String;
//     _fetchFirstName();
//   }

//   @override
//   void dispose() {
//     passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchFirstName() async {
//     if (phoneNo.isEmpty) return;

//     final url = Uri.parse('$_baseUrl/api/auth/name/$phoneNo');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (mounted) {
//           setState(() => firstName = data['firstName'] ?? '');
//         }
//       }
//     } catch (e) {
//       // You can log this if needed
//     }
//   }

//   Future<void> _loginChild() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     final url = Uri.parse('$_baseUrl/api/auth/login-child');

//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'phoneNo': phoneNo.trim(),
//           'password': passwordController.text.trim(),
//         }),
//       );

//       setState(() => _isLoading = false);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         // ------- SAVE TOKEN -------
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString("token", data['token']);
//         await prefs.setString("role", "Child");
//         await prefs.setInt("childId", data['childId']);

//         Navigator.pushReplacementNamed(
//           context,
//           '/childShell',
//           arguments: {
//             'childId': data['childId'],
//             'baseUrl': _baseUrl,
//             'token': data['token'], // <-- REQUIRED
//           },
//         );
//       } else {
//         final error = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(error['message'] ?? error['error'] ?? 'Login failed'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primary = Color(0xFF1ABC9C);

//     return Scaffold(
//       appBar: AppBar(
//         leading: const BackButton(color: Colors.black87),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFF7F8FA), Color(0xFFE9E9E9)],
//             stops: [0.64, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 380),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Form(
//                   key: _formKey,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 10),

//                         Image.asset(
//                           'assets/logo/hassalaLogo2.png',
//                           width: 350,
//                           fit: BoxFit.contain,
//                         ),
//                         const SizedBox(height: 25),

//                         Text(
//                           'Login for ${firstName.isNotEmpty ? firstName : phoneNo}',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 25),

//                         const Text(
//                           'Enter your password',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Color(0xFF333333),
//                           ),
//                         ),
//                         const SizedBox(height: 30),

//                         // Password field
//                         Material(
//                           elevation: 3,
//                           shadowColor: const Color(0x22000000),
//                           borderRadius: BorderRadius.circular(14),
//                           child: TextFormField(
//                             controller: passwordController,
//                             obscureText: true,
//                             decoration: InputDecoration(
//                               labelText: 'Password',
//                               labelStyle: const TextStyle(
//                                 color: Colors.black45,
//                                 fontSize: 16,
//                               ),
//                               filled: true,
//                               fillColor: Colors.white,
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 16,
//                               ),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                                 borderSide: BorderSide.none,
//                               ),
//                             ),
//                             validator: (v) {
//                               if (v == null || v.isEmpty) {
//                                 return 'Enter your password';
//                               }
//                               if (v.length < 8) {
//                                 return 'Password must be at least 8 characters';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         const SizedBox(height: 40),

//                         // Continue button
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _isLoading ? null : _loginChild,
//                             style: ButtonStyle(
//                               backgroundColor: MaterialStateProperty.all<Color>(
//                                 primary,
//                               ),
//                               foregroundColor: MaterialStateProperty.all<Color>(
//                                 Colors.white,
//                               ),
//                               elevation: MaterialStateProperty.all<double>(6),
//                               shape:
//                                   MaterialStateProperty.all<
//                                     RoundedRectangleBorder
//                                   >(
//                                     RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(22),
//                                     ),
//                                   ),
//                               padding: MaterialStateProperty.all<EdgeInsets>(
//                                 const EdgeInsets.symmetric(vertical: 16),
//                               ),
//                             ),
//                             child: _isLoading
//                                 ? const CircularProgressIndicator(
//                                     color: Colors.white,
//                                   )
//                                 : const Text(
//                                     'Continue',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/core/api_config.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  late String phoneNo;
  String firstName = '';

  String get _baseUrl => ApiConfig.baseUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    phoneNo = (args?['phoneNo'] ?? '') as String;
    _fetchFirstName();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchFirstName() async {
    if (phoneNo.isEmpty) return;

    final url = Uri.parse('$_baseUrl/api/auth/name/$phoneNo');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => firstName = data['firstName'] ?? '');
        }
      }
    } catch (_) {}
  }

  Future<void> _loginChild() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('$_baseUrl/api/auth/login-child');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNo': phoneNo.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data['token']);
        await prefs.setString("role", "Child");
        await prefs.setInt("childId", data['childId']);

        Navigator.pushReplacementNamed(
          context,
          '/childShell',
          arguments: {
            'childId': data['childId'],
            'baseUrl': _baseUrl,
            'token': data['token'],
          },
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const hassalaLinkColor = Color(0xFF2EA49E);

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
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        /// Logo
                        Image.asset(
                          'assets/logo/hassalaLogo5.png',
                          width: MediaQuery.of(context).size.width * 0.90,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Welcome Back",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '${firstName.isNotEmpty ? firstName : phoneNo}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          'Enter your password',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// Password Field
                        Material(
                          elevation: 10,
                          shadowColor: Colors.black12,
                          borderRadius: BorderRadius.circular(20),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: const TextStyle(color: Colors.black38),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),

                              // --------------------------
                              // 👇 زر إظهار/إخفاء الباسورد
                              // --------------------------
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscure = !_obscure;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.black54,
                                    size: 26,
                                  ),
                                ),
                              ),

                              // --------------------------
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your password';
                              }
                              if (v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF37C4BE), Color(0xFF2EA49E)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _loginChild,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Continue",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
