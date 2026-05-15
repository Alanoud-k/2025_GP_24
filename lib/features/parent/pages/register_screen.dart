// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:my_app/l10n/app_localizations.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final firstName = TextEditingController();
//   final lastName = TextEditingController();
//   final nationalId = TextEditingController();
//   final dob = TextEditingController();
//   final password = TextEditingController();
//   final securityAnswer = TextEditingController();
//   final confirmPassword = TextEditingController();

//   String phoneNo = '';
//   bool _obscure = true;
//   bool _obscureConfirm = true;
//   bool _isLoading = false;

//   // متغيرات لتخزين رسائل الخطأ القادمة من الخادم وعرضها تحت كل خانة
//   String? _apiFirstNameError;
//   String? _apiLastNameError;
//   String? _apiNationalIdError;
//   String? _apiDobError;
//   String? _apiPasswordError;
//   String? _apiSecurityAnswerError;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     phoneNo = args?['phoneNo'] ?? '';
//   }

//   @override
//   void dispose() {
//     firstName.dispose();
//     lastName.dispose();
//     nationalId.dispose();
//     dob.dispose();
//     password.dispose();
//     confirmPassword.dispose();
//     securityAnswer.dispose();
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

//   void _showSuccessBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showPasswordRequirementsDialog(BuildContext context, AppLocalizations l10n) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           title: Text(
//             l10n.passwordRequirementsTitle,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(l10n.passwordRequirementsList),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // تم التعديل لدعم اللغة العربية والإنجليزية بشكل صريح
//   String? _nameValidator(String? v, AppLocalizations l10n) {
//     if (v == null || v.trim().isEmpty) {
//       return l10n.requiredField;
//     }
//     if (v.trim().length < 2) {
//       return l10n.nameMinLengthVal;
//     }
//     // دعم الحروف العربية والإنجليزية والمسافات
//     if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v.trim())) {
//       return l10n.nameLettersOnlyVal;
//     }
//     return null;
//   }

//   String? _nationalIdValidator(String? v, AppLocalizations l10n) {
//     final value = (v ?? '').trim();
//     if (value.isEmpty) return l10n.requiredField;
//     if (!RegExp(r'^\d{10}$').hasMatch(value)) {
//       return l10n.nationalIdValidationVal;
//     }
//     return null;
//   }

//   String? _confirmPasswordValidator(String? v, AppLocalizations l10n) {
//     final value = (v ?? '').trim();
//     if (value.isEmpty) return l10n.confirmPasswordVal;
//     if (value != password.text.trim()) return l10n.passwordsDoNotMatchVal;
//     return null;
//   }

//   // دالة مخصصة للسؤال الأمني لدعم العربية والإنجليزية والأرقام
//   String? _securityAnswerValidator(String? v, AppLocalizations l10n) {
//     if (v == null || v.trim().isEmpty) {
//       return l10n.requiredField;
//     }
//     if (!RegExp(r'^[\u0600-\u06FFa-zA-Z0-9\s]+$').hasMatch(v.trim())) {
//       return 'الرجاء إدخال أحرف وأرقام فقط'; 
//     }
//     return null;
//   }

//   Future<void> _registerParent(AppLocalizations l10n) async {
//     if (!_formKey.currentState!.validate()) return;
    
//     if (_isLoading) return;
    
//     setState(() {
//       _isLoading = true;
//       // تصفير أخطاء الواجهة البرمجية السابقة
//       _apiFirstNameError = null;
//       _apiLastNameError = null;
//       _apiNationalIdError = null;
//       _apiDobError = null;
//       _apiPasswordError = null;
//       _apiSecurityAnswerError = null;
//     });
    
//     final url = Uri.parse('http://10.0.2.2:3000/api/auth/register-parent');

