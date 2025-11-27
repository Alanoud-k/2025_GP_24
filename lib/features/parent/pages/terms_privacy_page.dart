// import 'package:flutter/material.dart';
// import 'package:my_app/utils/check_auth.dart';

// class TermsPrivacyPage extends StatefulWidget {
//   const TermsPrivacyPage({super.key});

//   @override
//   State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
// }

// class _TermsPrivacyPageState extends State<TermsPrivacyPage> {
//   @override
//   void initState() {
//     super.initState();

//     /// 🔒 Check token validity AFTER the first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await checkAuthStatus(context);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     checkAuthStatus(context);
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'Terms & privacy policy',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header Section
//               const Text(
//                 'Terms & privacy policy',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal,
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Main Points
//               _buildBulletPoint(
//                 'Using Hassala means you agree to our terms and privacy practices',
//               ),
//               _buildBulletPoint(
//                 'You control your data, permissions, and linked devices',
//               ),
//               _buildBulletPoint(
//                 'All sensitive data is encrypted and never shared without explicit consent',
//               ),

//               const SizedBox(height: 24),
//               const Divider(height: 1, color: Colors.grey),
//               const SizedBox(height: 24),

//               // Terms of Use Section
//               const Text(
//                 'Terms of Use',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'You agree to use Hassala responsibly and for family financial education purposes. '
//                 'All accounts created under a parent are subject to parental supervision. '
//                 'Transactions are simulated or processed via licensed PSPs. '
//                 'The app follows SAMA and Saudi data protection standards. '
//                 'Misuse of the platform may result in account suspension.'
//                 'Hassala currently uses sandbox-based payment simulations (e.g., Moyasar) '
//                 'and does not support real banking transactions. Only one parent account '
//                 'is supported per family in this version.',

//                 style: TextStyle(
//                   fontSize: 16,
//                   height: 1.5,
//                   color: Colors.black54,
//                 ),
//                 textAlign: TextAlign.justify,
//               ),

//               const SizedBox(height: 24),
//               const Divider(height: 1, color: Colors.grey),
//               const SizedBox(height: 24),

//               // Privacy Policy Section
//               const Text(
//                 'Privacy Policy',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'Hessala does not share your personal or financial data with third parties without consent. '
//                 'All sensitive data (PINs, passwords, tokens) are encrypted at rest and in transit. '
//                 'You can request data deletion or unlink your bank anytime. '
//                 'Only aggregated, anonymized data may be used for analytics.',
//                 style: TextStyle(
//                   fontSize: 16,
//                   height: 1.5,
//                   color: Colors.black54,
//                 ),
//                 textAlign: TextAlign.justify,
//               ),

//               const SizedBox(height: 24),
//               const Divider(height: 1, color: Colors.grey),
//               const SizedBox(height: 24),

//               // Contact Section
//               const Text(
//                 'Questions or concerns?',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Email: support@hessala.sa',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.teal,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),

//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBulletPoint(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(top: 6, right: 8),
//             child: Icon(Icons.circle, size: 6, color: Colors.teal),
//           ),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 16,
//                 height: 1.4,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:my_app/utils/check_auth.dart';

class TermsPrivacyPage extends StatefulWidget {
  const TermsPrivacyPage({super.key});

  @override
  State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends State<TermsPrivacyPage> {
  @override
  void initState() {
    super.initState();

    /// 🔒 Check token validity AFTER the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAuthStatus(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define App Colors
    const Color hassalaGreen = Color(0xFF37C4BE);
    const Color titleColor = Color(0xFF2C3E50);
    const Color bodyColor = Color(0xFF607D8B);

    checkAuthStatus(context);

    return Scaffold(
      body: Container(
        // Standard App Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Custom Header ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: titleColor, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Terms & Privacy',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Content Card ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 0),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intro Section
                        const Text(
                          'Policy Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hassalaGreen,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Points
                        _buildBulletPoint(
                          'Using Hassala means you agree to our terms and privacy practices',
                          hassalaGreen,
                          bodyColor,
                        ),
                        _buildBulletPoint(
                          'You control your data, permissions, and linked devices',
                          hassalaGreen,
                          bodyColor,
                        ),
                        _buildBulletPoint(
                          'All sensitive data is encrypted and never shared without explicit consent',
                          hassalaGreen,
                          bodyColor,
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        // Terms of Use Section
                        const Text(
                          'Terms of Use',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You agree to use Hassala responsibly and for family financial education purposes. '
                          'All accounts created under a parent are subject to parental supervision. '
                          'Transactions are simulated or processed via licensed PSPs. '
                          'The app follows SAMA and Saudi data protection standards. '
                          'Misuse of the platform may result in account suspension. '
                          'Hassala currently uses sandbox-based payment simulations (e.g., Moyasar) '
                          'and does not support real banking transactions. Only one parent account '
                          'is supported per family in this version.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: bodyColor,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        // Privacy Policy Section
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hessala does not share your personal or financial data with third parties without consent. '
                          'All sensitive data (PINs, passwords, tokens) are encrypted at rest and in transit. '
                          'You can request data deletion or unlink your bank anytime. '
                          'Only aggregated, anonymized data may be used for analytics.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: bodyColor,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        // Contact Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hassalaGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Questions or concerns?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'support@hessala.sa',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: hassalaGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color dotColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Icon(Icons.circle, size: 8, color: dotColor),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}