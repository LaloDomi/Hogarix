import 'package:flutter/material.dart';
import 'package:manocerca/core/widgets/boton_mejorar_ia.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/models/tipo_pago.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/trabajador_service.dart';
import 'package:provider/provider.dart';

/// Crea un servicio nuevo o edita [servicio]. Al guardar hace `pop(true)`.
class ServicioFormScreen extends StatefulWidget {
  final MiServicio? servicio;
  const ServicioFormScreen({super.key, this.servicio});

  @override
  State<ServicioFormScreen> createState() => _ServicioFormScreenState();
}

class _ServicioFormScreenState extends State<ServicioFormScreen> {
  static const _montoMaximo = 99999999.99;

  final _form = GlobalKey<FormState>();
  late final TextEditingController _precio;
  late final TextEditingController _descripcion;
  int? _idCategoria;
  String? _tipoPago;
  bool _guardando = false;
  String? _error;

  bool get _edita => widget.servicio != null;

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    _idCategoria = s?.idCategoria;
    _tipoPago = s?.tipoPago;
    _precio = TextEditingController(
      text: s?.precioBase == null
          ? ''
          : (s!.precioBase! == s.precioBase!.roundToDouble()
              ? s.precioBase!.toStringAsFixed(0)
              : s.precioBase!.toStringAsFixed(2)),
    );
    _descripcion = TextEditingController(text: s?.descripcion ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoriasProvider>().cargarSiHaceFalta();
    });
  }

  @override
  void dispose() {
    _precio.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  double? _montoDe(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  String? _validarPrecio(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final monto = _montoDe(t);
    if (monto == null || monto < 0) return 'Ingresa un monto válido';
    if (monto > _montoMaximo) return 'El monto es demasiado grande';
    return null;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final texto = _precio.text.trim();
    final precio = texto.isEmpty ? null : _montoDe(texto);
    final descripcion = _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim();

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final service = TrabajadorService(context.read<ApiClient>());
      if (_edita) {
        await service.actualizarServicio(
          widget.servicio!.id,
          idCategoria: _idCategoria!,
          tipoPago: _tipoPago!,
          precioBase: precio,
          descripcion: descripcion,
        );
      } else {
        await service.crearServicio(
          idCategoria: _idCategoria!,
          tipoPago: _tipoPago!,
          precioBase: precio,
          descripcion: descripcion,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo guardar el servicio. Intenta de nuevo.';
        _guardando = false;
      });
    }
  }

  Widget _formulario(CategoriasProvider cats) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _idCategoria,
            isExpanded: true,
            dropdownColor: C.card,
            decoration: inputDeco('Categoría'),
            items: [
              for (final c in cats.items)
                DropdownMenuItem(value: c.id, child: Text(c.nombre)),
            ],
            onChanged: (v) => setState(() => _idCategoria = v),
            validator: (v) => v == null ? 'Elige una categoría' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _tipoPago,
            isExpanded: true,
            dropdownColor: C.card,
            decoration: inputDeco('Tipo de pago'),
            items: [
              for (final t in TipoPago.todos)
                DropdownMenuItem(value: t.valor, child: Text(t.etiqueta)),
            ],
            onChanged: (v) => setState(() => _tipoPago = v),
            validator: (v) => v == null ? 'Elige cómo cobras' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: inputDeco('Precio base en pesos (opcional)',
                prefix: const Icon(Icons.attach_money, color: C.muted)),
            validator: _validarPrecio,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descripcion,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: inputDeco('Describe lo que incluye tu servicio (opcional)'),
          ),
          BotonMejorarIA(
            controller: _descripcion,
            tipo: TipoTextoIA.servicio,
            categoria: () =>
                cats.items.where((c) => c.id == _idCategoria).firstOrNull?.nombre ?? '',
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          _guardando
              ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
              : PrimaryButton(
                  text: _edita ? 'Guardar cambios' : 'Agregar servicio',
                  onTap: _guardar,
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoriasProvider>();

    Widget cuerpo;
    if (cats.items.isNotEmpty) {
      cuerpo = _formulario(cats);
    } else if (cats.error != null && !cats.cargando) {
      cuerpo = Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Text(cats.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, fontSize: 14)),
            TextButton(onPressed: cats.recargar, child: const Text('Reintentar')),
          ],
        ),
      );
    } else {
      cuerpo = const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_edita ? 'Editar servicio' : 'Nuevo servicio',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: cuerpo,
        ),
      ),
    );
  }
}
