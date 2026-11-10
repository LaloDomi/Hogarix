import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/models/tipo_pago.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/categoria_icono.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/boton_mejorar_ia.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/stars.dart';
import 'package:manocerca/screens/confirmed/confirmed_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/chat_service.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:provider/provider.dart';

/// El cliente solicita uno de los servicios del trabajador.
class RequestScreen extends StatefulWidget {
  final PerfilTrabajador perfil;

  /// Categoría con la que llegó el cliente (se preselecciona si existe).
  final int? idCategoriaInicial;

  const RequestScreen({super.key, required this.perfil, this.idCategoriaInicial});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  late MiServicio _servicio;
  late String _tipoPago;
  final _monto = TextEditingController();
  final _detalle = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final servicios = widget.perfil.servicios;
    _servicio = servicios.firstWhere(
      (s) => s.idCategoria == widget.idCategoriaInicial,
      orElse: () => servicios.first,
    );
    _elegirServicio(_servicio, inicial: true);
  }

  @override
  void dispose() {
    _monto.dispose();
    _detalle.dispose();
    super.dispose();
  }

  void _elegirServicio(MiServicio s, {bool inicial = false}) {
    void aplicar() {
      _servicio = s;
      _tipoPago = s.tipoPago;
      final p = s.precioBase;
      _monto.text = p == null ? '' : (p == p.roundToDouble() ? p.toStringAsFixed(0) : '$p');
    }

    inicial ? aplicar() : setState(aplicar);
  }

  Future<void> _enviar() async {
    final texto = _monto.text.trim().replaceAll(',', '.');
    final monto = texto.isEmpty ? null : double.tryParse(texto);
    if (texto.isNotEmpty && (monto == null || monto < 0)) {
      mostrarAviso(context, 'Escribe un monto válido o déjalo vacío.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await SolicitudService(context.read<ApiClient>()).crear(
        idTrabajador: widget.perfil.idUsuario!,
        idCategoria: _servicio.idCategoria,
        tipoPago: _tipoPago,
        monto: monto,
      );
      await _mandarDetalle();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmedScreen(
            nombreTrabajador: widget.perfil.nombreCompleto,
            servicio: _servicio.categoria,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarAviso(context, e.mensaje);
    }
  }

  /// El detalle del trabajo llega al profesional como primer mensaje del
  /// chat, donde coordinan fecha y detalles. Si falla, la solicitud ya quedó.
  Future<void> _mandarDetalle() async {
    final detalle = _detalle.text.trim();
    if (detalle.isEmpty || !mounted) return;
    try {
      final chat = ChatService(context.read<ApiClient>());
      final id = await chat.abrir(widget.perfil.idUsuario!);
      await chat.enviar(id, contenido: 'Solicitud de ${_servicio.categoria}: $detalle');
    } catch (_) {
      // Sin conexión: el cliente puede escribirle después por mensaje.
    }
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.perfil;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar servicio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDeco(),
              child: Row(
                children: [
                  Avatar(name: p.nombreCompleto, foto: urlFoto(context, p.fotoPerfil), size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombreCompleto,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        if (p.calificacion != null)
                          Row(
                            children: [
                              Stars(rating: p.calificacion!, size: 13),
                              const SizedBox(width: 6),
                              Text('${p.calificacion!.toStringAsFixed(1)} (${p.totalResenas})',
                                  style: const TextStyle(color: C.muted, fontSize: 12)),
                            ],
                          )
                        else
                          const Text('Sin reseñas aún',
                              style: TextStyle(color: C.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _titulo('¿Qué servicio necesitas?'),
            for (final s in p.servicios)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _elegirServicio(s),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _servicio.id == s.id ? C.primary : C.border,
                        width: _servicio.id == s.id ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(iconoDeCategoria(s.categoria), color: C.light),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.categoria,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text(s.precioTexto,
                            style: const TextStyle(color: C.light, fontSize: 13)),
                        const SizedBox(width: 8),
                        Icon(
                          _servicio.id == s.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _servicio.id == s.id ? C.primary : C.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            _titulo('¿Cómo se cobrará?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in TipoPago.todos)
                  ChoiceChip(
                    label: Text(t.etiqueta),
                    selected: _tipoPago == t.valor,
                    onSelected: (_) => setState(() => _tipoPago = t.valor),
                  ),
              ],
            ),
            _titulo('Monto estimado (opcional)'),
            TextField(
              controller: _monto,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: inputDeco('Ej. 500',
                  prefix: const Icon(Icons.attach_money, color: C.muted)),
            ),
            _titulo('Cuéntale qué necesitas (opcional)'),
            TextField(
              controller: _detalle,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                  'Ej. Se gotea la llave de la cocina desde ayer, es de monomando…'),
            ),
            BotonMejorarIA(
              controller: _detalle,
              tipo: TipoTextoIA.solicitud,
              categoria: () => _servicio.categoria,
              habilitado: !_enviando,
            ),
            const Text('Se lo enviamos por mensaje junto con tu solicitud.',
                style: TextStyle(color: C.muted, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x222F8BFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: C.light, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El profesional recibirá tu solicitud y podrá aceptarla. '
                      'Después coordinen la fecha y los detalles por mensaje.',
                      style: TextStyle(color: Color(0xFFD7E0F2), fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _enviando
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(text: 'Enviar solicitud', icon: Icons.send, onTap: _enviar),
          ],
        ),
      ),
    );
  }
}
