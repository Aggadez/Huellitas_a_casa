import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:huellitas_a_casa/core/theme/app_colors.dart';
import 'package:huellitas_a_casa/data/repositories/reports_repository.dart';
import 'package:huellitas_a_casa/presentation/providers/app_providers.dart';
import 'package:huellitas_a_casa/presentation/widgets/report_details_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setInitialPosition());
  }

  Future<void> _setInitialPosition() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPositionWithDisclosure(context);
      final point = GeoPoint(position.latitude, position.longitude);
      ref.read(centerPointProvider.notifier).value = point;

      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.critical,
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerPoint = ref.watch(centerPointProvider);
    final reportState = ref.watch(nearbyReportsProvider);
    final markers = reportState.when(
      data: _buildMarkers,
      loading: () => <Marker>{},
      error: (_, _) => <Marker>{},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa comunitario'),
        actions: [
          IconButton(
            tooltip: 'Actualizar ubicación',
            onPressed: _setInitialPosition,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: centerPoint == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(centerPoint.latitude, centerPoint.longitude),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: markers,
                  onMapCreated: (controller) => _controller = controller,
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: reportState.when(
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(width: 8),
                            Text('Cargando reportes cercanos...'),
                          ],
                        ),
                      ),
                    ),
                    error: (error, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Error al cargar reportes: $error',
                          style: const TextStyle(color: AppColors.critical),
                        ),
                      ),
                    ),
                    data: (reports) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${reports.length} reportes en tu radio de acción.',
                          style: const TextStyle(color: AppColors.bodyText),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Set<Marker> _buildMarkers(List<MapReport> reports) {
    return reports
        .map(
          (report) => Marker(
            markerId: MarkerId(report.reportKey),
            position: LatLng(report.location.latitude, report.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              report.isReunited
                  ? BitmapDescriptor.hueYellow
                  : report.type == 'lost'
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueAzure,
            ),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ReportDetailsSheet(report: report),
            ),
          ),
        )
        .toSet();
  }
}