//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'firstName': firstName.text.trim(),
//           'lastName': lastName.text.trim(),
//           'nationalId': int.tryParse(nationalId.text.trim()),
//           'DoB': dob.text.trim(),
//           'phoneNo': phoneNo.trim(),
//           'password': password.text.trim(),
//           'securityAnswer': securityAnswer.text.trim(),
//         }),
//       );

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         _showSuccessBar(l10n.registeredSuccessfully);

//         Navigator.pushReplacementNamed(
//           context,
//           '/parentLogin',
//           arguments: {'phoneNo': phoneNo},
//         );
//       } else {
//         final decoded = jsonDecode(response.body);
//         final errorMsg = decoded['error']?.toString() ?? '';
//         final errorLower = errorMsg.toLowerCase();
        
//         // ترجمة وتوجيه أخطاء الخادم إلى كل خانة
//         setState(() {
//           if (errorLower.contains('first name')) {
//             _apiFirstNameError = 'الاسم الأول غير صالح';
//           } else if (errorLower.contains('last name')) {
//             _apiLastNameError = 'الاسم الأخير غير صالح';
//           } else if (errorLower.contains('national')) {
//             _apiNationalIdError = 'رقم الهوية/الإقامة غير صالح';
//           } else if (errorLower.contains('password')) {
//             _apiPasswordError = 'كلمة المرور غير صالحة';
//           } else if (errorLower.contains('security')) {
//             _apiSecurityAnswerError = 'إجابة السؤال الأمني غير صالحة';
//           } else if (errorLower.contains('dob') || errorLower.contains('date')) {
//             _apiDobError = 'تاريخ الميلاد غير صالح';
//           } else {
//             // إظهار رسالة عامة للخطأ غير المعروف أسفل الشاشة
//             _showErrorBar(errorMsg.isEmpty ? l10n.registrationFailed : errorMsg);
//           }
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _showErrorBar(l10n.errorPrefixMsg(e.toString()));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
    
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
//             begin: AlignmentDirectional.topCenter,
//             end: AlignmentDirectional.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Align(
//                 alignment: AlignmentDirectional.centerStart,
//                 child: IconButton(
//                   icon: const Icon(
//                     Icons.arrow_back,
//                     color: Colors.black,
//                     size: 28,
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//               ),

//               Expanded(
//                 child: Center(
//                   child: SingleChildScrollView(
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxWidth: 380),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 26),
//                         child: Form(
//                           key: _formKey,
//                           child: Column(
//                             children: [
//                               const SizedBox(height: 20),

//                               Transform.translate(
//                                 offset: const Offset(0, 70),
//                                 child: Image.asset(
//                                   'assets/logo/hassalaLogo5.png',
//                                   width: MediaQuery.of(context).size.width * 0.70,
//                                   fit: BoxFit.contain,
//                                 ),
//                               ),

//                               const SizedBox(height: 10),

//                               Text(
//                                 l10n.createYourAccount,
//                                 style: const TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w800,
//                                   color: Color(0xFF2C3E50),
//                                 ),
//                               ),

//                               const SizedBox(height: 20),

//                               _field(
//                                 firstName,
//                                 l10n.firstNameLabel,
//                                 validator: (v) => _nameValidator(v, l10n),
//                                 errorText: _apiFirstNameError,
//                                 onChanged: () {
//                                   if (_apiFirstNameError != null) setState(() => _apiFirstNameError = null);
//                                 },
//                                 l10n: l10n,
//                               ),
//                               const SizedBox(height: 15),

//                               _field(
//                                 lastName,
//                                 l10n.lastNameLabel,
//                                 validator: (v) => _nameValidator(v, l10n),
//                                 errorText: _apiLastNameError,
//                                 onChanged: () {
//                                   if (_apiLastNameError != null) setState(() => _apiLastNameError = null);
//                                 },
//                                 l10n: l10n,
//                               ),
//                               const SizedBox(height: 15),

