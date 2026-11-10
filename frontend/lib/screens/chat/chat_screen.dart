import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/chat_service.dart';
import 'package:provider/provider.dart';

/// Chat real con otra persona. Revisa mensajes nuevos cada pocos segundos.
class ChatScreen extends StatefulWidget {
  final int idOtroUsuario;
  final String nombre;
  final String? foto;

  /// Si ya se conoce (desde la bandeja); si no, se abre o crea al entrar.
  final int? idConversacion;

  const ChatScreen({
    super.key,
    required this.idOtroUsuario,
    required this.nombre,
    this.foto,
    this.idConversacion,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late final ChatService _service;

  int? _idConversacion;
  final List<Mensaje> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  Timer? _sondeo;

  @override
  void initState() {
    super.initState();
    _service = ChatService(context.read<ApiClient>());
    _idConversacion = widget.idConversacion;
    _iniciar();
  }

  @override
  void dispose() {
    _sondeo?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      _idConversacion ??= await _service.abrir(widget.idOtroUsuario);
      final lista = await _service.mensajes(_idConversacion!);
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(lista);
        _cargando = false;
        _error = null;
      });
      _alFinal();
      _service.marcarLeida(_idConversacion!).catchError((_) {});
      _sondeo = Timer.periodic(const Duration(seconds: 4), (_) => _nuevos());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e is ApiException ? e.mensaje : 'No se pudo abrir el chat.';
      });
    }
  }

  Future<void> _nuevos() async {
    final id = _idConversacion;
    if (id == null || !mounted) return;
    try {
      final ultimo = _mensajes.isEmpty ? null : _mensajes.last.id;
      final nuevos = await _service.mensajes(id, despuesDe: ultimo);
      if (!mounted || nuevos.isEmpty) return;
      final ids = _mensajes.map((m) => m.id).toSet();
      setState(() => _mensajes.addAll(nuevos.where((m) => !ids.contains(m.id))));
      _alFinal();
      _service.marcarLeida(id).catchError((_) {});
    } catch (_) {
      // Sin conexión momentánea: se reintenta en el siguiente ciclo.
    }
  }

  void _alFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _enviar({String? urlImagen}) async {
    final texto = _ctrl.text.trim();
    final id = _idConversacion;
    if (id == null || _enviando || (texto.isEmpty && urlImagen == null)) return;
    setState(() => _enviando = true);
    try {
      final m = await _service.enviar(id,
          contenido: texto.isEmpty ? null : texto, urlImagen: urlImagen);
      if (!mounted) return;
      _ctrl.clear();
      if (m != null) setState(() => _mensajes.add(m));
      _alFinal();
    } on ApiException catch (e) {
      if (mounted) mostrarAviso(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _enviarFoto() async {
    try {
      final foto = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
      if (foto == null || !mounted) return;
      setState(() => _enviando = true);
      final data = await context.read<ApiClient>().subirImagen(await foto.readAsBytes(), foto.name);
      if (!mounted) return;
      setState(() => _enviando = false);
      await _enviar(urlImagen: data['ruta'] as String);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarAviso(context, e.mensaje);
      }
    } catch (_) {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _burbuja(Mensaje m, bool mostrarFecha) {
    return Column(
      children: [
        if (mostrarFecha && m.fecha != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(capitalizada(fechaCorta(m.fecha!)),
                style: const TextStyle(color: C.muted, fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: m.esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(
                    color: m.esMio ? C.primary : C.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.esMio ? 16 : 4),
                      bottomRight: Radius.circular(m.esMio ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (m.urlImagen != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ImagenRed(ruta: m.urlImagen, width: 220, height: 160),
                          ),
                        ),
                      if ((m.contenido ?? '').isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(m.contenido!,
                              style: const TextStyle(fontSize: 14.5, height: 1.3)),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.fecha != null)
                            Text(horaTexto(m.fecha!),
                                style: const TextStyle(fontSize: 10.5, color: Color(0xCCFFFFFF))),
                          if (m.esMio) ...[
                            const SizedBox(width: 4),
                            Icon(m.leido ? Icons.done_all : Icons.done,
                                size: 14, color: m.leido ? C.green : const Color(0xCCFFFFFF)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: EstadoError(
          mensaje: _error!,
          onReintentar: () {
            setState(() {
              _cargando = true;
              _error = null;
            });
            _iniciar();
          },
        ),
      );
    }
    if (_mensajes.isEmpty) {
      return Center(
        child: EstadoVacio(
          icono: Icons.waving_hand_outlined,
          titulo: 'Saluda a ${widget.nombre.split(' ').first}',
          detalle: 'Cuéntale qué necesitas o acuerden la fecha de la visita.',
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length,
      itemBuilder: (_, i) {
        final m = _mensajes[i];
        final anterior = i == 0 ? null : _mensajes[i - 1];
        final nuevoDia = anterior?.fecha == null ||
            m.fecha == null ||
            !mismoDia(anterior!.fecha!, m.fecha!);
        return _burbuja(m, nuevoDia);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(name: widget.nombre, foto: urlFoto(context, widget.foto), size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _contenido()),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: const BoxDecoration(
                color: C.bg2,
                border: Border(top: BorderSide(color: C.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Enviar foto',
                    onPressed: _idConversacion == null || _enviando ? null : _enviarFoto,
                    icon: const Icon(Icons.photo_outlined, color: C.light),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _enviar(),
                      decoration: inputDeco('Escribe un mensaje…'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _enviando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton.filled(
                          onPressed: _idConversacion == null ? null : () => _enviar(),
                          icon: const Icon(Icons.send_rounded),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
