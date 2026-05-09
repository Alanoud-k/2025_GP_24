import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ParentAllowanceScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentAllowanceScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentAllowanceScreen> createState() => _ParentAllowanceScreenState();
}

class _ParentAllowanceScreenState extends State<ParentAllowanceScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _loading = true;
  String? token;

  // البيانات الأساسية
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  
  // إعدادات المصروف
  final TextEditingController _amountController = TextEditingController(text: "100");
  double _savePercentage = 0.0;
  String _frequency = 'Weekly'; 
  String _selectedDayOfWeek = 'Sunday';
  int _selectedDayOfMonth = 1;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  // ألوان التصميم الخاصة بحصالة
  final Color hassalaGreen = const Color(0xFF37C4BE);
  final Color secondaryDark = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await checkAuthStatus(context);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
    await _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children');
    try {
      final res = await http.get(url, headers: {'Authorization': 'Bearer ${token!}'});
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = (decoded is List) ? decoded : decoded["children"] ?? [];
        
        List<Map<String, dynamic>> loadedChildren = [];
        
        for (var c in data) {
          int childId = c['childId'] ?? c['id'];
          
          // --- جلب بيانات المصروف لهذا الطفل لمعرفة حالته ---
          bool hasAllowance = false;
          double amount = 0;
          String freq = 'Weekly';
          String dayW = 'Sunday';
          int dayM = 1;
          String timeStr = '08:00';
          
          try {
            final aRes = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/api/allowance/$childId'), 
              headers: {'Authorization': 'Bearer ${token!}'}
            );
            if (aRes.statusCode == 200) {
              final aData = jsonDecode(aRes.body);
              hasAllowance = aData['isEnabled'] ?? false;
              amount = (aData['amount'] ?? 0).toDouble();
              if (aData['frequency'] != null) freq = aData['frequency'];
              if (aData['dayOfWeek'] != null) dayW = aData['dayOfWeek'];
              if (aData['dayOfMonth'] != null) dayM = aData['dayOfMonth'];
              if (aData['timeOfDay'] != null) timeStr = aData['timeOfDay'];
            }
          } catch (_) {} 

          loadedChildren.add({
            'id': childId,
            'name': c['firstName'] ?? 'Unnamed',
            'ratio': (c['defaultSavingRatio'] ?? 0).toDouble(),
            'hasAllowance': hasAllowance,
            'amount': amount,
            'frequency': freq,
            'dayOfWeek': dayW,
            'dayOfMonth': dayM,
            'timeOfDay': timeStr,
          });
        }

        setState(() {
          _children = loadedChildren;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedChild == null) return;

    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final url = Uri.parse('${ApiConfig.baseUrl}/api/allowance/${_selectedChild!['id']}');
    
    try {
      final res = await http.put(
        url,
        headers: {'Authorization': 'Bearer ${token!}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'isEnabled': true,
          'amount': double.tryParse(_amountController.text) ?? 0,
          'savingRatio': _savePercentage, 
          'frequency': _frequency,
          'dayOfWeek': _selectedDayOfWeek,
          'dayOfMonth': _selectedDayOfMonth,
          'timeOfDay': timeStr,
        }),
      );

      if (!mounted) return; // حماية لمنع الأخطاء إذا تغيرت الشاشة

      if (res.statusCode >= 200 && res.statusCode <= 299) {
        
        // تحديث بيانات الطفل محلياً لتظهر شارة "نشط" فوراً
        final index = _children.indexWhere((c) => c['id'] == _selectedChild!['id']);
        if (index != -1) {
          _children[index]['hasAllowance'] = true;
          _children[index]['amount'] = double.tryParse(_amountController.text) ?? 0;
          _children[index]['frequency'] = _frequency;
          _children[index]['dayOfWeek'] = _selectedDayOfWeek;
          _children[index]['dayOfMonth'] = _selectedDayOfMonth;
          _children[index]['timeOfDay'] = timeStr;
        }

        // عرض رسالة النجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allowanceSavedSuccess), backgroundColor: hassalaGreen)
        );
        
        // العودة للخطوة الأولى بسلاسة 
        setState(() {
          _currentStep = 0;
        });
        _pageController.animateToPage(
          0, 
          duration: const Duration(milliseconds: 400), 
          curve: Curves.easeInOut,
        );

      } else {
        _showError(l10n.saveFailed(res.statusCode));
      }
    } catch (e) {
      if (!mounted) return;
      _showError(l10n.somethingWentWrongGeneric);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
    );
  }

  void _nextPage() {
    if (_currentStep == 0 && _selectedChild == null) {
      _showError(AppLocalizations.of(context)!.pleaseSelectChildFirst);
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // دالة مساعدة لترجمة الأيام بناءً على ملف الـ L10n
  String _getTranslatedDay(String dayEn, AppLocalizations l10n) {
    switch(dayEn) {
      case 'Sunday': return l10n.sunday;
      case 'Monday': return l10n.monday;
      case 'Tuesday': return l10n.tuesday;
      case 'Wednesday': return l10n.wednesday;
      case 'Thursday': return l10n.thursday;
      case 'Friday': return l10n.friday;
      case 'Saturday': return l10n.saturday;
      default: return dayEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.allowanceSetupTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: secondaryDark,
        leading: _currentStep > 0 ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
        ) : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _stepSelectChild(l10n),
                  _stepAmountAndSplit(l10n),
                  _stepSchedule(l10n),
                ],
              ),
            ),
            _buildBottomNav(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          bool isDone = index < _currentStep;
          bool isCurrent = index == _currentStep;
          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent || isDone ? hassalaGreen : Colors.grey.shade300,
                  boxShadow: isCurrent ? [BoxShadow(color: hassalaGreen.withOpacity(0.3), blurRadius: 6)] : [],
                ),
                child: Center(
                  child: isDone 
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              if (index < 2) Container(width: 30, height: 2, color: index < _currentStep ? hassalaGreen : Colors.grey.shade300),
            ],
          );
        }),
      ),
    );
  }

  // الخطوة الأولى: اختيار الطفل
  Widget _stepSelectChild(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.selectChildTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: secondaryDark)),
          const SizedBox(height: 8),
          Text(l10n.allowanceSetupSubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 25),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.95,
            ),
            itemCount: _children.length,
            itemBuilder: (context, idx) {
              final child = _children[idx];
              final isSelected = _selectedChild?['id'] == child['id'];
              final bool hasAllowance = child['hasAllowance'] ?? false;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedChild = child;
                  _savePercentage = child['ratio'] ?? 0.0;
                  
                  // سحب البيانات القديمة لتعبئتها تلقائياً (التعديل)
                  if (child['amount'] > 0) {
                    _amountController.text = child['amount'].toStringAsFixed(0);
                  } else {
                    _amountController.text = "100";
                  }
                  
                  _frequency = child['frequency'] ?? 'Weekly';
                  _selectedDayOfWeek = child['dayOfWeek'] ?? 'Sunday';
                  _selectedDayOfMonth = child['dayOfMonth'] ?? 1;
                  
                  final parts = (child['timeOfDay'] ?? '08:00').split(':');
                  if (parts.length >= 2) {
                    _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                  }
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? hassalaGreen : Colors.transparent, width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: isSelected ? hassalaGreen.withOpacity(0.1) : Colors.grey.shade100,
                            child: Icon(Icons.face_rounded, size: 40, color: isSelected ? hassalaGreen : Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Text(child['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                    
                    // مؤشر "نشط" أعلى بطاقة الطفل
                    if (hasAllowance)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: hassalaGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: hassalaGreen),
                              const SizedBox(width: 4),
                              Text(l10n.active, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hassalaGreen)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // الخطوة الثانية: تحديد المبلغ وتقسيم الادخار
  Widget _stepAmountAndSplit(AppLocalizations l10n) {
    double total = double.tryParse(_amountController.text) ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weeklyAmountLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    suffixText: l10n.currencySarLabel,
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _infoBox(l10n.spend, total * (1 - _savePercentage), hassalaGreen, Icons.shopping_bag_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _infoBox(l10n.save, total * _savePercentage, const Color(0xFF7E57C2), Icons.account_balance_wallet_outlined)),
            ],
          ),
          const SizedBox(height: 25),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: hassalaGreen,
              thumbColor: hassalaGreen,
              overlayColor: hassalaGreen.withOpacity(0.1),
            ),
            child: Slider(
              value: _savePercentage,
              divisions: 10,
              label: "${(_savePercentage * 100).toInt()}%",
              onChanged: (v) => setState(() => _savePercentage = v),
            ),
          ),
          Text(l10n.allowanceSliderInstruction, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // الخطوة الثالثة: الجدولة (التكرار والوقت)
  Widget _stepSchedule(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.whenToTransfer, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: secondaryDark)),
          const SizedBox(height: 20),
          _selectorTile(
            title: l10n.frequency,
            value: _frequency == 'Weekly' ? l10n.weekly : l10n.monthly,
            icon: Icons.sync_rounded,
            onTap: () => _showFrequencyPicker(l10n),
          ),
          _selectorTile(
            title: _frequency == 'Weekly' ? l10n.day : l10n.dayOfMonth,
            value: _frequency == 'Weekly' ? _getTranslatedDay(_selectedDayOfWeek, l10n) : "${l10n.day} $_selectedDayOfMonth",
            icon: Icons.calendar_today_rounded,
            onTap: () => _showDayPicker(l10n),
          ),
          _selectorTile(
            title: l10n.time,
            value: _selectedTime.format(context),
            icon: Icons.access_time_filled_rounded,
            onTap: () => _pickTime(),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, double val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15))
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(val.toStringAsFixed(0), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _selectorTile({required String title, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: hassalaGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: hassalaGreen, size: 20),
            ),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hassalaGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: _currentStep == 2 ? _saveSettings : _nextPage,
          child: Text(
            _currentStep == 2 ? l10n.saveSettings : l10n.continue_,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // الاختيارات (Pickers)
  void _showFrequencyPicker(AppLocalizations l10n) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        ListTile(title: Text(l10n.weekly), leading: const Icon(Icons.calendar_view_week), onTap: () { setState(() => _frequency = 'Weekly'); Navigator.pop(ctx); }),
        ListTile(title: Text(l10n.monthly), leading: const Icon(Icons.calendar_view_month), onTap: () { setState(() => _frequency = 'Monthly'); Navigator.pop(ctx); }),
        const SizedBox(height: 15),
      ],
    ));
  }

  void _showDayPicker(AppLocalizations l10n) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => SizedBox(
      height: 350,
      child: ListView.builder(
        itemCount: _frequency == 'Weekly' ? 7 : 31,
        itemBuilder: (c, i) => ListTile(
          title: Text(_frequency == 'Weekly' ? _getTranslatedDay(days[i], l10n) : "${l10n.day} ${i+1}"),
          trailing: const Icon(Icons.check_circle_outline, size: 18),
          onTap: () {
            setState(() {
              if (_frequency == 'Weekly') _selectedDayOfWeek = days[i];
              else _selectedDayOfMonth = i + 1;
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    ));
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: hassalaGreen)), child: child!),
    );
    if (time != null) setState(() => _selectedTime = time);
  }
}