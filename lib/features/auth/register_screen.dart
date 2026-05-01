import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  ProviderSubscription<AsyncValue<Session?>>? _sub;

  @override
  void initState() {
    super.initState();

    _sub = ref.listenManual<AsyncValue<Session?>>(
      authProvider,
      (prev, next) {
        next.whenOrNull(
          data: (session) {
            // Si Supabase devuelve sesión, el router también te llevará a '/'
            if (session != null && mounted) context.go('/');
          },
          error: (e, _) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
            );
          },
        );
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _sub?.close();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
          _email.text.trim(),
          _pass.text,
        );

    // Si tu Supabase tiene "Confirm email" activado, puede que no haya sesión.
    // En ese caso el router no te redirige. Muestra mensaje:
    final session = ref.read(authProvider).valueOrNull;
    if (session == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Revisa tu correo para confirmar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded, size: 36, color: cs.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu cuenta para empezar a gestionar citas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Requerido';
                        if (!t.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) {
                        final t = v ?? '';
                        if (t.isEmpty) return 'Requerido';
                        if (t.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: Text(auth.isLoading ? 'Creando…' : 'Registrarme'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: auth.isLoading ? null : () => context.go('/login'),
                      child: const Text('Ya tengo cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}