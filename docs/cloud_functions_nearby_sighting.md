# Cloud Function: notificar avistamientos cercanos

Cuando la app crea un avistamiento, también crea un documento en `notification_jobs` con:

- `type: nearby_sighting`
- `sightingId`
- `radiusKm: 2`
- `title: "¡Avistamiento cerca!"`

Implementa una Cloud Function `onCreate` para esa colección:

1. Lee el `sightingId` en `sightings/{id}`.
2. Obtén su `position.geopoint`.
3. Ejecuta una geoquery de usuarios dentro de 2 km (colección `users` con ubicación geohash/geopoint).
4. Envía FCM con título `¡Avistamiento cerca!`.

Ejemplo de payload:

```json
{
  "notification": {
    "title": "¡Avistamiento cerca!",
    "body": "Se reportó un posible avistamiento en tu zona."
  },
  "data": {
    "type": "sighting",
    "sightingId": "abc123"
  }
}
```
