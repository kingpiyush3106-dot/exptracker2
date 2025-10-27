import 'package:flutter/material.dart';
import '../auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  bool _loading = false;

  void _showSnack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(email: _emailCtl.text.trim());
      _showSnack('Password reset email sent. Check your inbox.');
      if (mounted) Navigator.pop(context); // return to login
    } on Exception catch (e) {
      _showSnack('Failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    super.dispose();
  }

  Widget _topDecor(Size size) {
    return SizedBox(
      height: size.height * 0.28,
      child: Stack(
        children: [
          Positioned(
            left: -size.width * 0.25,
            top: -size.width * 0.18,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B3BFF), Color(0xFF2AD2F5)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -size.width * 0.18,
            top: -size.width * 0.25,
            child: Container(
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF19B8FF),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 4),
                Text(
                  'Why you forgot?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Size size) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the email associated with your account and we\'ll send a reset link.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendReset,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send reset link'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _topDecor(size),
            _card(size),
            const SizedBox(height: 40),
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    bottom: 0,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF19B8FF),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    bottom: 0,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFB84D), Color(0xFFF99E2A)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
