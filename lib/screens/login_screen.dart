import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _hidePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    if (!RegExp(r'^.+@.+\..+$').hasMatch(value)) return 'Neispravan email';
    return null;
  }

  String? _password(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Obavezno polje';
    if (value.length < 6) return 'Lozinka mora imati bar 6 karaktera';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Dobrodošao nazad',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Prijavi se kako bi mogao da kupuješ karte, vidiš kupovine i koristiš wishlist.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _hidePass,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Lozinka',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                    icon: Icon(
                      _hidePass ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: _password,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = _formKey.currentState?.validate() ?? false;
                    if (!ok) return;

                    try {
                      await context.read<AuthProvider>().login(
                            email: _emailCtrl.text.trim(),
                            password: _passCtrl.text,
                          );
                      if (!context.mounted) return;
                      context.read<NavigationProvider>().reset();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login nije uspeo: $e')),
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('Nemam nalog — Registruj se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
