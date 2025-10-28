import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pinCtrl = TextEditingController();
  final FocusNode _pinFocus = FocusNode();

  bool _isLoading = false;
  late String phoneNo = '';

  Color get _brandTeal => const Color(0xFF37C4BE); 
  Color get _bgTop => const Color(0xFFF7F8FA);    
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    phoneNo = (args?['phoneNo'] ?? '').toString();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  bool get _pinValid => _pinCtrl.text.trim().length == 4;

  Future<void> _loginChild() async {
    if (!_pinValid || _isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('http://10.0.2.2:3000/api/auth/login-child');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNo': phoneNo.trim(),
          'PIN': _pinCtrl.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login successful!')),
        );
        Navigator.pushNamed(context, '/childHome');
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
 
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, Colors.white],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Spacer(),
                  // Logo
                  Image.asset(
                    'assets/logo/hassalaLogo2.png',
                    width: 350,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Enter Your PIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                
                  GestureDetector(
                    onTap: () => FocusScope.of(context).requestFocus(_pinFocus),
                    child: _PinBoxes(pinText: _pinCtrl.text),
                  ),

                  // PIN
                  Offstage(
                    offstage: false,
                    child: SizedBox(
                      height: 0,
                      width: 0,
                      child: TextFormField(
                        controller: _pinCtrl,
                        focusNode: _pinFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscureText: true,
                        obscuringCharacter: '•',
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Enter your PIN';
                          if (t.length != 4) return 'PIN must be 4 digits';
                          return null;
                        },
                        enableInteractiveSelection: false,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_pinValid && !_isLoading)
                            ? _loginChild
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandTeal,
                          disabledBackgroundColor:
                              _brandTeal.withOpacity(0.35),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinBoxes extends StatelessWidget {
  final String pinText;
  const _PinBoxes({required this.pinText});

  @override
  Widget build(BuildContext context) {
    final chars = pinText.characters.toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final hasChar = i < chars.length;
        return Container(
          width: 54,
          height: 54,
          margin: EdgeInsets.only(right: i == 3 ? 0 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(0, 2),
                color: Color(0x14000000), 
              ),
            ],
            border: Border.all(
              color: hasChar ? const Color(0xFFE0E0E0) : const Color(0xFFEAEAEA),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            hasChar ? '•' : '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        );
      }),
    );
  }
}
