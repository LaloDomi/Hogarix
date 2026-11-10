import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:provider/provider.dart';

class ConfirmedScreen extends StatelessWidget {
  final String nombreTrabajador;
  final String servicio;
  const ConfirmedScreen({
    super.key,
    required this.nombreTrabajador,
    required this.servicio,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      ['Solicitud enviada', 'Hoy, ${horaTexto(DateTime.now())}', true],
      ['$nombreTrabajador la acepta', 'En espera', false],
      ['Servicio en proceso', '', false],
      ['Servicio completado y calificación', '', false],
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud enviada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: cardDeco(18),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.event_available, size: 72, color: C.primary),
                    const SizedBox(height: 10),
                    const Text('¡Listo!',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Tu solicitud de $servicio fue enviada',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: C.muted, fontSize: 14)),
                    const SizedBox(height: 26),
                    for (int i = 0; i < steps.length; i++)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: steps[i][2] as bool
                                        ? C.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: steps[i][2] as bool
                                            ? C.primary
                                            : C.light,
                                        width: 1.5),
                                  ),
                                  child: steps[i][2] as bool
                                      ? const Icon(Icons.check,
                                          size: 15, color: Colors.white)
                                      : null,
                                ),
                                if (i != steps.length - 1)
                                  Expanded(
                                    child: Container(width: 1.5, color: C.border),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(steps[i][0] as String,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    if ((steps[i][1] as String).isNotEmpty)
                                      Text(steps[i][1] as String,
                                          style: const TextStyle(
                                              color: C.muted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlineButtonX(
              text: 'Ver mis solicitudes',
              icon: Icons.assignment_outlined,
              onTap: () {
                final shell = context.read<ShellController>();
                Navigator.of(context).popUntil((r) => r.isFirst);
                shell.ir(3); // Solicitudes del cliente
              },
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              text: 'Volver al inicio',
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
