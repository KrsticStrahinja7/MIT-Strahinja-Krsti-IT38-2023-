import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirmPass = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Obavezno polje';
    return null;
  }

  String? _email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    if (!RegExp(r'^.+@.+\..+$').hasMatch(value)) return 'Neispravan email';
    return null;
  }

  String? _phone(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    final digits = value.replaceAll(RegExp(r'\D+'), '');
    if (digits.length < 8) return 'Neispravan telefon';
    return null;
  }

  String? _password(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Obavezno polje';
    if (value.length < 6) return 'Lozinka mora imati bar 6 karaktera';
    return null;
  }

  String? _confirmPassword(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Obavezno polje';
    if (value != _passCtrl.text) return 'Lozinke se ne poklapaju';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Kreiraj nalog',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Unesi podatke za regitraciju.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Ime',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Prezime',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _hidePass,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _hideConfirmPass,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Potvrdi lozinku',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hideConfirmPass = !_hideConfirmPass),
                    icon: Icon(
                      _hideConfirmPass
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: _confirmPassword,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final ok = _formKey.currentState?.validate() ?? false;
                    if (!ok) return;

                    context.read<AuthProvider>().register(
                          firstName: _firstNameCtrl.text.trim(),
                          lastName: _lastNameCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                        );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Kreiraj nalog'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Imam nalog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
