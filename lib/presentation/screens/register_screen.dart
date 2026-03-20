import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huellitas_a_casa/core/theme/app_colors.dart';
import 'package:huellitas_a_casa/presentation/providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          if (mounted) Navigator.of(context).pop();
        },
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _aliasCtrl,
                decoration: const InputDecoration(labelText: 'Alias'),
                validator: (value) =>
                    value != null && value.trim().isNotEmpty ? null : 'Alias requerido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (value) =>
                    value != null && value.contains('@') ? null : 'Correo inválido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) =>
                    value != null && value.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                title: const Text(
                  'Acepto los Términos de Servicio y la Política de Privacidad',
                  style: TextStyle(color: AppColors.bodyText),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() != true) return;
                          if (!_acceptedTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.critical,
                                content: Text(
                                  'Debes aceptar Términos y Política antes de registrarte.',
                                ),
                              ),
                            );
                            return;
                          }
                          await ref.read(authControllerProvider.notifier).signUp(
                                email: _emailCtrl.text.trim(),
                                password: _passwordCtrl.text.trim(),
                                alias: _aliasCtrl.text.trim(),
                              );
                        },
                  child: state.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
