import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/boton_mejorar_ia.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/editar_perfil/agregar_correo_screen.dart';
import 'package:manocerca/screens/editar_perfil/cambiar_contrasena_screen.dart';
import 'package:manocerca/screens/ubicacion/ubicacion_sheet.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/trabajador_service.dart';
import 'package:provider/provider.dart';

/// Editar perfil (clientes y trabajadores): foto, datos personales, edad,
/// sexo y ubicación. Si se pasa [perfil] (trabajador) también la descripción
/// y la disponibilidad. Devuelve `true` si guardó cambios.
class EditarPerfilScreen extends StatefulWidget {
  final PerfilTrabajador? perfil;
  const EditarPerfilScreen({super.key, this.perfil});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  static const _sexos = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _telefono;
  late final TextEditingController _bio;
  DateTime? _nacimiento;
  String? _sexo;
  late bool _disponible;

  Uint8List? _fotoNueva;
  String? _fotoNombre;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().usuario;
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _apellido = TextEditingController(text: u?.apellido ?? '');
    _telefono = TextEditingController(text: u?.telefono ?? '');
    _bio = TextEditingController(text: widget.perfil?.biografia ?? '');
    _nacimiento = DateTime.tryParse(u?.fechaNacimiento ?? '');
    _sexo = _sexos.contains(u?.sexo) ? u!.sexo : null;
    _disponible = widget.perfil?.disponible ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _bio.dispose();
    super.dispose();
  }

  String _dos(int n) => n.toString().padLeft(2, '0');
  String _fechaSql(DateTime d) => '${d.year}-${_dos(d.month)}-${_dos(d.day)}';
  String _fechaTexto(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

  Future<void> _elegirFoto() async {
    try {
      final foto = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      if (mounted) {
        setState(() {
          _fotoNueva = bytes;
          _fotoNombre = foto.name;
        });
      }
    } catch (_) {
      if (mounted) mostrarAviso(context, 'No se pudieron abrir tus fotos.');
    }
  }

  Future<void> _elegirNacimiento() async {
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(hoy.year - 25, 1, 1),
      firstDate: DateTime(hoy.year - 100),
      lastDate: DateTime(hoy.year - 16, hoy.month, hoy.day),
      helpText: 'Fecha de nacimiento',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (elegido != null) setState(() => _nacimiento = elegido);
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    final api = context.read<ApiClient>();
    final auth = context.read<AuthProvider>();
    try {
      String? rutaFoto;
      if (_fotoNueva != null) {
        final data = await api.subirImagen(_fotoNueva!, _fotoNombre ?? 'perfil.jpg');
        rutaFoto = data['ruta'] as String?;
      }
      final error = await auth.actualizarPerfil({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'telefono': _telefono.text.trim(),
        if (rutaFoto != null) 'foto_perfil': rutaFoto,
        if (_nacimiento != null) 'fecha_nacimiento': _fechaSql(_nacimiento!),
        'sexo': _sexo ?? '',
      });
      if (error != null) throw ApiException(error);

      final p = widget.perfil;
      if (p != null) {
        final service = TrabajadorService(api);
        if (_bio.text.trim() != (p.biografia ?? '').trim()) {
          await service.actualizarBiografia(_bio.text.trim());
        }
        if (_disponible != p.disponible) await service.actualizarDisponibilidad(_disponible);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      mostrarAviso(context, 'Perfil actualizado');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarAviso(context, e.mensaje);
    }
  }

  Widget _seccion(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthProvider>().usuario;
    final nombre = u?.nombreCompleto ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _guardando ? null : _elegirFoto,
                  child: Stack(
                    children: [
                      _fotoNueva != null
                          ? ClipOval(
                              child: Image.memory(_fotoNueva!,
                                  width: 108, height: 108, fit: BoxFit.cover),
                            )
                          : Avatar(
                              name: nombre,
                              foto: urlFoto(context, u?.fotoPerfil),
                              size: 108,
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: C.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: C.bg, width: 3),
                          ),
                          child: const Icon(Icons.photo_camera, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Toca la foto para cambiarla',
                    style: TextStyle(color: C.muted, fontSize: 12)),
              ),
              _seccion('Datos personales'),
              TextFormField(
                controller: _nombre,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                decoration: inputDeco('Nombre'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _apellido,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                decoration: inputDeco('Apellido'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe tu apellido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _telefono,
                enabled: !_guardando,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                decoration: inputDeco('Teléfono (opcional)',
                    prefix: const Icon(Icons.phone_outlined, color: C.muted)),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: cardDeco(12),
                child: ListTile(
                  leading: const Icon(Icons.mail_outline, color: C.muted),
                  title: Text((u?.correo ?? '').isEmpty ? 'Sin correo' : u!.correo),
                  subtitle: Text(
                    (u?.correo ?? '').isEmpty
                        ? 'Agrégalo para poder recuperar tu contraseña'
                        : 'Toca para cambiarlo',
                    style: const TextStyle(color: C.muted, fontSize: 12),
                  ),
                  trailing: Text((u?.correo ?? '').isEmpty ? 'Agregar' : 'Cambiar',
                      style: const TextStyle(color: C.light)),
                  onTap: _guardando
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AgregarCorreoScreen())),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: cardDeco(12),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline, color: C.muted),
                  title: const Text('Cambiar contraseña'),
                  trailing: const Icon(Icons.chevron_right, color: C.muted),
                  onTap: _guardando
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CambiarContrasenaScreen())),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _guardando ? null : _elegirNacimiento,
                      child: InputDecorator(
                        decoration: inputDeco('Nacimiento',
                            prefix: const Icon(Icons.cake_outlined, color: C.muted)),
                        child: Text(
                          _nacimiento == null ? 'Elegir' : _fechaTexto(_nacimiento!),
                          style: TextStyle(color: _nacimiento == null ? C.muted : Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sexo,
                      isExpanded: true,
                      dropdownColor: C.card,
                      decoration: inputDeco('Sexo'),
                      items: [
                        for (final s in _sexos) DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: _guardando ? null : (v) => setState(() => _sexo = v),
                    ),
                  ),
                ],
              ),
              _seccion('Ubicación'),
              Container(
                decoration: cardDeco(14),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: C.primary),
                  title: Text(u?.ubicacionTexto ?? 'Sin ubicación'),
                  subtitle: Text(
                    (u?.colonia ?? '').isEmpty ? 'Toca para cambiarla' : 'Col. ${u!.colonia}',
                    style: const TextStyle(color: C.muted, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit_outlined, color: C.muted),
                  onTap: _guardando ? null : () => editarUbicacion(context),
                ),
              ),
              if (widget.perfil != null) ...[
                _seccion('Sobre ti'),
                const Text('Tu experiencia, en qué te especializas y en qué zona trabajas.',
                    style: TextStyle(color: C.muted, fontSize: 12)),
                const SizedBox(height: 10),
                TextField(
                  controller: _bio,
                  enabled: !_guardando,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 600,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: inputDeco(
                      'Ej. Carpintero desde hace 5 años, hago muebles a medida y reparaciones…'),
                ),
                BotonMejorarIA(
                  controller: _bio,
                  tipo: TipoTextoIA.biografia,
                  habilitado: !_guardando,
                ),
                Container(
                  decoration: cardDeco(14),
                  child: SwitchListTile(
                    value: _disponible,
                    onChanged: _guardando ? null : (v) => setState(() => _disponible = v),
                    title: const Text('Disponible para trabajar'),
                    subtitle: Text(
                      _disponible
                          ? 'Los clientes te ven como disponible'
                          : 'Los clientes te ven como no disponible',
                      style: const TextStyle(color: C.muted, fontSize: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _guardando
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(text: 'Guardar cambios', icon: Icons.check, onTap: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
