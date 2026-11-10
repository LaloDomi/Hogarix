import 'package:flutter/material.dart';
import 'package:manocerca/app.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:provider/provider.dart';

void main() {
  final api = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..restaurarSesion()),
        ChangeNotifierProvider(create: (_) => CategoriasProvider(api)),
      ],
      child: const Hogarix(),
    ),
  );
}
