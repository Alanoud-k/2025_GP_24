// import 'dart:convert';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:my_app/l10n/app_localizations.dart';
// import 'package:my_app/core/api_config.dart';
// import 'package:my_app/main.dart';

// class MobileInputScreen extends StatefulWidget {
//   const MobileInputScreen({super.key});

//   @override
//   State<MobileInputScreen> createState() => _MobileInputScreenState();
// }

// class _MobileInputScreenState extends State<MobileInputScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController phoneController = TextEditingController();

//   bool _loading = false;
//   bool _showPhoneHelp = false;

//   bool get _canContinue => !_loading;

//   @override
//   void dispose() {
//     phoneController.dispose();
//     super.dispose();
//   }

//   void _showErrorBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFFE74C3C),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String? _phoneValidator(String? v) {
//     final value = (v ?? '').trim();
//     if (value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterMobile;
//     if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
//       return AppLocalizations.of(context)!.validSaudiPhone;
//     }
//     return null;
//   }

//   void _toggleLanguage() {
//     final currentLocale = localeNotifier.value;
//     localeNotifier.value = currentLocale.languageCode == 'ar'
//         ? const Locale('en')
//         : const Locale('ar');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     const hassalaLinkColor = Color(0xFF2EA49E);

//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 380),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 26),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 10),

//                         /// Language Toggle Button
//                         Align(
//                           alignment: AlignmentDirectional.centerEnd,
//                           child: GestureDetector(
//                             onTap: _toggleLanguage,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.8),
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                   color: const Color(0xFF2EA49E).withOpacity(0.3),
//                                 ),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(
//                                     Icons.language,
//                                     size: 16,
//                                     color: const Color(0xFF2EA49E),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     localeNotifier.value.languageCode == 'ar'
//                                         ? l10n.english
//                                         : l10n.arabic,
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                       color: Color(0xFF2C3E50),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 10),

//                         /// Logo
//                         Transform.translate(
//                           offset: const Offset(0, 40),
//                           child: Image.asset(
//                             'assets/logo/hassalaLogo5.png',
//                             width: MediaQuery.of(context).size.width * 0.9,
//                             fit: BoxFit.contain,
//                           ),
//                         ),

//                         const SizedBox(height: 10),

//                         /// Welcome
//                         Text(
//                           l10n.welcome,
//                           style: const TextStyle(
//                             fontSize: 30,
//                             fontWeight: FontWeight.w800,
//                             color: Color(0xFF2C3E50),
//                           ),
//                         ),

//                         const SizedBox(height: 10),

//                         /// Subtitle
//                         Text(
//                           l10n.enterMobileNumber,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF2C3E50),
//                             height: 1.4,
//                           ),
//                         ),

//                         const SizedBox(height: 40),

//                         /// TextFormField with validator
//                         Material(
//                           elevation: 10,
//                           shadowColor: Colors.black12,
//                           borderRadius: BorderRadius.circular(20),
//                           child: TextFormField(
//                             controller: phoneController,
//                             keyboardType: TextInputType.number,
//                             validator: _phoneValidator,
//                             decoration: InputDecoration(
//                               hintText: l10n.mobileHint,
//                               hintStyle: const TextStyle(
//                                 color: Colors.black38,
//                                 fontSize: 16,
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 18,
//                               ),
//                               filled: true,
//                               fillColor: Colors.white,
//                               errorStyle: const TextStyle(
//                                 color: Color(0xFFE74C3C),
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                                 borderSide: BorderSide.none,
//                               ),
//                               enabledBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                                 borderSide: BorderSide.none,
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                                 borderSide: BorderSide.none,
//                               ),
//                               errorBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                                 borderSide: const BorderSide(
//                                   color: Color(0xFFE74C3C),
//                                   width: 1.4,
//                                 ),
//                               ),
//                               focusedErrorBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                                 borderSide: const BorderSide(
//                                   color: Color(0xFFE74C3C),
//                                   width: 1.4,
//                                 ),
//                               ),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _showPhoneHelp
//                                       ? Icons.info
//                                       : Icons.info_outline,
//                                   color: Colors.black54,
//                                 ),
//                                 onPressed: () {
//                                   setState(
//                                     () => _showPhoneHelp = !_showPhoneHelp,
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),