//                               _field(
//                                 nationalId,
//                                 l10n.nationalIdIqamaLabel,
//                                 keyboardType: TextInputType.number,
//                                 validator: (v) => _nationalIdValidator(v, l10n),
//                                 errorText: _apiNationalIdError,
//                                 onChanged: () {
//                                   if (_apiNationalIdError != null) setState(() => _apiNationalIdError = null);
//                                 },
//                                 l10n: l10n,
//                               ),
//                               const SizedBox(height: 15),

//                               _buildDateField(l10n),
//                               const SizedBox(height: 15),

//                               Material(
//                                 elevation: 10,
//                                 shadowColor: Colors.black12,
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: TextFormField(
//                                   controller: password,
//                                   obscureText: _obscure,
//                                   onChanged: (v) {
//                                     if (_apiPasswordError != null) setState(() => _apiPasswordError = null);
//                                   },
//                                   decoration: InputDecoration(
//                                     hintText: l10n.passwordHint,
//                                     errorText: _apiPasswordError, // عرض خطأ السيرفر
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 20,
//                                       vertical: 18,
//                                     ),
//                                     prefixIcon: IconButton(
//                                       icon: const Icon(
//                                         Icons.info_outline,
//                                         color: Colors.black54,
//                                       ),
//                                       onPressed: () =>
//                                           _showPasswordRequirementsDialog(context, l10n),
//                                     ),
//                                     suffixIcon: GestureDetector(
//                                       onTap: () =>
//                                           setState(() => _obscure = !_obscure),
//                                       child: Padding(
//                                         padding: const EdgeInsetsDirectional.only(end: 12),
//                                         child: Icon(
//                                           _obscure
//                                               ? Icons.visibility_off
//                                               : Icons.visibility,
//                                           size: 26,
//                                           color: Colors.black54,
//                                         ),
//                                       ),
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                   ),
//                                   validator: (v) {
//                                     if (v == null || v.isEmpty)
//                                       return l10n.enterPasswordVal;
//                                     if (v.length < 8)
//                                       return l10n.passwordMinLengthVal;
//                                     if (!RegExp(
//                                       r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*])',
//                                     ).hasMatch(v)) {
//                                       return l10n.passwordRegexVal;
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                               ),

//                               const SizedBox(height: 15),

//                               Material(
//                                 elevation: 10,
//                                 shadowColor: Colors.black12,
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: TextFormField(
//                                   controller: confirmPassword,
//                                   obscureText: _obscureConfirm,
//                                   decoration: InputDecoration(
//                                     hintText: l10n.confirmPasswordHint,
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 20,
//                                       vertical: 18,
//                                     ),
//                                     suffixIcon: GestureDetector(
//                                       onTap: () => setState(
//                                         () => _obscureConfirm = !_obscureConfirm,
//                                       ),
//                                       child: Padding(
//                                         padding: const EdgeInsetsDirectional.only(end: 12),
//                                         child: Icon(
//                                           _obscureConfirm
//                                               ? Icons.visibility_off
//                                               : Icons.visibility,
//                                           size: 26,
//                                           color: Colors.black54,
//                                         ),
//                                       ),
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                   ),
//                                   validator: (v) => _confirmPasswordValidator(v, l10n),
//                                 ),
//                               ),

//                               const SizedBox(height: 15),

//                               _field(
//                                 securityAnswer,
//                                 l10n.securityQuestionAnswerLabel,
//                                 validator: (v) => _securityAnswerValidator(v, l10n),
//                                 errorText: _apiSecurityAnswerError,
//                                 onChanged: () {
//                                   if (_apiSecurityAnswerError != null) setState(() => _apiSecurityAnswerError = null);
//                                 },
//                                 suffix: const Icon(
//                                   Icons.lock_outline,
//                                   color: Colors.grey,
//                                 ),
//                                 l10n: l10n,
//                               ),

//                               Padding(
//                                 padding: const EdgeInsets.only(top: 5),
//                                 child: Text(
//                                   l10n.securityQuestionHint,
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     color: Colors.black54,
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 25),

