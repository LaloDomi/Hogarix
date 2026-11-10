import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manocerca/core/models/usuario.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/screens/auth/widgets/validaciones.dart';

/// Campo de contraseña con botón para mostrarla u ocultarla.
class CampoContrasena extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const CampoContrasena({
    super.key,
    required this.controller,
    this.hint = 'Contraseña',
    this.validator,
    this.autofillHints,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  bool _ocultar = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _ocultar,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      decoration: inputDeco(
        widget.hint,
        prefix: const Icon(Icons.lock_outline, color: C.muted),
      ).copyWith(
        suffixIcon: IconButton(
          tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility, color: C.muted),
          onPressed: () => setState(() => _ocultar = !_ocultar),
        ),
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}

/// Campo para el código de 6 dígitos que llega al correo.
class CampoCodigo extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onFieldSubmitted;
  const CampoCodigo({super.key, required this.controller, this.onFieldSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 10),
      decoration: inputDeco('000000'),
      validator: validarCodigo,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

/// "Reenviar código" con cuenta regresiva para no saturar el correo.
class ReenviarCodigo extends StatefulWidget {
  /// Devuelve true si se envió el código (reinicia la cuenta regresiva).
  final Future<bool> Function() onReenviar;
  final int segundos;
  const ReenviarCodigo({super.key, required this.onReenviar, this.segundos = 45});

  @override
  State<ReenviarCodigo> createState() => _ReenviarCodigoState();
}

class _ReenviarCodigoState extends State<ReenviarCodigo> {
  Timer? _timer;
  late int _restantes;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  void _iniciar() {
    _timer?.cancel();
    _restantes = widget.segundos;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restantes--);
      if (_restantes <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reenviar() async {
    setState(() => _enviando = true);
    final ok = await widget.onReenviar();
    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (ok) _iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_enviando) {
      return const SizedBox(
          height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_restantes > 0) {
      return SizedBox(
        height: 36,
        child: Center(
          child: Text('Puedes pedir otro código en $_restantes s',
              style: const TextStyle(color: C.muted, fontSize: 13)),
        ),
      );
    }
    return TextButton(
      onPressed: _reenviar,
      child: const Text('Reenviar código', style: TextStyle(color: C.light)),
    );
  }
}

/// Tarjetas "Busco un servicio" / "Ofrezco servicios".
class SelectorRol extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  const SelectorRol({super.key, required this.valor, required this.onChanged});

  Widget _opcion(int rol, IconData icono, String titulo, String detalle) {
    final activo = valor == rol;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(rol),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: activo ? C.primary.withValues(alpha: 0.18) : C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: activo ? C.primary : C.border, width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icono, color: activo ? C.primary : C.muted, size: 28),
              const SizedBox(height: 8),
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(detalle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _opcion(Roles.cliente, Icons.search, 'Busco un servicio', 'Soy cliente'),
        const SizedBox(width: 12),
        _opcion(Roles.trabajador, Icons.handyman, 'Ofrezco servicios', 'Soy trabajador'),
      ],
    );
  }
}

/// Línea "—— o ——" entre el formulario y otras formas de entrar.
class SeparadorO extends StatelessWidget {
  const SeparadorO({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Divider(color: C.border)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('o', style: TextStyle(color: C.muted)),
          ),
          Expanded(child: Divider(color: C.border)),
        ],
      ),
    );
  }
}

/// Texto de error del formulario.
class TextoError extends StatelessWidget {
  final String? texto;
  const TextoError(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = texto;
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(t, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
    );
  }
}

/// Botón principal o indicador de carga del mismo alto.
class BotonOCarga extends StatelessWidget {
  final bool cargando;
  final Widget boton;
  const BotonOCarga({super.key, required this.cargando, required this.boton});

  @override
  Widget build(BuildContext context) => cargando
      ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
      : boton;
}
