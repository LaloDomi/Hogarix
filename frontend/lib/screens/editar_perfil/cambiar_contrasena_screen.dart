import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/auth/recuperar_contrasena_screen.dart';
import 'package:manocerca/screens/auth/widgets/auth_widgets.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';
import 'package:manocerca/screens/editar_perfil/agregar_correo_screen.dart';
import 'package:provider/provider.dart';

/// Cambiar la contraseña con la sesión iniciada (pide la actual).
/// Si no la recuerda (o entró con Gmail y nunca tuvo una), puede crear una
/// nueva con un código enviado a su correo.
class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await context
        .read<AuthProvider>()
        .cambiarContrasena(actual: _actual.text, nueva: _nueva.text);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _guardando = false;
      _error = error;
    });
  }

  void _noLaRecuerdo(String correo) {
    final pantalla = correo.isEmpty
        ? const AgregarCorreoScreen()
        : RecuperarContrasenaScreen(correoInicial: correo);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final correo = context.select<AuthProvider, String>((a) => a.usuario?.correo ?? '');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampoContrasena(
                  controller: _actual,
                  hint: 'Contraseña actual',
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña actual' : null,
                ),
                const SizedBox(height: 14),
                CampoContrasena(
                  controller: _nueva,
                  hint: 'Contraseña nueva (mínimo 6 caracteres)',
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: validarContrasenaNueva,
                ),
                const SizedBox(height: 14),
                CampoContrasena(
                  controller: _confirmar,
                  hint: 'Repite la contraseña nueva',
                  validator: (v) => v != _nueva.text ? 'Las contraseñas no coinciden' : null,
                  onFieldSubmitted: (_) => _guardar(),
                ),
                TextoError(_error),
                const SizedBox(height: 22),
                BotonOCarga(
                  cargando: _guardando,
                  boton: PrimaryButton(text: 'Guardar contraseña', onTap: _guardar),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _guardando ? null : () => _noLaRecuerdo(correo),
                    child: Text(
                      correo.isEmpty
                          ? '¿No la recuerdas? Agrega un correo para recuperarla'
                          : '¿No la recuerdas? Te enviamos un código a tu correo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: C.light, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
