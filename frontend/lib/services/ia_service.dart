import 'package:manocerca/core/models/categoria.dart';
import 'package:manocerca/services/api_client.dart';

/// Un mensaje de la conversación con el asistente.
class MensajeIA {
  final bool deUsuario;
  final String texto;

  /// Oficio que el asistente sugiere para este problema (solo clientes).
  final Categoria? categoria;

  const MensajeIA({required this.deUsuario, required this.texto, this.categoria});
}

/// Tipos de texto que puede mejorar la IA (ver backend: POST /api/ia/mejorar-texto).
class TipoTextoIA {
  static const publicacion = 'publicacion';
  static const servicio = 'servicio';
  static const biografia = 'biografia';
  static const solicitud = 'solicitud';
}

class IaService {
  IaService(this._api);
  final ApiClient _api;

  static const _espera = Duration(seconds: 40);

  /// Manda la conversación y devuelve la respuesta del asistente.
  Future<MensajeIA> preguntar(List<MensajeIA> historial) async {
    final r = await _api.post(
      '/ia/asistente',
      espera: _espera,
      body: {
        'mensajes': [
          for (final m in historial)
            {'rol': m.deUsuario ? 'usuario' : 'asistente', 'texto': m.texto},
        ],
      },
    );
    final data = r['data'];
    if (data is! Map<String, dynamic> || data['respuesta'] is! String) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    final cat = data['categoria'];
    return MensajeIA(
      deUsuario: false,
      texto: data['respuesta'] as String,
      categoria: cat is Map<String, dynamic> ? Categoria.fromJson(cat) : null,
    );
  }

  /// Resumen con IA de lo que dicen las reseñas de un trabajador.
  /// [resumen] es null si aún no hay suficientes reseñas; [motivo] lo explica.
  Future<({String? resumen, String? motivo})> resumenResenas(int idTrabajador) async {
    final r = await _api.get('/ia/resumen-resenas/$idTrabajador', espera: _espera);
    final data = r['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return (resumen: data['resumen'] as String?, motivo: data['motivo'] as String?);
  }

  /// Devuelve una versión mejorada de [texto].
  Future<String> mejorarTexto({
    required String texto,
    required String tipo,
    String? titulo,
    String? categoria,
  }) async {
    final r = await _api.post(
      '/ia/mejorar-texto',
      espera: _espera,
      body: {
        'texto': texto,
        'tipo': tipo,
        if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      },
    );
    final data = r['data'];
    if (data is! Map<String, dynamic> || data['texto'] is! String) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return data['texto'] as String;
  }
}
