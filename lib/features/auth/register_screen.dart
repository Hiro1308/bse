import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repos/auth_repo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _repo = AuthRepo();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.signUp(_name.text, _email.text, _pass.text);
      if (mounted) context.go('/groups');
    } catch (e) {
      setState(() => _error = _humanizeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _humanizeAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user already registered') || msg.contains('already registered')) {
      return 'Ese email ya tiene cuenta';
    }
    if (msg.contains('password should be at least')) return 'La contraseña es muy corta';
    if (msg.contains('invalid email')) return 'Email inválido';
    if (msg.contains('network') || msg.contains('socket')) return 'Problema de conexión';
    return 'No se pudo crear la cuenta';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Empecemos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Creá una cuenta para armar grupos y cargar gastos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Ingresá tu nombre';
                      if (s.length < 2) return 'Nombre muy corto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Ingresá tu email';
                      if (!s.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Mínimo 6 caracteres',
                    ),
                    validator: (v) {
                      final s = (v ?? '');
                      if (s.isEmpty) return 'Ingresá una contraseña';
                      if (s.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                    onFieldSubmitted: (_) => _register(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear cuenta'),
              ),
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => context.go('/login'),
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
