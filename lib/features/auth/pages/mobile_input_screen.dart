// import 'dart:convert';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../../../core/api_config.dart';

// class MobileInputScreen extends StatefulWidget {
//   const MobileInputScreen({super.key});

//   @override
//   State<MobileInputScreen> createState() => _MobileInputScreenState();
// }

// class _MobileInputScreenState extends State<MobileInputScreen> {
//   final TextEditingController phoneController = TextEditingController();
//   bool _loading = false;

//   bool get _canContinue => !_loading && phoneController.text.trim().isNotEmpty;

//   @override
//   void initState() {
//     super.initState();
//     phoneController.addListener(() => setState(() {}));
//   }

//   @override
//   void dispose() {
//     phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primary = Color(0xFF1ABC9C);
//     const hassalaLinkColor = Color(0xFF2EA49E);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 380),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 26),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 30),
//                     // Logo (متوسط)
//                     Image.asset(
//                       'assets/logo/hassalaLogo5.png',
//                       width: 400,
//                       fit: BoxFit.contain,
//                     ),

//                     const SizedBox(height: 5),
//                     // Welcome Text
//                     const Text(
//                       "Welcome",
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF2C3E50),
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     // Title
//                     const Text(
//                       "Please enter your mobile number",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF2C3E50),
//                         height: 1.4,
//                       ),
//                     ),

//                     const SizedBox(height: 35),

//                     // Input Field
//                     Material(
//                       elevation: 4,
//                       shadowColor: Colors.black12,
//                       borderRadius: BorderRadius.circular(16),
//                       child: TextField(
//                         controller: phoneController,
//                         keyboardType: TextInputType.number,
//                         decoration: InputDecoration(
//                           hintText: '05XXXXXXXX',
//                           hintStyle: const TextStyle(
//                             color: Colors.black38,
//                             fontSize: 16,
//                           ),
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 18,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 25),

//                     // Terms + Privacy Policy
//                     Text.rich(
//                       TextSpan(
//                         text: 'By clicking "Continue", you agree to our ',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.black87,
//                           height: 1.4,
//                         ),
//                         children: [
//                           TextSpan(
//                             text: 'Terms',
//                             style: const TextStyle(
//                               color: hassalaLinkColor,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             recognizer: TapGestureRecognizer()
//                               ..onTap = () {
//                                 // TODO: open terms
//                               },
//                           ),
//                           const TextSpan(text: ' and '),
//                           TextSpan(
//                             text: 'Data Privacy Policy',
//                             style: const TextStyle(
//                               color: hassalaLinkColor,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             recognizer: TapGestureRecognizer()
//                               ..onTap = () {
//                                 // TODO: open privacy
//                               },
//                           ),
//                           const TextSpan(text: '.'),
//                         ],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),

//                     const SizedBox(height: 35),

//                     // Continue Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _canContinue ? _onContinuePressed : null,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _canContinue
//                               ? primary
//                               : primary.withOpacity(0.35),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           elevation: _canContinue ? 4 : 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           textStyle: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         child: _loading
//                             ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     Colors.white,
//                                   ),
//                                 ),
//                               )
//                             : const Text("Continue"),
//                       ),
//                     ),

//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // --- API call to /api/auth/check-user ---
//   Future<void> _onContinuePressed() async {
//     final phoneRaw = phoneController.text.trim();

//     if (phoneRaw.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter your mobile number')),
//       );
//       return;
//     }

//     final phoneRegex = RegExp(r'^05\d{8}$');
//     if (!phoneRegex.hasMatch(phoneRaw)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Enter a valid Saudi phone number starting with 05'),
//         ),
//       );
//       return;
//     }

//     final phone = phoneRaw;

//     setState(() => _loading = true);
//     try {
//       final uri = Uri.parse('$kBaseUrl/api/auth/check-user');

//       final response = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'phoneNo': phone}),
//       );

//       debugPrint('CHECK-USER → status: ${response.statusCode}');
//       debugPrint('CHECK-USER → body  : ${response.body}');

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data['exists'] == true) {
//           if (data['role'] == 'Parent') {
//             Navigator.pushNamed(
//               context,
//               '/parentLogin',
//               arguments: {'phoneNo': phone},
//             );
//           } else {
//             Navigator.pushNamed(
//               context,
//               '/childLogin',
//               arguments: {'phoneNo': phone},
//             );
//           }
//         } else {
//           Navigator.pushNamed(
//             context,
//             '/register',
//             arguments: {'phoneNo': phone},
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Server error (${response.statusCode}). Please try again later.',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       debugPrint('CHECK-USER → exception: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
// }
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_config.dart';

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _loading = false;

  bool get _canContinue => !_loading && phoneController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1ABC9C);
    const hassalaLinkColor = Color(0xFF2EA49E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      /// Logo
                      Transform.translate(
                        offset: const Offset(
                          0,
                          40,
                        ),
                        child: Image.asset(
                          'assets/logo/hassalaLogo5.png',
                          width: MediaQuery.of(context).size.width * 0.9,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Welcome
                      const Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Subtitle
                      const Text(
                        "Please enter your mobile number",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// Input
                      Material(
                        elevation: 10,
                        shadowColor: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '05XXXXXXXX',
                              hintStyle: TextStyle(
                                color: Colors.black38,
                                fontSize: 16,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// Terms
                      Text.rich(
                        TextSpan(
                          text: 'By clicking "Continue", you agree to our ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms',
                              style: const TextStyle(
                                color: hassalaLinkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Data Privacy Policy',
                              style: const TextStyle(
                                color: hassalaLinkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 35),

                      /// Button
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _canContinue
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF37C4BE),
                                      Color(0xFF2EA49E),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.4),
                                      Colors.grey.withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ElevatedButton(
                            onPressed: _canContinue ? _onContinuePressed : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
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
    );
  }

  // API LOGIC (unchanged)
  Future<void> _onContinuePressed() async {
    final phoneRaw = phoneController.text.trim();

    if (phoneRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return;
    }

    final phoneRegex = RegExp(r'^05\d{8}$');
    if (!phoneRegex.hasMatch(phoneRaw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid Saudi phone number starting with 05'),
        ),
      );
      return;
    }

    final phone = phoneRaw;

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('$kBaseUrl/api/auth/check-user');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNo': phone}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['exists'] == true) {
          Navigator.pushNamed(
            context,
            data['role'] == 'Parent' ? '/parentLogin' : '/childLogin',
            arguments: {'phoneNo': phone},
          );
        } else {
          Navigator.pushNamed(
            context,
            '/register',
            arguments: {'phoneNo': phone},
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error (${response.statusCode}). Please try again later.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
