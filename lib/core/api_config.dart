// /*class ApiConfig {
//   static const String baseUrl = "https://2025gp24-production.up.railway.app";
// }

// const String kBaseUrl = ApiConfig.baseUrl;
// */

// class ApiConfig {
//   static const String baseUrl = "http://10.0.2.2:3000";
// }

// const String kBaseUrl = ApiConfig.baseUrl;


import 'package:flutter/foundation.dart'; // ضرورية لمعرفة وضع التطبيق

class ApiConfig {
  // 1. رابط سيرفر الإنتاج (Railway - للعرض النهائي)
  static const String _railwayUrl = "https://2025gp24-production.up.railway.app";
  
  // 2. رابط سيرفر التطوير المحلي (Localhost / Wi-Fi)
  static const String _localUrl = "http://10.0.2.2:3000"; // استبدليه بالـ IP الخاص بك

  // =====================================
  // زر التحكم اليدوي (لأوقات البرمجة والتطوير)
  // اجعليه true لتشغيل المحلي، و false لتشغيل ريل واي
  static const bool _useLocalBackend = false; 
  // =====================================

  // 3. الدالة الذكية التي تغذي التطبيق بالرابط
  static String get baseUrl {
    // kReleaseMode تعني أن التطبيق تم استخراجه كملف APK للعرض النهائي
    if (kReleaseMode) {
      return _railwayUrl; // حماية ذكية: في العرض سيستخدم Railway إجبارياً حتى لو نسيتي تغيير الزر!
    } 
    
    // أما إذا كنتِ تطورين على الـ VS Code (Debug Mode):
    else {
      return _useLocalBackend ? _localUrl : _railwayUrl;
    }
  }
}
