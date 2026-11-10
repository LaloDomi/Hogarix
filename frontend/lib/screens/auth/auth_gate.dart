import 'package:flutter/material.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/main_shell/main_shell.dart';
import 'package:manocerca/screens/welcome/welcome_screen.dart';
import 'package:provider/provider.dart';

/// Muestra la app si hay sesión y la bienvenida si no. Al cambiar el estado
/// de la sesión cierra cualquier pantalla abierta encima (login, registro,
/// chats...) para que no queden huérfanas.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final autenticado =
        context.select<AuthProvider, bool>((auth) => auth.autenticado);
    final restaurando =
        context.select<AuthProvider, bool>((auth) => auth.restaurando);

    // Mientras se revisa la sesión guardada.
    if (restaurando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).popUntil((ruta) => ruta.isFirst);
      }
    });

    return autenticado ? const MainShell() : const WelcomeScreen();
  }
}
