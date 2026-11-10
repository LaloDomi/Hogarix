import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/auth/login_screen.dart';
import 'package:manocerca/screens/auth/register_screen.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _check(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: C.light, size: 24),
            const SizedBox(width: 14),
            Text(text, style: const TextStyle(color: C.muted, fontSize: 15)),
          ],
        ),
      );

  void _ir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final aviso = context.watch<AuthProvider>().error;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E2348), C.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset('assets/img/logo.png', width: 120, height: 120, fit: BoxFit.contain,),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Oficio', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'Link', style: TextStyle(color: C.light)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profesionales para\nhacer tu vida más fácil',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.muted, fontSize: 17, height: 1.4),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _check(Icons.check_circle, 'Personas verificadas'),
                        _check(Icons.verified_user, 'Servicios de confianza'),
                        _check(Icons.bolt, 'Rápido y seguro'),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                if (aviso != null) ...[
                  Text(aviso,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                    text: 'Iniciar sesión',
                    onTap: () => _ir(context, const LoginScreen())),
                const SizedBox(height: 14),
                OutlineButtonX(
                    text: 'Crear cuenta',
                    onTap: () => _ir(context, const RegisterScreen())),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
