import 'package:flutter/material.dart';
import '../services/goals_api.dart';

class ChildAddGoalScreen extends StatefulWidget {
  const ChildAddGoalScreen({super.key});

  @override
  State<ChildAddGoalScreen> createState() => _ChildAddGoalScreenState();
}

class _ChildAddGoalScreenState extends State<ChildAddGoalScreen> {
  // 🎨 Colors
  static const kBg = Color(0xFFF7F8FA);
  static const kCard = Color(0xFF9FE5E2);
  static const kAddBtn = Color(0xFF75C6C3);
  static const kTextSecondary = Color(0xFF6E6E6E);

  // --- Form state ---
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _submitting = false;

  // --- API wiring ---
  late int _childId;
  late GoalsApi _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _childId = (args['childId'] ?? 0) as int;

    final baseUrl = (args['baseUrl'] ?? 'http://10.0.2.2:3000') as String;
    _api = GoalsApi(baseUrl);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // Submit goal
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final name = _nameCtrl.text.trim();
      final amount = double.parse(_amountCtrl.text.trim());

      await _api.createGoal(
        childId: _childId,
        goalName: name,
        targetAmount: amount,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create goal: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // App Bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Goals',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.black87),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),

      // Body
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _GoalFormCard(
                      nameCtrl: _nameCtrl,
                      amountCtrl: _amountCtrl,
                      formKey: _formKey,
                      submitting: _submitting,
                      onSubmit: _onSubmit,
                      onCancel: () => Navigator.pop(context, false),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kAddBtn,
        unselectedItemColor: const Color(0xFFAAAAAA),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
        ],
      ),
    );
  }
}

class _GoalFormCard extends StatelessWidget {
  const _GoalFormCard({
    required this.nameCtrl,
    required this.amountCtrl,
    required this.formKey,
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final GlobalKey<FormState> formKey;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  static const kCard = Color(0xFF9FE5E2);
  static const kAddBtn = Color(0xFF75C6C3);
  static const kTextSecondary = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Create a new goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
              ),

              // Goal name
              const Text(
                'Goal name',
                style: TextStyle(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _inputField(
                controller: nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter goal name' : null,
              ),

              const SizedBox(height: 22),

              // Amount
              const Text(
                'Amount of money need to save',
                style: TextStyle(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _inputField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter target amount';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Invalid amount';
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _flatPillButton(
                    submitting ? 'Saving...' : 'Add',
                    bg: kAddBtn,
                    textColor: Colors.black,
                    onTap: submitting ? null : onSubmit,
                    loading: submitting,
                  ),
                  const SizedBox(width: 16),
                  _flatPillButton(
                    'Cancel',
                    bg: Colors.white,
                    textColor: Colors.black,
                    onTap: submitting ? null : onCancel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Inputs
  static Widget _inputField({
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Buttons
  static Widget _flatPillButton(
    String text, {
    required Color bg,
    required Color textColor,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 120,
        height: 44,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
        child: Center(
          child: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
    );
  }
}
