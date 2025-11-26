import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/goals_api.dart';
import 'package:my_app/utils/check_auth.dart';

class ChildAddGoalScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildAddGoalScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildAddGoalScreen> createState() => _ChildAddGoalScreenState();
}

class _ChildAddGoalScreenState extends State<ChildAddGoalScreen> {
  static const kBg = Color(0xFFF7F8FA);
  static const kCard = Color(0xFF9FE5E2);
  static const kAddBtn = Color(0xFF75C6C3);
  static const kTextSecondary = Color(0xFF6E6E6E);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _submitting = false;
  late final GoalsApi _api;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _api = GoalsApi(widget.baseUrl, widget.token);
  }

  Future<void> _checkAuth() async {
    await checkAuthStatus(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _lettersOnly(String v) {
    final t = v.trim();
    if (t.isEmpty) return false;
    return RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(t);
  }

  bool _amountOnly(String v) {
    final t = v.trim();
    return RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t);
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final name = _nameCtrl.text.trim();
      final amount = double.parse(_amountCtrl.text.trim());
      final description = _descCtrl.text.trim();

      await _api.createGoal(
        childId: widget.childId,
        goalName: name,
        targetAmount: amount,
        description: description,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (e.toString().contains("401")) {
        await checkAuthStatus(context);
        return;
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const Spacer(),
                  const Text(
                    'Add Goal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    'Create a new goal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),

                              const Text(
                                'Goal name',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _field(
                                controller: _nameCtrl,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'[0-9]'),
                                  ),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Enter goal name';
                                  if (!_lettersOnly(v)) return 'Letters only';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _field(
                                controller: _descCtrl,
                                maxLines: 3,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'[0-9]'),
                                  ),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return null;
                                  if (!_lettersOnly(v)) return 'Letters only';
                                  if (v.trim().length > 200)
                                    return 'Max 200 characters';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                'Amount to save',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _field(
                                controller: _amountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Enter amount';
                                  if (!_amountOnly(v)) return 'Numbers only';
                                  final d = double.tryParse(v.trim());
                                  if (d == null || d <= 0)
                                    return 'Invalid amount';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 28),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _pill(
                                    text: _submitting ? 'Saving...' : 'Add',
                                    bg: kAddBtn,
                                    onTap: _submitting ? null : _onSubmit,
                                    loading: _submitting,
                                  ),
                                  const SizedBox(width: 16),
                                  _pill(
                                    text: 'Cancel',
                                    bg: Colors.white,
                                    onTap: _submitting
                                        ? null
                                        : () => Navigator.pop(context, false),
                                  ),
                                ],
                              ),
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
        },
      ),
    );
  }

  static Widget _field({
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget _pill({
    required String text,
    required Color bg,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: disabled ? 0.6 : 1,
        child: Container(
          width: 120,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
