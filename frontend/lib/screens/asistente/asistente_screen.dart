import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/categoria_icono.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/pro_list/pro_list_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:provider/provider.dart';

/// Asistente con IA.
/// - Cliente: describe su problema, recibe consejos y el oficio que necesita,
///   con un botón para ver a los profesionales de esa categoría.
/// - Trabajador: ayuda con cotizaciones, mensajes a clientes y descripciones.
class AsistenteScreen extends StatefulWidget {
  /// Pregunta que se envía al abrir (por ejemplo desde un atajo).
  final String? preguntaInicial;
  const AsistenteScreen({super.key, this.preguntaInicial});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  static const _sugerenciasCliente = [
    'Se me tapó el baño, ¿qué hago?',
    'Tengo una fuga de agua en la cocina',
    'Se fue la luz solo en un cuarto',
    'Quiero pintar mi casa, ¿qué necesito?',
  ];
  static const _sugerenciasTrabajador = [
    '¿Cómo calculo cuánto cobrar por un trabajo?',
    'Ayúdame a escribirle a un cliente que el trabajo se retrasa',
    '¿Cómo consigo más reseñas buenas?',
    'Ideas para describir mis servicios',
  ];

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<MensajeIA> _mensajes = [];
  bool _pensando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final inicial = widget.preguntaInicial;
    if (inicial != null && inicial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enviar(inicial));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _enviar([String? texto]) async {
    final pregunta = (texto ?? _ctrl.text).trim();
    if (pregunta.isEmpty || _pensando) return;
    _ctrl.clear();
    setState(() {
      _mensajes.add(MensajeIA(deUsuario: true, texto: pregunta));
      _pensando = true;
      _error = null;
    });
    _bajar();

    try {
      final respuesta = await IaService(context.read<ApiClient>()).preguntar(_mensajes);
      if (!mounted) return;
      setState(() => _mensajes.add(respuesta));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo contactar al asistente. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _pensando = false);
      _bajar();
    }
  }

  Widget _burbuja(MensajeIA m) {
    final mio = m.deUsuario;
    final cat = m.categoria;
    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mio ? C.primary : C.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mio ? 16 : 4),
              bottomRight: Radius.circular(mio ? 4 : 16),
            ),
            border: mio ? null : Border.all(color: C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(m.texto, style: const TextStyle(fontSize: 15, height: 1.4)),
              if (cat != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProListScreen(categoria: cat)),
                    ),
                    icon: Icon(iconoDeCategoria(cat.nombre), size: 18),
                    label: Text('Ver profesionales de ${cat.nombre}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bienvenida(bool esTrabajador) {
    final sugerencias = esTrabajador ? _sugerenciasTrabajador : _sugerenciasCliente;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const Center(child: Icon(Icons.auto_awesome, color: C.light, size: 48)),
        const SizedBox(height: 14),
        Text(
          esTrabajador ? '¿En qué te ayudo con tu trabajo?' : '¿Qué problema tienes en casa?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          esTrabajador
              ? 'Pregúntame sobre cotizaciones, mensajes para tus clientes o cómo describir tus servicios.'
              : 'Cuéntame qué pasa y te digo qué hacer mientras tanto y qué profesional necesitas.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: C.muted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        for (final s in sugerencias)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _enviar(s),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: cardDeco(14),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: C.light, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Las respuestas las genera una IA y pueden tener errores. '
          'Ante una emergencia (gas, cables expuestos, inundación) llama al 911.',
          textAlign: TextAlign.center,
          style: TextStyle(color: C.muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final esTrabajador =
        context.select<AuthProvider, bool>((a) => a.usuario?.esTrabajador ?? false);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: C.light, size: 20),
            SizedBox(width: 8),
            Text('Asistente IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (_mensajes.isNotEmpty)
            IconButton(
              tooltip: 'Nueva conversación',
              icon: const Icon(Icons.refresh),
              onPressed: _pensando
                  ? null
                  : () => setState(() {
                        _mensajes.clear();
                        _error = null;
                      }),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _mensajes.isEmpty
                  ? _bienvenida(esTrabajador)
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      children: [
                        for (final m in _mensajes) _burbuja(m),
                        if (_pensando)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Pensando…', style: TextStyle(color: C.muted)),
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
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
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: inputDeco('Escribe tu pregunta…').copyWith(counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _pensando ? null : _enviar,
                    icon: const Icon(Icons.send),
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
