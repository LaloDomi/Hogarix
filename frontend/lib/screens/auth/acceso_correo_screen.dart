import 'package:flutter/material.dart';
import 'package:manocerca/core/models/usuario.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/auth/widgets/auth_widgets.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';
import 'package:provider/provider.dart';

enum _Paso { correo, codigo, datos }

/// "Continuar con Gmail": entra o crea la cuenta con un código que llega al
/// correo. Funciona con Gmail o cualquier correo y no necesita Google Cloud.
/// 1) correo  2) código  3) solo si es cuenta nueva: rol, nombre y apellido.
class AccesoCorreoScreen extends StatefulWidget {
  const AccesoCorreoScreen({super.key});

  @override
  State<AccesoCorreoScreen> createState() => _AccesoCorreoScreenState();
}

class _AccesoCorreoScreenState extends State<AccesoCorreoScreen> {
  final _formCorreo = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  final _formDatos = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();

  _Paso _paso = _Paso.correo;
  int _idRol = Roles.cliente;
  bool _enviando = false;
  String? _aviso;
  String? _errorEnvio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().limpiarError();
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    _nombre.dispose();
    _apellido.dispose();
    super.dispose();
  }

  String get _correoLimpio => _correo.text.trim().toLowerCase();

  Future<bool> _pedirCodigo() async {
    setState(() {
      _enviando = true;
      _errorEnvio = null;
    });
    final r = await context
        .read<AuthProvider>()
        .enviarCodigo(correo: _correoLimpio, proposito: 'acceso');
    if (!mounted) return false;
    setState(() {
      _enviando = false;
      if (r.ok) {
        _paso = _Paso.codigo;
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

  Future<void> _verificar() async {
    if (!_formCodigo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final r = await context.read<AuthProvider>().accederConCodigo(
          correo: _correoLimpio,
          codigo: _codigo.text.trim(),
        );
    // entro: AuthGate abre la app. faltanDatos: es una cuenta nueva.
    if (r == ResultadoAcceso.faltanDatos && mounted) {
      setState(() => _paso = _Paso.datos);
    }
  }

  Future<void> _crearCuenta() async {
    if (!_formDatos.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthProvider>().accederConCodigo(
          correo: _correoLimpio,
          codigo: _codigo.text.trim(),
          idRol: _idRol,
          nombre: _nombre.text.trim(),
          apellido: _apellido.text.trim(),
        );
  }

  Widget _titulo(String titulo, String detalle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(detalle, style: const TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
          const SizedBox(height: 24),
        ],
      );

  Widget _pasoCorreo() => Form(
        key: _formCorreo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('Continuar con Gmail',
                'Escribe tu Gmail (o cualquier correo). Te enviaremos un código para entrar, sin contraseña. Si aún no tienes cuenta, la creamos en un momento.'),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: inputDeco('tucorreo@gmail.com',
                  prefix: const Icon(Icons.mail_outline, color: C.muted)),
              validator: validarCorreo,
              onFieldSubmitted: (_) => _enviarCorreo(),
            ),
            TextoError(_errorEnvio),
            const SizedBox(height: 22),
            BotonOCarga(
              cargando: _enviando,
              boton: PrimaryButton(text: 'Enviarme un código', onTap: _enviarCorreo),
            ),
          ],
        ),
      );

  Widget _pasoCodigo(AuthProvider auth) => Form(
        key: _formCodigo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('Revisa tu correo', _aviso ?? 'Te enviamos un código a $_correoLimpio.'),
            CampoCodigo(controller: _codigo, onFieldSubmitted: (_) => _verificar()),
            TextoError(auth.error ?? _errorEnvio),
            const SizedBox(height: 22),
            BotonOCarga(
              cargando: auth.cargando,
              boton: PrimaryButton(text: 'Continuar', onTap: _verificar),
            ),
            const SizedBox(height: 8),
            Center(child: ReenviarCodigo(onReenviar: _pedirCodigo)),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _paso = _Paso.correo;
                  _codigo.clear();
                  context.read<AuthProvider>().limpiarError();
                }),
                child: const Text('Usar otro correo', style: TextStyle(color: C.muted)),
              ),
            ),
          ],
        ),
      );

  Widget _pasoDatos(AuthProvider auth) => Form(
        key: _formDatos,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('Termina tu cuenta', 'Tu correo $_correoLimpio está verificado. Solo faltan estos datos.'),
            const Text('¿Cómo vas a usar la app?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SelectorRol(valor: _idRol, onChanged: (r) => setState(() => _idRol = r)),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              decoration: inputDeco('Nombre'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _apellido,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              decoration: inputDeco('Apellido'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Ingresa tu apellido' : null,
              onFieldSubmitted: (_) => _crearCuenta(),
            ),
            if (_idRol == Roles.trabajador) ...[
              const SizedBox(height: 10),
              const Text('Después podrás agregar tu oficio en "Mis servicios".',
                  style: TextStyle(color: C.muted, fontSize: 12)),
            ],
            TextoError(auth.error),
            const SizedBox(height: 22),
            BotonOCarga(
              cargando: auth.cargando,
              boton: PrimaryButton(text: 'Crear cuenta', onTap: _crearCuenta),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar con correo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_paso) {
            _Paso.correo => _pasoCorreo(),
            _Paso.codigo => _pasoCodigo(auth),
            _Paso.datos => _pasoDatos(auth),
          },
        ),
      ),
    );
  }
}
