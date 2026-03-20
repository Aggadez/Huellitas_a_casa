import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:huellitas_a_casa/core/theme/app_colors.dart';
import 'package:huellitas_a_casa/presentation/providers/app_providers.dart';

class ReportFormsScreen extends ConsumerStatefulWidget {
  const ReportFormsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ReportFormsScreen> createState() => _ReportFormsScreenState();
}

class _ReportFormsScreenState extends ConsumerState<ReportFormsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  final _lostFormKey = GlobalKey<FormState>();
  final _sightingFormKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _speciesLostCtrl = TextEditingController();
  final _descriptionLostCtrl = TextEditingController();
  DateTime _lostDate = DateTime.now();
  GeoPoint? _lostLocation;
  File? _lostImage;

  final _speciesSightingCtrl = TextEditingController();
  final _descriptionSightingCtrl = TextEditingController();
  GeoPoint? _sightingLocation;
  File? _sightingImage;

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _speciesLostCtrl.dispose();
    _descriptionLostCtrl.dispose();
    _speciesSightingCtrl.dispose();
    _descriptionSightingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    ref.listen(reportControllerProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte guardado correctamente.')),
        ),
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.critical,
            content: Text(error.toString()),
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mascota perdida'),
            Tab(text: 'Avistamiento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLostForm(state.isLoading),
          _buildSightingForm(state.isLoading),
        ],
      ),
    );
  }

  Widget _buildLostForm(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _lostFormKey,
        child: Column(
          children: [
            _ImagePickerTile(
              title: 'Foto de la mascota',
              file: _lostImage,
              onPick: () async => setState(() => _lostImage = null),
              picker: (file) => setState(() => _lostImage = file),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speciesLostCtrl,
              decoration: const InputDecoration(labelText: 'Especie'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionLostCtrl,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text('Fecha de pérdida: ${DateFormat('dd/MM/yyyy').format(_lostDate)}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: _lostDate,
                );
                if (selected != null) setState(() => _lostDate = selected);
              },
            ),
            const SizedBox(height: 12),
            _LocationTile(
              title: 'Ubicación exacta',
              location: _lostLocation,
              onSetCurrentLocation: () async {
                final position = await ref
                    .read(locationServiceProvider)
                    .getCurrentPositionWithDisclosure(context);
                setState(() {
                  _lostLocation = GeoPoint(position.latitude, position.longitude);
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submitLostPet,
                child: loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Publicar mascota perdida'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSightingForm(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _sightingFormKey,
        child: Column(
          children: [
            _ImagePickerTile(
              title: 'Foto del avistamiento',
              file: _sightingImage,
              onPick: () async => setState(() => _sightingImage = null),
              picker: (file) => setState(() => _sightingImage = file),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speciesSightingCtrl,
              decoration: const InputDecoration(labelText: 'Especie sospechada'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionSightingCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción rápida'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            _LocationTile(
              title: 'Ubicación exacta del avistamiento',
              location: _sightingLocation,
              onSetCurrentLocation: () async {
                final position = await ref
                    .read(locationServiceProvider)
                    .getCurrentPositionWithDisclosure(context);
                setState(() {
                  _sightingLocation = GeoPoint(position.latitude, position.longitude);
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submitSighting,
                style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                child: loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Publicar avistamiento'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLostPet() async {
    if (_lostFormKey.currentState?.validate() != true) return;
    if (_lostImage == null || _lostLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.critical,
          content: Text('Debes incluir foto y ubicación.'),
        ),
      );
      return;
    }
    await ref.read(reportControllerProvider.notifier).createLostPet(
          name: _nameCtrl.text.trim(),
          species: _speciesLostCtrl.text.trim(),
          description: _descriptionLostCtrl.text.trim(),
          lostAt: _lostDate,
          location: _lostLocation!,
          imageFile: _lostImage!,
        );
  }

  Future<void> _submitSighting() async {
    if (_sightingFormKey.currentState?.validate() != true) return;
    if (_sightingImage == null || _sightingLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.critical,
          content: Text('Debes incluir foto y ubicación.'),
        ),
      );
      return;
    }
    await ref.read(reportControllerProvider.notifier).createSighting(
          species: _speciesSightingCtrl.text.trim(),
          description: _descriptionSightingCtrl.text.trim(),
          location: _sightingLocation!,
          imageFile: _sightingImage!,
        );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.title,
    required this.file,
    required this.onPick,
    required this.picker,
  });

  final String title;
  final File? file;
  final Future<void> Function() onPick;
  final ValueChanged<File> picker;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(file == null ? 'Selecciona una imagen' : 'Imagen cargada'),
        trailing: const Icon(Icons.photo_camera_outlined),
        onTap: () async {
          await onPick();
          final picked = await ImagePicker().pickImage(source: ImageSource.camera);
          if (picked != null) picker(File(picked.path));
        },
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.title,
    required this.location,
    required this.onSetCurrentLocation,
  });

  final String title;
  final GeoPoint? location;
  final Future<void> Function() onSetCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          location == null
              ? 'Sin ubicación seleccionada'
              : 'Lat: ${location!.latitude.toStringAsFixed(5)}, Lng: ${location!.longitude.toStringAsFixed(5)}',
        ),
        trailing: const Icon(Icons.pin_drop_outlined),
        onTap: onSetCurrentLocation,
      ),
    );
  }
}
