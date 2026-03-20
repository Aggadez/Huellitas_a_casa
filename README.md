# Huellitas a casa

Aplicación comunitaria altruista para reportar mascotas perdidas y avistamientos en tiempo real.

## Stack

- Flutter + Riverpod
- Firebase Auth, Firestore, Storage, FCM
- Google Maps + geoqueries con `geoflutterfire2`

## Módulos implementados

- Registro/Login con aceptación obligatoria de Términos y Política.
- Modal de disclosure antes de pedir permisos nativos de ubicación.
- Mapa principal con pines por radio (geoqueries eficientes).
- BottomSheet de detalle con menú UGC: **Reportar publicación** y **Bloquear usuario**.
- Formularios: mascota perdida y avistamiento rápido.
- Preparación de trigger para FCM cercano en `notification_jobs`.
- Perfil con reportes propios, marcar reunificación y eliminación de cuenta/datos.

## Configuración mínima requerida

1. Configura Firebase para Android/iOS y agrega:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
2. Define `MAPS_API_KEY` para Android en `android/local.properties` o gradle env.
3. Ejecuta:

```bash
flutter pub get
flutter run
```

## Nota Cloud Functions

En `docs/cloud_functions_nearby_sighting.md` está el contrato para disparar FCM con título:

`¡Avistamiento cerca!`