//                         // Help box under field
//                         AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 200),
//                           child: !_showPhoneHelp
//                               ? const SizedBox(height: 0)
//                               : Container(
//                                   width: double.infinity,
//                                   margin: const EdgeInsets.only(top: 10),
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(0.85),
//                                     borderRadius: BorderRadius.circular(14),
//                                     border: Border.all(
//                                       color: const Color(
//                                         0xFF2EA49E,
//                                       ).withOpacity(0.25),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     l10n.numberHelp,
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       color: Color(0xFF2C3E50),
//                                       height: 1.35,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                         ),

//                         const SizedBox(height: 25),

//                         /// Terms
//                         Text.rich(
//                           TextSpan(
//                             text: l10n.byClickingContinue,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.black87,
//                               height: 1.4,
//                             ),
//                             children: [
//                               TextSpan(
//                                 text: l10n.terms,
//                                 style: const TextStyle(
//                                   color: hassalaLinkColor,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                                 recognizer: TapGestureRecognizer()
//                                   ..onTap = () {
//                                     // optional route to terms
//                                   },
//                               ),
//                               TextSpan(text: l10n.and),
//                               TextSpan(
//                                 text: l10n.privacyPolicy,
//                                 style: const TextStyle(
//                                   color: hassalaLinkColor,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                                 recognizer: TapGestureRecognizer()
//                                   ..onTap = () {
//                                     // optional route to privacy
//                                   },
//                               ),
//                               const TextSpan(text: '.'),
//                             ],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),

//                         const SizedBox(height: 35),

//                         /// Button
//                         SizedBox(
//                           width: double.infinity,
//                           child: DecoratedBox(
//                             decoration: BoxDecoration(
//                               gradient: _canContinue
//                                   ? const LinearGradient(
//                                       colors: [
//                                         Color(0xFF37C4BE),
//                                         Color(0xFF2EA49E),
//                                       ],
//                                     )
//                                   : LinearGradient(
//                                       colors: [
//                                         Colors.grey.withOpacity(0.4),
//                                         Colors.grey.withOpacity(0.3),
//                                       ],
//                                     ),
//                               borderRadius: BorderRadius.circular(22),
//                             ),
//                             child: ElevatedButton(
//                               onPressed: _loading ? null : _onContinuePressed,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 shadowColor: Colors.transparent,
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 18,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(22),
//                                 ),
//                               ),
//                               child: _loading
//                                   ? const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor:
//                                             AlwaysStoppedAnimation<Color>(
//                                               Colors.white,
//                                             ),
//                                       ),
//                                     )
//                                   : Text(
//                                       l10n.continue_,
//                                       style: const TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w700,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 40),
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

//   Future<void> _onContinuePressed() async {
//     FocusScope.of(context).unfocus();

//     if (!_formKey.currentState!.validate()) return;

//     final phone = phoneController.text.trim();

//     setState(() => _loading = true);

//     try {
//       final uri = Uri.parse('$kBaseUrl/api/auth/check-user');

