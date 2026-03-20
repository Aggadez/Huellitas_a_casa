import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPositionWithDisclosure(BuildContext context) async {
    final accepted = await _showDisclosure(context);
    if (!accepted) {
      throw Exception('Debes aceptar el aviso de ubicación para continuar.');
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Activa el GPS para continuar.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<bool> _showDisclosure(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uso de ubicación'),
          content: const Text(
            'Necesitamos tu ubicación para mostrarte mascotas perdidas cerca de ti y avisarte de avistamientos en tu zona.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );

    return accepted ?? false;
  }
}
