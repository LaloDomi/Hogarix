import 'package:flutter/material.dart';
import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/screens/chat/chat_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/chat_service.dart';
import 'package:provider/provider.dart';

/// Bandeja de conversaciones (datos reales del backend).
class MessagesScreen extends StatefulWidget {
  final bool conAppBar;
  const MessagesScreen({super.key, this.conAppBar = false});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Conversacion>? _lista;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_error != null) setState(() => _error = null);
    try {
      final lista = await ChatService(context.read<ApiClient>()).conversaciones();
      if (mounted) setState(() => _lista = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.mensaje : 'No se pudieron cargar tus chats.');
      }
    }
  }

  String _cuando(DateTime? f) {
    if (f == null) return '';
    return mismoDia(f, DateTime.now()) ? horaTexto(f) : diaMesAbreviado(f);
  }

  Widget _listaWidget() {
    if (_error != null) {
      return ListView(children: [EstadoError(mensaje: _error!, onReintentar: _cargar)]);
    }
    final lista = _lista;
    if (lista == null) return const Center(child: CircularProgressIndicator());
    if (lista.isEmpty) {
      return ListView(children: const [
        EstadoVacio(
          icono: Icons.chat_bubble_outline,
          titulo: 'Aún no tienes conversaciones',
          detalle: 'Escríbele a un profesional desde su perfil o desde una solicitud.',
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = lista[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  idOtroUsuario: c.idOtro,
                  nombre: c.nombreOtro,
                  foto: c.fotoOtro,
                  idConversacion: c.id,
                ),
              ),
            );
            if (mounted) _cargar();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDeco(),
            child: Row(
              children: [
                Avatar(name: c.nombreOtro, foto: urlFoto(context, c.fotoOtro), size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nombreOtro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: c.noLeidos > 0 ? FontWeight.w800 : FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(c.vistaPrevia,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: c.noLeidos > 0 ? Colors.white : C.muted, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_cuando(c.fecha), style: const TextStyle(color: C.muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    if (c.noLeidos > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: C.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${c.noLeidos}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuerpo = RefreshIndicator(onRefresh: _cargar, child: _listaWidget());
    if (widget.conAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mensajes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(child: cuerpo),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text('Mensajes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        Expanded(child: cuerpo),
      ],
    );
  }
}
