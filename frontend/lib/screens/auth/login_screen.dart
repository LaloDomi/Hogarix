import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/auth/acceso_correo_screen.dart';
import 'package:manocerca/screens/auth/recuperar_contrasena_screen.dart';
import 'package:manocerca/screens/auth/register_screen.dart';
import 'package:manocerca/screens/auth/widgets/auth_widgets.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().limpiarError();
    });
  }

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  /// El backend recibe el teléfono ya limpio (10 dígitos).
  String get _identificador {
    final t = _usuario.text.trim();
    return t.contains('@') ? t : (normalizarTelefono(t) ?? t);
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Si el login funciona, AuthGate reemplaza esta pantalla por la app.
    await context.read<AuthProvider>().login(
          usuario: _identificador,
          contrasena: _contrasena.text,
        );
  }

  void _ir(Widget pantalla, {bool reemplazar = false}) {
    final ruta = MaterialPageRoute(builder: (_) => pantalla);
    reemplazar
        ? Navigator.of(context).pushReplacement(ruta)
        : Navigator.of(context).push(ruta);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final escrito = _usuario.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Bienvenido de nuevo',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Ingresa con tu correo o tu número de teléfono.',
                      style: TextStyle(color: C.muted, fontSize: 15)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _usuario,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                    decoration: inputDeco('Correo o teléfono',
                        prefix: const Icon(Icons.person_outline, color: C.muted)),
                    validator: validarCorreoOTelefono,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  CampoContrasena(
                    controller: _contrasena,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => (v ?? '').isEmpty ? 'Ingresa tu contraseña' : null,
                    onFieldSubmitted: (_) => _enviar(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _ir(RecuperarContrasenaScreen(
                          correoInicial: escrito.contains('@') ? escrito : null)),
                      child: const Text('¿Olvidaste tu contraseña?',
                          style: TextStyle(color: C.light, fontSize: 14)),
                    ),
                  ),
                  TextoError(auth.error),
                  const SizedBox(height: 14),
                  BotonOCarga(
                    cargando: auth.cargando,
                    boton: PrimaryButton(text: 'Iniciar sesión', onTap: _enviar),
                  ),
                  const SeparadorO(),
                  OutlineButtonX(
                    text: 'Continuar con Gmail',
                    icon: Icons.mail_outline,
                    onTap: () => _ir(const AccesoCorreoScreen()),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Te enviamos un código a tu correo, sin contraseña.',
                        style: TextStyle(color: C.muted, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => _ir(const RegisterScreen(), reemplazar: true),
                      child: const Text(
                        '¿No tienes cuenta? Crea una',
                        style: TextStyle(
                          color: C.light,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
