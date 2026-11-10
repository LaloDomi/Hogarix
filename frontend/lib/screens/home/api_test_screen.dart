
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  late Future<Map<String, dynamic>> resultado;

  @override
  void initState() {
    super.initState();
    resultado = ApiService.obtenerCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de conexión'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: resultado,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Error de conexión:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                snapshot.data.toString(),
              ),
            );
          },
        ),
      ),
    );
  }
}