//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DecoratedBox(
//                                   decoration: BoxDecoration(
//                                     gradient: const LinearGradient(
//                                       colors: [
//                                         Color(0xFF37C4BE),
//                                         Color(0xFF2EA49E),
//                                       ],
//                                     ),
//                                     borderRadius: BorderRadius.circular(22),
//                                   ),
//                                   child: ElevatedButton(
//                                     onPressed: () => _registerParent(l10n),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.transparent,
//                                       shadowColor: Colors.transparent,
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 18,
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(22),
//                                       ),
//                                     ),
//                                     child: _isLoading 
//                                         ? const CircularProgressIndicator(color: Colors.white) 
//                                         : Text(
//                                             l10n.continue_,
//                                             style: const TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.w700,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 20),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // تم تحديث الدالة لتستقبل errorText و onChanged للتعامل مع أخطاء السيرفر
//   Widget _field(
//     TextEditingController controller,
//     String hint, {
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//     Widget? suffix,
//     String? errorText,
//     VoidCallback? onChanged,
//     required AppLocalizations l10n,
//   }) {
//     return Material(
//       elevation: 10,
//       shadowColor: Colors.black12,
//       borderRadius: BorderRadius.circular(20),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         onChanged: (v) {
//           if (onChanged != null) onChanged();
//         },
//         decoration: InputDecoration(
//           hintText: hint,
//           errorText: errorText, // إضافة مكان لرسالة الخطأ
//           filled: true,
//           fillColor: Colors.white,
//           suffixIcon: suffix,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 18,
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(20),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         validator:
//             validator ??
//             (v) => v == null || v.isEmpty ? l10n.requiredField : null,
//       ),
//     );
//   }

