import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:provider/provider.dart';

/// Botón "Mejorar con IA" para poner debajo de un campo de texto.
/// Pide a la IA una versión mejor redactada, la muestra y la persona decide
/// si la usa. Nunca reemplaza el texto sin preguntar.
class BotonMejorarIA extends StatefulWidget {
  final TextEditingController controller;

  /// Uno de [TipoTextoIA].
  final String tipo;

  /// Contexto opcional (título del trabajo, oficio...) que se lee al tocar.
  final String Function()? titulo;
  final String Function()? categoria;
  final bool habilitado;

  const BotonMejorarIA({
    super.key,
    required this.controller,
    required this.tipo,
    this.titulo,
    this.categoria,
    this.habilitado = true,
  });

  @override
  State<BotonMejorarIA> createState() => _BotonMejorarIAState();
}

class _BotonMejorarIAState extends State<BotonMejorarIA> {
  bool _cargando = false;

  Future<void> _mejorar() async {
    final texto = widget.controller.text.trim();
    final titulo = widget.titulo?.call().trim() ?? '';
    final mensajero = ScaffoldMessenger.of(context);
    if (texto.length < 3 && titulo.isEmpty) {
      mensajero.showSnackBar(const SnackBar(
          content: Text('Escribe primero unas palabras y la IA te ayuda a mejorarlas.')));
      return;
    }

    setState(() => _cargando = true);
    String? sugerencia;
    try {
      sugerencia = await IaService(context.read<ApiClient>()).mejorarTexto(
        texto: texto,
        tipo: widget.tipo,
        titulo: titulo,
        categoria: widget.categoria?.call(),
      );
    } on ApiException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (_) {
      mensajero.showSnackBar(
          const SnackBar(content: Text('No se pudo usar la IA. Intenta de nuevo.')));
    }
    if (!mounted) return;
    setState(() => _cargando = false);
    final propuesta = sugerencia;
    if (propuesta == null) return;

    final usar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg2,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: C.light),
            SizedBox(width: 8),
            Text('Sugerencia de la IA', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDeco(12),
            child: SelectableText(propuesta, style: const TextStyle(height: 1.4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Dejar el mío', style: TextStyle(color: C.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usar este texto'),
          ),
        ],
      ),
    );
    if (usar == true) {
      widget.controller.text = propuesta;
      widget.controller.selection =
          TextSelection.collapsed(offset: widget.controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _cargando || !widget.habilitado ? null : _mejorar,
        icon: _cargando
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.auto_awesome, size: 18, color: C.light),
        label: Text(_cargando ? 'Mejorando…' : 'Mejorar con IA',
            style: const TextStyle(color: C.light, fontSize: 13)),
      ),
    );
  }
}
