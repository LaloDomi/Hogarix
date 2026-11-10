import 'package:flutter/material.dart';
import 'package:manocerca/core/models/publicacion.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/publicacion_service.dart';
import 'package:provider/provider.dart';

/// Una publicación completa al estilo Facebook: fotos deslizables,
/// "Me gusta" y comentarios. Devuelve `true` si algo cambió.
class PublicacionDetalleScreen extends StatefulWidget {
  final Publicacion publicacion;
  final bool esPropia;
  const PublicacionDetalleScreen({
    super.key,
    required this.publicacion,
    this.esPropia = false,
  });

  @override
  State<PublicacionDetalleScreen> createState() => _PublicacionDetalleScreenState();
}

class _PublicacionDetalleScreenState extends State<PublicacionDetalleScreen> {
  late Publicacion _p = widget.publicacion;
  final _comentario = TextEditingController();
  final _foco = FocusNode();
  final _pagina = PageController();
  int _foto = 0;

  List<Comentario>? _comentarios;
  String? _errorComentarios;
  bool _enviando = false;
  bool _cambio = false;

  PublicacionService get _service => PublicacionService(context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _cargarComentarios();
  }

  @override
  void dispose() {
    _comentario.dispose();
    _foco.dispose();
    _pagina.dispose();
    super.dispose();
  }

  Future<void> _cargarComentarios() async {
    if (_errorComentarios != null) setState(() => _errorComentarios = null);
    try {
      final lista = await _service.comentarios(_p.id);
      if (mounted) setState(() => _comentarios = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _errorComentarios =
            e is ApiException ? e.mensaje : 'No se pudieron cargar los comentarios.');
      }
    }
  }

  Future<void> _alternarLike() async {
    final antes = _p;
    setState(() {
      _cambio = true;
      _p = _p.copyWith(
        meGusta: !antes.meGusta,
        totalLikes: antes.totalLikes + (antes.meGusta ? -1 : 1),
      );
    });
    try {
      final total =
          antes.meGusta ? await _service.quitarLike(_p.id) : await _service.darLike(_p.id);
      if (mounted && total != null) setState(() => _p = _p.copyWith(totalLikes: total));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _p = antes);
      mostrarAviso(context, e.mensaje);
    }
  }

  Future<void> _comentar() async {
    final texto = _comentario.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _service.comentar(_p.id, texto);
      _comentario.clear();
      _cambio = true;
      _p = _p.copyWith(totalComentarios: _p.totalComentarios + 1);
      await _cargarComentarios();
    } on ApiException catch (e) {
      if (mounted) mostrarAviso(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('Se quitará de tu perfil. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: C.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.eliminar(_p.id);
      if (!mounted) return;
      Navigator.pop(context, true);
      mostrarAviso(context, 'Publicación eliminada');
    } on ApiException catch (e) {
      if (mounted) mostrarAviso(context, e.mensaje);
    }
  }

  void _verFoto(int inicio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _VisorFotos(fotos: _p.imagenes, inicio: inicio),
      ),
    );
  }

  Widget _galeria() {
    if (_p.imagenes.isEmpty) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pagina,
            itemCount: _p.imagenes.length,
            onPageChanged: (i) => setState(() => _foto = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _verFoto(i),
              child: ImagenRed(ruta: _p.imagenes[i], width: double.infinity),
            ),
          ),
          if (_p.imagenes.length > 1) ...[
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xAA000000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_foto + 1}/${_p.imagenes.length}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _p.imagenes.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _foto ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == _foto ? Colors.white : const Color(0x88FFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _comentariosLista() {
    if (_errorComentarios != null) {
      return EstadoError(mensaje: _errorComentarios!, onReintentar: _cargarComentarios);
    }
    final lista = _comentarios;
    if (lista == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (lista.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Sé el primero en comentar.',
            textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
      );
    }
    return Column(
      children: [
        for (final c in lista)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(name: c.nombre, foto: urlFoto(context, c.foto), size: 34),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: cardDeco(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(c.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            if (c.fecha != null)
                              Text(haceCuanto(c.fecha!),
                                  style: const TextStyle(color: C.muted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(c.contenido, style: const TextStyle(fontSize: 13, height: 1.35)),
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

  Widget _accion(IconData icono, String texto, Color color, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 20, color: color),
                const SizedBox(width: 6),
                Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context, _cambio),
        ),
        actions: [
          if (widget.esPropia)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'eliminar') _eliminar();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: C.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        Avatar(
                            name: _p.nombreAutor,
                            foto: urlFoto(context, _p.fotoAutor),
                            size: 42),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_p.nombreAutor,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (_p.fecha != null)
                                Text(haceCuanto(_p.fecha!),
                                    style: const TextStyle(color: C.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_p.titulo,
                            style:
                                const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(_p.contenido,
                            style: const TextStyle(
                                color: Color(0xFFD7E0F2), fontSize: 14, height: 1.45)),
                      ],
                    ),
                  ),
                  _galeria(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text('${_p.totalLikes}', style: const TextStyle(color: C.muted)),
                        const Spacer(),
                        Text(
                          _p.totalComentarios == 1
                              ? '1 comentario'
                              : '${_p.totalComentarios} comentarios',
                          style: const TextStyle(color: C.muted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: C.border, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _accion(
                          _p.meGusta ? Icons.favorite : Icons.favorite_border,
                          'Me gusta',
                          _p.meGusta ? Colors.redAccent : C.muted,
                          _alternarLike,
                        ),
                        _accion(Icons.mode_comment_outlined, 'Comentar', C.muted,
                            () => _foco.requestFocus()),
                      ],
                    ),
                  ),
                  const Divider(color: C.border, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: _comentariosLista(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(
                color: C.bg2,
                border: Border(top: BorderSide(color: C.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comentario,
                      focusNode: _foco,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: inputDeco('Escribe un comentario…')
                          .copyWith(counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _enviando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          onPressed: _comentar,
                          icon: const Icon(Icons.send_rounded, color: C.primary),
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

/// Fotos a pantalla completa con zoom.
class _VisorFotos extends StatelessWidget {
  final List<String> fotos;
  final int inicio;
  const _VisorFotos({required this.fotos, required this.inicio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PageView.builder(
        controller: PageController(initialPage: inicio),
        itemCount: fotos.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(child: ImagenRed(ruta: fotos[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