//       final response = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'phoneNo': phone}),
//       );

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data['exists'] == true) {
//           Navigator.pushNamed(
//             context,
//             data['role'] == 'Parent' ? '/parentLogin' : '/childLogin',
//             arguments: {'phoneNo': phone},
//           );
//         } else {
//           Navigator.pushNamed(
//             context,
//             '/register',
//             arguments: {'phoneNo': phone},
//           );
//         }
//       } else {
//         _showErrorBar(
//           'Server error (${response.statusCode}). Please try again later.',
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _showErrorBar('Error: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 استيراد مكتبة الـ services للـ formatters
import 'package:http/http.dart' as http;
import 'package:my_app/l10n/app_localizations.dart';
import 'package:my_app/core/api_config.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/providers/locale_provider.dart';

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();

  bool _loading = false;
  bool _showPhoneHelp = false;

  bool get _canContinue => !_loading;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _showErrorBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _phoneValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterMobile;
    if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
      return AppLocalizations.of(context)!.validSaudiPhone;
    }
    return null;
  }

  void _toggleLanguage() {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final isAr = provider.locale.languageCode == 'ar';
    provider.setLocale(isAr ? const Locale('en') : const Locale('ar'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguageCode = Provider.of<LocaleProvider>(context).locale.languageCode;
    
    const hassalaLinkColor = Color(0xFF2EA49E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        /// Language Toggle Button
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: GestureDetector(
                            onTap: _toggleLanguage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF2EA49E).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language,
                                    size: 16,
                                    color: Color(0xFF2EA49E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentLanguageCode == 'ar'
                                        ? l10n.english
                                        : l10n.arabic,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Logo
                        Transform.translate(
                          offset: const Offset(0, 40),
                          child: Image.asset(
                            'assets/logo/hassalaLogo5.png',
                            width: MediaQuery.of(context).size.width * 0.9,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Welcome
                        Text(
                          l10n.welcome,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Subtitle
                        Text(
                          l10n.enterMobileNumber,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// TextFormField with validator and formatters
                        Material(
                          elevation: 10,
                          shadowColor: Colors.black12,
                          borderRadius: BorderRadius.circular(20),
                          child: TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            validator: _phoneValidator,
                            
                            // 👇 الكود المضاف لتحويل الأرقام العربية إلى إنجليزية وتحديد طولها
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')), // السماح بالأرقام فقط
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                String text = newValue.text
                                    .replaceAll('٠', '0')
                                    .replaceAll('١', '1')
                                    .replaceAll('٢', '2')
                                    .replaceAll('٣', '3')
                                    .replaceAll('٤', '4')
                                    .replaceAll('٥', '5')
                                    .replaceAll('٦', '6')
                                    .replaceAll('٧', '7')
                                    .replaceAll('٨', '8')
                                    .replaceAll('٩', '9');
                                return newValue.copyWith(
                                  text: text,
                                  selection: newValue.selection,
                                );
                              }),
                              LengthLimitingTextInputFormatter(10), // الحد الأقصى 10 أرقام
                            ],
                            // 👆 نهاية الكود المضاف

                            decoration: InputDecoration(
                              hintText: l10n.mobileHint,
                              hintStyle: const TextStyle(
                                color: Colors.black38,
                                fontSize: 16,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorStyle: const TextStyle(
                                color: Color(0xFFE74C3C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE74C3C),
                                  width: 1.4,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE74C3C),
                                  width: 1.4,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPhoneHelp
                                      ? Icons.info
                                      : Icons.info_outline,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _showPhoneHelp = !_showPhoneHelp,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Help box under field
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: !_showPhoneHelp
                              ? const SizedBox(height: 0)
                              : Container(
                                  width: double.infinity,
                                  margin: const EdgeInsetsDirectional.only(top: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF2EA49E,
                                      ).withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.numberHelp,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2C3E50),
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 25),

                        /// Terms
                        Text.rich(
                          TextSpan(
                            text: l10n.byClickingContinue,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: l10n.terms,
                                style: const TextStyle(
                                  color: hassalaLinkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // optional route to terms
                                  },
                              ),
                              TextSpan(text: l10n.and),
                              TextSpan(
                                text: l10n.privacyPolicy,
                                style: const TextStyle(
                                  color: hassalaLinkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // optional route to privacy
                                  },
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
                              onPressed: _loading ? null : _onContinuePressed,
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
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      l10n.continue_,
                                      style: const TextStyle(
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

  Future<void> _onContinuePressed() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final phone = phoneController.text.trim();

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/check-user');

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
        _showErrorBar(
          'Server error (${response.statusCode}). Please try again later.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorBar('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}