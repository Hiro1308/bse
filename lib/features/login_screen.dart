import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repos/auth_repo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repo = AuthRepo();

  final _email = TextEditingController();
  final _pass = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.signIn(_email.text, _pass.text);
      if (mounted) context.go('/groups');
    } catch (e) {
      setState(() => _error = _humanizeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _humanizeAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials')) return 'Email o contraseña incorrectos';
    if (msg.contains('email not confirmed')) return 'Confirmá tu email antes de ingresar';
    if (msg.contains('network') || msg.contains('socket')) return 'Problema de conexión';
    return 'No se pudo ingresar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Bienvenido',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresá para ver tus grupos y gastos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
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
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      final s = (v ?? '');
                      if (s.isEmpty) return 'Ingresá tu contraseña';
                      if (s.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
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
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => context.go('/register'),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
