import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/auth/widgets/auth_widgets.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';
import 'package:provider/provider.dart';

/// "¿Olvidaste tu contraseña?": 1) correo  2) código + contraseña nueva.
/// Al terminar, la sesión queda iniciada.
class RecuperarContrasenaScreen extends StatefulWidget {
  final String? correoInicial;
  const RecuperarContrasenaScreen({super.key, this.correoInicial});

  @override
  State<RecuperarContrasenaScreen> createState() => _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formCorreo = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  late final TextEditingController _correo;
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();

  bool _codigoEnviado = false;
  bool _enviando = false;
  String? _aviso;
  String? _errorEnvio;

  @override
  void initState() {
    super.initState();
    _correo = TextEditingController(text: widget.correoInicial ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().limpiarError();
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  String get _correoLimpio => _correo.text.trim().toLowerCase();

  /// Devuelve true si se envió.
  Future<bool> _pedirCodigo() async {
    setState(() {
      _enviando = true;
      _errorEnvio = null;
    });
    final r = await context
        .read<AuthProvider>()
        .enviarCodigo(correo: _correoLimpio, proposito: 'restablecer');
    if (!mounted) return false;
    setState(() {
      _enviando = false;
      if (r.ok) {
        _codigoEnviado = true;
        _aviso = r.mensaje;
      } else {
        _errorEnvio = r.mensaje;
      }
    });
    return r.ok;
  }

  Future<void> _enviarCorreo() async {
    if (!_formCorreo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _pedirCodigo();
  }

  Future<void> _cambiar() async {
    if (!_formCodigo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final yaHabiaSesion = auth.autenticado;
    // Sin sesión: si sale bien, AuthGate cierra esta pantalla y abre la app.
    final ok = await auth.restablecerContrasena(
      correo: _correoLimpio,
      codigo: _codigo.text.trim(),
      contrasena: _contrasena.text,
    );
    // Con sesión (desde "Cambiar contraseña"): se cierra y se avisa.
    if (ok && yaHabiaSesion && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
      Navigator.of(context).pop();
    }
  }

  Widget _pasoCorreo() {
    return Form(
      key: _formCorreo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Olvidaste tu contraseña?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              'Escribe el correo de tu cuenta y te enviaremos un código para crear una contraseña nueva.',
              style: TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: inputDeco('Correo electrónico',
                prefix: const Icon(Icons.mail_outline, color: C.muted)),
            validator: validarCorreo,
            onFieldSubmitted: (_) => _enviarCorreo(),
          ),
          TextoError(_errorEnvio),
          const SizedBox(height: 22),
          BotonOCarga(
            cargando: _enviando,
            boton: PrimaryButton(text: 'Enviar código', onTap: _enviarCorreo),
          ),
          const SizedBox(height: 18),
          const Text(
            'La recuperación funciona con el correo de tu cuenta. Si te registraste solo con '
            'tu teléfono, agrega un correo desde "Editar perfil" para poder recuperarla.',
            style: TextStyle(color: C.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _pasoCodigo(AuthProvider auth) {
    return Form(
      key: _formCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crea tu contraseña nueva',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_aviso ?? 'Te enviamos un código a $_correoLimpio.',
              style: const TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
          const SizedBox(height: 22),
          CampoCodigo(controller: _codigo),
          const SizedBox(height: 14),
          CampoContrasena(
            controller: _contrasena,
            hint: 'Contraseña nueva (mínimo 6 caracteres)',
            autofillHints: const [AutofillHints.newPassword],
            validator: validarContrasenaNueva,
          ),
          const SizedBox(height: 14),
          CampoContrasena(
            controller: _confirmar,
            hint: 'Repite la contraseña nueva',
            validator: (v) => v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
            onFieldSubmitted: (_) => _cambiar(),
          ),
          TextoError(auth.error ?? _errorEnvio),
          const SizedBox(height: 22),
          BotonOCarga(
            cargando: auth.cargando,
            boton: PrimaryButton(text: 'Cambiar contraseña', onTap: _cambiar),
          ),
          const SizedBox(height: 8),
          Center(child: ReenviarCodigo(onReenviar: _pedirCodigo)),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _codigoEnviado = false;
                _codigo.clear();
                context.read<AuthProvider>().limpiarError();
              }),
              child: const Text('Usar otro correo', style: TextStyle(color: C.muted)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restablecer contraseña',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _codigoEnviado ? _pasoCodigo(auth) : _pasoCorreo(),
        ),
      ),
    );
  }
}
