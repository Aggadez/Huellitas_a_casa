import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huellitas_a_casa/core/theme/app_colors.dart';
import 'package:huellitas_a_casa/presentation/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPets = ref.watch(myPetsProvider);
    final state = ref.watch(profileControllerProvider);

    ref.listen(profileControllerProvider, (_, next) {
      next.whenOrNull(
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
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(profileControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mis reportes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: myPets.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return const Center(child: Text('Aún no tienes reportes.'));
                  }
                  return ListView.separated(
                    itemCount: pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final pet = pets[index];
                      return Card(
                        child: ListTile(
                          title: Text(pet.name),
                          subtitle: Text(pet.description),
                          trailing: pet.reunited
                              ? const Text(
                                  '¡REUNIDA!',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: AppColors.secondary,
                                  ),
                                  onPressed: state.isLoading
                                      ? null
                                      : () => ref
                                          .read(profileControllerProvider.notifier)
                                          .markReunited(pet.id),
                                  child: const Text('Marcar reunida'),
                                ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar cuenta'),
                            content: const Text(
                              'Esta acción borrará tu cuenta, reportes y fotos asociadas de forma inmediata.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.critical,
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Sí, eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(profileControllerProvider.notifier)
                              .deleteAccountAndData();
                        }
                      },
                child: state.isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Eliminar cuenta y todos mis datos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