//   Widget _buildDateField(AppLocalizations l10n) {
//     return Material(
//       elevation: 10,
//       shadowColor: Colors.black12,
//       borderRadius: BorderRadius.circular(20),
//       child: TextFormField(
//         controller: dob,
//         readOnly: true,
//         onChanged: (v) {
//           if (_apiDobError != null) setState(() => _apiDobError = null);
//         },
//         decoration: InputDecoration(
//           hintText: l10n.dobLabel,
//           errorText: _apiDobError, // إضافة مكان لرسالة الخطأ
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 18,
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(20),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         onTap: () async {
//           FocusScope.of(context).unfocus();
//           if (_apiDobError != null) setState(() => _apiDobError = null); // مسح الخطأ عند الفتح

//           final picked = await showDatePicker(
//             context: context,
//             initialDate: DateTime(2000),
//             firstDate: DateTime(1970),
//             lastDate: DateTime.now(),
//           );

//           if (picked != null) {
//             dob.text = picked.toIso8601String().split('T').first;
//           }
//         },
//         validator: (v) => v == null || v.isEmpty ? l10n.selectDateVal : null,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/l10n/app_localizations.dart';
// 1. أضفنا استيراد ملف الإعدادات هنا
import 'package:my_app/core/api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final nationalId = TextEditingController();
  final dob = TextEditingController();
  final password = TextEditingController();
  final securityAnswer = TextEditingController();
  final confirmPassword = TextEditingController();

  String phoneNo = '';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // متغيرات لتخزين رسائل الخطأ القادمة من الخادم وعرضها تحت كل خانة
  String? _apiFirstNameError;
  String? _apiLastNameError;
  String? _apiNationalIdError;
  String? _apiDobError;
  String? _apiPasswordError;
  String? _apiSecurityAnswerError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    phoneNo = args?['phoneNo'] ?? '';
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    nationalId.dispose();
    dob.dispose();
    password.dispose();
    confirmPassword.dispose();
    securityAnswer.dispose();
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

  void _showSuccessBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPasswordRequirementsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            l10n.passwordRequirementsTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.passwordRequirementsList),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // تم التعديل لدعم اللغة العربية والإنجليزية بشكل صريح
  String? _nameValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) {
      return l10n.requiredField;
    }
    if (v.trim().length < 2) {
      return l10n.nameMinLengthVal;
    }
    // دعم الحروف العربية والإنجليزية والمسافات
    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v.trim())) {
      return l10n.nameLettersOnlyVal;
    }
    return null;
  }

  String? _nationalIdValidator(String? v, AppLocalizations l10n) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return l10n.requiredField;
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return l10n.nationalIdValidationVal;
    }
    return null;
  }

  String? _confirmPasswordValidator(String? v, AppLocalizations l10n) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return l10n.confirmPasswordVal;
    if (value != password.text.trim()) return l10n.passwordsDoNotMatchVal;
    return null;
  }

  // دالة مخصصة للسؤال الأمني لدعم العربية والإنجليزية والأرقام
  String? _securityAnswerValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) {
      return l10n.requiredField;
    }
    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z0-9\s]+$').hasMatch(v.trim())) {
      return 'الرجاء إدخال أحرف وأرقام فقط'; 
    }
    return null;
  }

  Future<void> _registerParent(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      // تصفير أخطاء الواجهة البرمجية السابقة
      _apiFirstNameError = null;
      _apiLastNameError = null;
      _apiNationalIdError = null;
      _apiDobError = null;
      _apiPasswordError = null;
      _apiSecurityAnswerError = null;
    });
    
    // 2. هنا قمنا بتغيير الرابط ليتصل بالسيرفر المرفوع بدلاً من المحلي (Emulator)
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/register-parent');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName.text.trim(),
          'lastName': lastName.text.trim(),
          'nationalId': int.tryParse(nationalId.text.trim()),
          'DoB': dob.text.trim(),
          'phoneNo': phoneNo.trim(),
          'password': password.text.trim(),
          'securityAnswer': securityAnswer.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessBar(l10n.registeredSuccessfully);

        Navigator.pushReplacementNamed(
          context,
          '/parentLogin',
          arguments: {'phoneNo': phoneNo},
        );
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg = decoded['error']?.toString() ?? '';
        final errorLower = errorMsg.toLowerCase();
        
        // ترجمة وتوجيه أخطاء الخادم إلى كل خانة
        setState(() {
          if (errorLower.contains('first name')) {
            _apiFirstNameError = 'الاسم الأول غير صالح';
          } else if (errorLower.contains('last name')) {
            _apiLastNameError = 'الاسم الأخير غير صالح';
          } else if (errorLower.contains('national')) {
            _apiNationalIdError = 'رقم الهوية/الإقامة غير صالح';
          } else if (errorLower.contains('password')) {
            _apiPasswordError = 'كلمة المرور غير صالحة';
          } else if (errorLower.contains('security')) {
            _apiSecurityAnswerError = 'إجابة السؤال الأمني غير صالحة';
          } else if (errorLower.contains('dob') || errorLower.contains('date')) {
            _apiDobError = 'تاريخ الميلاد غير صالح';
          } else {
            // إظهار رسالة عامة للخطأ غير المعروف أسفل الشاشة
            _showErrorBar(errorMsg.isEmpty ? l10n.registrationFailed : errorMsg);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorBar(l10n.errorPrefixMsg(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              Expanded(
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
                              const SizedBox(height: 20),

                              Transform.translate(
                                offset: const Offset(0, 70),
                                child: Image.asset(
                                  'assets/logo/hassalaLogo5.png',
                                  width: MediaQuery.of(context).size.width * 0.70,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                l10n.createYourAccount,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),

                              const SizedBox(height: 20),

                              _field(
                                firstName,
                                l10n.firstNameLabel,
                                validator: (v) => _nameValidator(v, l10n),
                                errorText: _apiFirstNameError,
                                onChanged: () {
                                  if (_apiFirstNameError != null) setState(() => _apiFirstNameError = null);
                                },
                                l10n: l10n,
                              ),
                              const SizedBox(height: 15),

                              _field(
                                lastName,
                                l10n.lastNameLabel,
                                validator: (v) => _nameValidator(v, l10n),
                                errorText: _apiLastNameError,
                                onChanged: () {
                                  if (_apiLastNameError != null) setState(() => _apiLastNameError = null);
                                },
                                l10n: l10n,
                              ),
                              const SizedBox(height: 15),

                              _field(
                                nationalId,
                                l10n.nationalIdIqamaLabel,
                                keyboardType: TextInputType.number,
                                validator: (v) => _nationalIdValidator(v, l10n),
                                errorText: _apiNationalIdError,
                                onChanged: () {
                                  if (_apiNationalIdError != null) setState(() => _apiNationalIdError = null);
                                },
                                l10n: l10n,
                              ),
                              const SizedBox(height: 15),

                              _buildDateField(l10n),
                              const SizedBox(height: 15),

                              Material(
                                elevation: 10,
                                shadowColor: Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                                child: TextFormField(
                                  controller: password,
                                  obscureText: _obscure,
                                  onChanged: (v) {
                                    if (_apiPasswordError != null) setState(() => _apiPasswordError = null);
                                  },
                                  decoration: InputDecoration(
                                    hintText: l10n.passwordHint,
                                    errorText: _apiPasswordError, // عرض خطأ السيرفر
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    prefixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.black54,
                                      ),
                                      onPressed: () =>
                                          _showPasswordRequirementsDialog(context, l10n),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional.only(end: 12),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 26,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return l10n.enterPasswordVal;
                                    if (v.length < 8)
                                      return l10n.passwordMinLengthVal;
                                    if (!RegExp(
                                      r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*])',
                                    ).hasMatch(v)) {
                                      return l10n.passwordRegexVal;
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 15),

                              Material(
                                elevation: 10,
                                shadowColor: Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                                child: TextFormField(
                                  controller: confirmPassword,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    hintText: l10n.confirmPasswordHint,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional.only(end: 12),
                                        child: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 26,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) => _confirmPasswordValidator(v, l10n),
                                ),
                              ),

                              const SizedBox(height: 15),

                              _field(
                                securityAnswer,
                                l10n.securityQuestionAnswerLabel,
                                validator: (v) => _securityAnswerValidator(v, l10n),
                                errorText: _apiSecurityAnswerError,
                                onChanged: () {
                                  if (_apiSecurityAnswerError != null) setState(() => _apiSecurityAnswerError = null);
                                },
                                suffix: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey,
                                ),
                                l10n: l10n,
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  l10n.securityQuestionHint,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF37C4BE),
                                        Color(0xFF2EA49E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _registerParent(l10n),
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
                                        ? const CircularProgressIndicator(color: Colors.white) 
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

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  // تم تحديث الدالة لتستقبل errorText و onChanged للتعامل مع أخطاء السيرفر
  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
    String? errorText,
    VoidCallback? onChanged,
    required AppLocalizations l10n,
  }) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (v) {
          if (onChanged != null) onChanged();
        },
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText, // إضافة مكان لرسالة الخطأ
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        validator:
            validator ??
            (v) => v == null || v.isEmpty ? l10n.requiredField : null,
      ),
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: TextFormField(
        controller: dob,
        readOnly: true,
        onChanged: (v) {
          if (_apiDobError != null) setState(() => _apiDobError = null);
        },
        decoration: InputDecoration(
          hintText: l10n.dobLabel,
          errorText: _apiDobError, // إضافة مكان لرسالة الخطأ
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        onTap: () async {
          FocusScope.of(context).unfocus();
          if (_apiDobError != null) setState(() => _apiDobError = null); // مسح الخطأ عند الفتح

          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
          );

          if (picked != null) {
            dob.text = picked.toIso8601String().split('T').first;
          }
        },
        validator: (v) => v == null || v.isEmpty ? l10n.selectDateVal : null,
      ),
    );
  }
}