import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huellitas_a_casa/presentation/providers/app_providers.dart';
import 'package:huellitas_a_casa/presentation/screens/home_shell.dart';
import 'package:huellitas_a_casa/presentation/screens/login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user == null ? const LoginScreen() : const HomeShell(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error de autenticación: $error')),
      ),
    );
  }
}
