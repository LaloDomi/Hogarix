import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/screens/ubicacion/ubicacion_sheet.dart';

/// Tarjeta que invita a elegir la ubicación cuando todavía no hay una.
class AvisoUbicacion extends StatelessWidget {
  const AvisoUbicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x222F8BFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => editarUbicacion(context),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: C.light, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agrega tu ubicación',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Para ver primero a los profesionales de tu zona.',
                        style: TextStyle(color: C.muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: C.light),
            ],
          ),
        ),
      ),
    );
  }
}
