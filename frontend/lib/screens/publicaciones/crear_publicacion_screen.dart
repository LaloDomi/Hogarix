import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manocerca/core/widgets/boton_mejorar_ia.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/publicacion_service.dart';
import 'package:provider/provider.dart';

/// Publicar un trabajo realizado, al estilo de una publicación de Facebook:
/// fotos + título + descripción. Devuelve `true` si se publicó.
class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({super.key});

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _Foto {
  final Uint8List bytes;
  final String nombre;
  const _Foto(this.bytes, this.nombre);
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _picker = ImagePicker();
  final List<_Foto> _fotos = [];

  bool _enviando = false;
  int _subidas = 0;

  static const _max = PublicacionService.maxFotos;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _agregar(List<XFile> archivos) async {
    final espacio = _max - _fotos.length;
    if (archivos.length > espacio) {
      mostrarAviso(context, 'Máximo $_max fotos por publicación.');
    }
    final nuevas = <_Foto>[];
    for (final a in archivos.take(espacio)) {
      nuevas.add(_Foto(await a.readAsBytes(), a.name));
    }
    if (mounted) setState(() => _fotos.addAll(nuevas));
  }

  Future<void> _desdeGaleria() async {
    if (_fotos.length >= _max) {
      mostrarAviso(context, 'Ya tienes $_max fotos.');
      return;
    }
    try {
      final archivos = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1920);
      await _agregar(archivos);
    } catch (_) {
      if (mounted) mostrarAviso(context, 'No se pudieron abrir tus fotos.');
    }
  }

  Future<void> _desdeCamara() async {
    if (_fotos.length >= _max) {
      mostrarAviso(context, 'Ya tienes $_max fotos.');
      return;
    }
    try {
      final foto = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 80, maxWidth: 1920);
      if (foto != null) await _agregar([foto]);
    } catch (_) {
      if (mounted) mostrarAviso(context, 'No se pudo abrir la cámara.');
    }
  }

  Future<void> _publicar() async {
    if (_enviando) return;
    final valido = _form.currentState!.validate();
    if (_fotos.isEmpty) {
      mostrarAviso(context, 'Agrega al menos una foto de tu trabajo.');
      return;
    }
    if (!valido) return;

    setState(() {
      _enviando = true;
      _subidas = 0;
    });
    try {
      await PublicacionService(context.read<ApiClient>()).crear(
        titulo: _titulo.text.trim(),
        contenido: _descripcion.text.trim(),
        fotos: [for (final f in _fotos) (bytes: f.bytes, nombre: f.nombre)],
        alAvanzar: (n) {
          if (mounted) setState(() => _subidas = n);
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      mostrarAviso(context, '¡Trabajo publicado!');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarAviso(context, e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarAviso(context, 'No se pudo publicar. Intenta de nuevo.');
    }
  }

  Widget _miniatura(int i) => Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(_fotos[i].bytes, fit: BoxFit.cover),
            ),
          ),
          if (i == 0)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: C.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Portada', style: TextStyle(fontSize: 10)),
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: _enviando ? null : () => setState(() => _fotos.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xAA000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );

  Widget _botonAgregar() => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _enviando ? null : _desdeGaleria,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: C.light, width: 1.2),
            color: C.card,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: C.light, size: 30),
              SizedBox(height: 4),
              Text('Agregar', style: TextStyle(color: C.light, fontSize: 12)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva publicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _enviando ? null : () => Navigator.pop(context, false),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _enviando ? null : _publicar,
                child: const Text('Publicar'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_enviando) ...[
                  LinearProgressIndicator(
                    value: _fotos.isEmpty ? null : _subidas / (_fotos.length + 1),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subidas < _fotos.length
                        ? 'Subiendo foto ${_subidas + 1} de ${_fotos.length}…'
                        : 'Publicando…',
                    style: const TextStyle(color: C.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Avatar(name: usuario?.nombreCompleto ?? '?', size: 44),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario?.nombreCompleto ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Row(
                          children: [
                            Icon(Icons.public, size: 13, color: C.muted),
                            SizedBox(width: 4),
                            Text('Visible para todos los clientes',
                                style: TextStyle(color: C.muted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titulo,
                  enabled: !_enviando,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: inputDeco('¿Qué trabajo hiciste? Ej. Mesa para 6 personas'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Escribe un título para tu trabajo' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcion,
                  enabled: !_enviando,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: inputDeco(
                      'Cuenta los detalles: materiales, cuánto tardaste, precio aproximado…'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Describe brevemente el trabajo' : null,
                ),
                BotonMejorarIA(
                  controller: _descripcion,
                  tipo: TipoTextoIA.publicacion,
                  titulo: () => _titulo.text,
                  habilitado: !_enviando,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Fotos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('${_fotos.length}/$_max',
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (int i = 0; i < _fotos.length; i++) _miniatura(i),
                    if (_fotos.length < _max) _botonAgregar(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _enviando ? null : _desdeGaleria,
                        icon: const Icon(Icons.photo_library_outlined, color: C.green),
                        label: const Text('Galería'),
                      ),
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _enviando ? null : _desdeCamara,
                          icon: const Icon(Icons.photo_camera_outlined, color: C.light),
                          label: const Text('Cámara'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'La primera foto será la portada. Imágenes JPG, PNG o WEBP de hasta 5 MB.',
                  style: TextStyle(color: C.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
