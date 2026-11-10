import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/auth/widgets/auth_widgets.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';
import 'package:provider/provider.dart';

/// Agrega o cambia el correo de la cuenta comprobándolo con un código.
/// Sirve sobre todo a quien se registró con teléfono: con correo ya puede
/// recuperar su contraseña. Devuelve `true` si guardó el correo.
class AgregarCorreoScreen extends StatefulWidget {
  const AgregarCorreoScreen({super.key});

  @override
  State<AgregarCorreoScreen> createState() => _AgregarCorreoScreenState();
}

class _AgregarCorreoScreenState extends State<AgregarCorreoScreen> {
  final _formCorreo = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _codigo = TextEditingController();

  bool _codigoEnviado = false;
  bool _cargando = false;
  String? _aviso;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    super.dispose();
  }

  String get _correoLimpio => _correo.text.trim().toLowerCase();

  Future<bool> _pedirCodigo() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final r = await context
        .read<AuthProvider>()
        .enviarCodigo(correo: _correoLimpio, proposito: 'acceso');
    if (!mounted) return false;
    setState(() {
      _cargando = false;
      if (r.ok) {
        _codigoEnviado = true;
        _aviso = r.mensaje;
      } else {
        _error = r.mensaje;
      }
    });
    return r.ok;
  }

  Future<void> _enviarCorreo() async {
    if (!_formCorreo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _pedirCodigo();
  }

  Future<void> _guardar() async {
    if (!_formCodigo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await context
        .read<AuthProvider>()
        .cambiarCorreo(correo: _correoLimpio, codigo: _codigo.text.trim());
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Correo guardado.')));
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _cargando = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final actual = context.watch<AuthProvider>().usuario?.correo ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(actual.isEmpty ? 'Agregar correo' : 'Cambiar correo',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _codigoEnviado
              ? Form(
                  key: _formCodigo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_aviso ?? 'Te enviamos un código a $_correoLimpio.',
                          style: const TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
                      const SizedBox(height: 20),
                      CampoCodigo(controller: _codigo, onFieldSubmitted: (_) => _guardar()),
                      TextoError(_error),
                      const SizedBox(height: 22),
                      BotonOCarga(
                        cargando: _cargando,
                        boton: PrimaryButton(text: 'Guardar correo', onTap: _guardar),
                      ),
                      const SizedBox(height: 8),
                      Center(child: ReenviarCodigo(onReenviar: _pedirCodigo)),
                    ],
                  ),
                )
              : Form(
                  key: _formCorreo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (actual.isNotEmpty) ...[
                        Text('Correo actual: $actual',
                            style: const TextStyle(color: C.muted, fontSize: 14)),
                        const SizedBox(height: 14),
                      ],
                      const Text(
                          'Te enviaremos un código para comprobar que el correo es tuyo. '
                          'Con él podrás recuperar tu contraseña y entrar sin contraseña.',
                          style: TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _correo,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: inputDeco('Correo nuevo',
                            prefix: const Icon(Icons.mail_outline, color: C.muted)),
                        validator: validarCorreo,
                        onFieldSubmitted: (_) => _enviarCorreo(),
                      ),
                      TextoError(_error),
                      const SizedBox(height: 22),
                      BotonOCarga(
                        cargando: _cargando,
                        boton: PrimaryButton(text: 'Enviar código', onTap: _enviarCorreo),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
