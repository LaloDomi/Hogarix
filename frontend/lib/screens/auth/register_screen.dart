import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manocerca/core/models/usuario.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/screens/auth/acceso_correo_screen.dart';
import 'package:manocerca/screens/auth/login_screen.dart';
import 'package:manocerca/screens/auth/widgets/auth_widgets.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';
import 'package:provider/provider.dart';

/// Con qué se registra la persona (con qué va a iniciar sesión).
enum _Via { correo, telefono }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  int _idRol = Roles.cliente;
  _Via _via = _Via.correo;

  /// true cuando el servidor mandó un código para confirmar el correo.
  bool _verificando = false;
  final _formCodigo = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  // Solo trabajadores (ambos opcionales).
  int? _idCategoria;
  String? _tipoPago;

  /// Lo que ve la persona -> valor que entiende el backend.
  static const _tiposPago = <(String, String)>[
    ('Destajo', 'Destajo'),
    ('Por día', 'Día'),
    ('Por proyecto', 'Por trabajo'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().limpiarError();
      context.read<CategoriasProvider>().cargarSiHaceFalta();
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _telefono.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _registrar();
  }

  /// Sin [codigo]: el servidor puede responder que mandó un código al correo.
  /// Con [codigo]: confirma el correo y crea la cuenta.
  /// Devuelve true si se creó la cuenta o se envió el código.
  Future<bool> _registrar({String? codigo}) async {
    final correo = _correo.text.trim().toLowerCase();
    // Si el registro funciona, AuthGate reemplaza esta pantalla por la app.
    final r = await context.read<AuthProvider>().registrar(
          idRol: _idRol,
          nombre: _nombre.text.trim(),
          apellido: _apellido.text.trim(),
          correo: correo.isEmpty ? null : correo,
          contrasena: _contrasena.text,
          telefono: normalizarTelefono(_telefono.text) ?? '',
          codigo: codigo,
          // Si eligió oficio, aparece de inmediato en esa categoría.
          servicio: _idRol == Roles.trabajador && _idCategoria != null
              ? (idCategoria: _idCategoria!, tipoPago: _tipoPago ?? 'Por trabajo')
              : null,
        );
    if (!mounted) return false;
    if (r == ResultadoRegistro.requiereCodigo) {
      setState(() {
        _verificando = true;
        _codigo.clear();
      });
    }
    return r != ResultadoRegistro.error;
  }

  Future<void> _confirmarCodigo() async {
    if (!_formCodigo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _registrar(codigo: _codigo.text.trim());
  }

  Widget _pasoCodigo(AuthProvider auth) {
    final correo = _correo.text.trim().toLowerCase();
    return Form(
      key: _formCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirma tu correo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Te enviamos un código de 6 dígitos a $correo. Revisa también la carpeta de spam.',
              style: const TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
          const SizedBox(height: 22),
          CampoCodigo(controller: _codigo, onFieldSubmitted: (_) => _confirmarCodigo()),
          TextoError(auth.error),
          const SizedBox(height: 22),
          BotonOCarga(
            cargando: auth.cargando,
            boton: PrimaryButton(text: 'Confirmar y crear cuenta', onTap: _confirmarCodigo),
          ),
          const SizedBox(height: 8),
          Center(child: ReenviarCodigo(onReenviar: () => _registrar())),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _verificando = false;
                context.read<AuthProvider>().limpiarError();
              }),
              child: const Text('Corregir mis datos', style: TextStyle(color: C.muted)),
            ),
          ),
        ],
      ),
    );
  }

  String? _requerido(String? v, String campo) =>
      (v ?? '').trim().isEmpty ? 'Ingresa tu $campo' : null;

  /// Oficio y forma de cobro (opcionales). Se pueden cambiar después en
  /// "Mis servicios".
  Widget _datosTrabajador() {
    final cats = context.watch<CategoriasProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        const Text('¿A qué te dedicas? (opcional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Así los clientes te encuentran en esa categoría desde el primer día.',
            style: TextStyle(color: C.muted, fontSize: 12)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _idCategoria,
          isExpanded: true,
          dropdownColor: C.card,
          decoration: inputDeco(cats.cargando && cats.items.isEmpty
              ? 'Cargando oficios...'
              : 'Elige tu oficio',
              prefix: const Icon(Icons.handyman_outlined, color: C.muted)),
          items: [
            for (final c in cats.items) DropdownMenuItem(value: c.id, child: Text(c.nombre)),
          ],
          onChanged: (v) => setState(() => _idCategoria = v),
        ),
        const SizedBox(height: 14),
        const Text('¿Cómo cobras? (opcional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _tiposPago)
              ChoiceChip(
                label: Text(t.$1),
                selected: _tipoPago == t.$2,
                onSelected: (sel) => setState(() => _tipoPago = sel ? t.$2 : null),
              ),
          ],
        ),
        if (_tipoPago != null && _idCategoria == null) ...[
          const SizedBox(height: 6),
          const Text('Elige también tu oficio para guardar la forma de cobro.',
              style: TextStyle(color: C.star, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _campoCorreo({required bool obligatorio}) => TextFormField(
        key: ValueKey('correo-$obligatorio'),
        controller: _correo,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: inputDeco(obligatorio ? 'Correo electrónico' : 'Correo (opcional)',
            prefix: const Icon(Icons.mail_outline, color: C.muted)),
        validator: (v) {
          if (!obligatorio && (v ?? '').trim().isEmpty) return null;
          return validarCorreo(v);
        },
      );

  Widget _campoTelefono({required bool obligatorio}) => TextFormField(
        key: ValueKey('telefono-$obligatorio'),
        controller: _telefono,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: inputDeco(
          obligatorio ? 'Teléfono a 10 dígitos' : 'Teléfono (opcional)',
          prefix: const Icon(Icons.phone_outlined, color: C.muted),
        ).copyWith(prefixText: '+52 '),
        validator: (v) {
          if (!obligatorio && (v ?? '').trim().isEmpty) return null;
          return validarTelefono(v);
        },
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _verificando ? _pasoCodigo(auth) : Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Cómo vas a usar la app?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SelectorRol(valor: _idRol, onChanged: (r) => setState(() => _idRol = r)),
                if (_idRol == Roles.trabajador) _datosTrabajador(),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  decoration: inputDeco('Nombre'),
                  validator: (v) => _requerido(v, 'nombre'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _apellido,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  decoration: inputDeco('Apellido'),
                  validator: (v) => _requerido(v, 'apellido'),
                ),
                const SizedBox(height: 22),
                const Text('¿Con qué quieres iniciar sesión?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Via>(
                    segments: const [
                      ButtonSegment(
                          value: _Via.correo,
                          icon: Icon(Icons.mail_outline),
                          label: Text('Correo')),
                      ButtonSegment(
                          value: _Via.telefono,
                          icon: Icon(Icons.phone_outlined),
                          label: Text('Teléfono')),
                    ],
                    selected: {_via},
                    showSelectedIcon: false,
                    onSelectionChanged: (sel) => setState(() => _via = sel.first),
                  ),
                ),
                const SizedBox(height: 14),
                if (_via == _Via.correo) ...[
                  _campoCorreo(obligatorio: true),
                  const SizedBox(height: 14),
                  _campoTelefono(obligatorio: false),
                ] else ...[
                  _campoTelefono(obligatorio: true),
                  const SizedBox(height: 14),
                  _campoCorreo(obligatorio: false),
                  const SizedBox(height: 6),
                  const Text('Con un correo podrás recuperar tu contraseña si la olvidas.',
                      style: TextStyle(color: C.muted, fontSize: 12)),
                ],
                const SizedBox(height: 14),
                CampoContrasena(
                  controller: _contrasena,
                  hint: 'Contraseña (mínimo 6 caracteres)',
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: validarContrasenaNueva,
                ),
                const SizedBox(height: 14),
                CampoContrasena(
                  controller: _confirmar,
                  hint: 'Repite la contraseña',
                  validator: (v) =>
                      v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
                  onFieldSubmitted: (_) => _enviar(),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 14),
                  Text(auth.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                ],
                const SizedBox(height: 24),
                auth.cargando
                    ? const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : PrimaryButton(text: 'Crear cuenta', onTap: _enviar),
                const SeparadorO(),
                OutlineButtonX(
                  text: 'Registrarme con Gmail',
                  icon: Icons.mail_outline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccesoCorreoScreen()),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Sin contraseña: te enviamos un código a tu correo.',
                      style: TextStyle(color: C.muted, fontSize: 12)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
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
    );
  }
}
