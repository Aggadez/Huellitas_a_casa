import 'package:flutter/material.dart';
import 'package:huellitas_a_casa/core/theme/app_theme.dart';
import 'package:huellitas_a_casa/presentation/screens/auth_gate.dart';

class HuellitasApp extends StatelessWidget {
  const HuellitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Huellitas a casa',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
