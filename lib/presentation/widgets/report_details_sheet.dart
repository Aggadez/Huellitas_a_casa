import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huellitas_a_casa/core/theme/app_colors.dart';
import 'package:huellitas_a_casa/data/repositories/reports_repository.dart';
import 'package:huellitas_a_casa/presentation/providers/app_providers.dart';

class ReportDetailsSheet extends ConsumerWidget {
  const ReportDetailsSheet({
    required this.report,
    super.key,
  });

  final MapReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: report.type == 'lost' ? AppColors.critical : AppColors.secondary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: Text('Reportar publicación'),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Text('Bloquear usuario'),
                  ),
                ],
                onSelected: (value) async {
                  final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
                  if (uid == null) return;
                  final moderation = ref.read(moderationRepositoryProvider);
                  if (value == 'report') {
                    await moderation.reportPost(
                      actorUid: uid,
                      reportKey: report.reportKey,
                      ownerUid: report.ownerUid,
                      reason: 'contenido_inapropiado',
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Publicación reportada y ocultada.')),
                      );
                    }
                  } else {
                    await moderation.blockUser(actorUid: uid, blockedUid: report.ownerUid);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario bloqueado y publicaciones ocultas.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (report.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                report.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            report.description,
            style: const TextStyle(color: AppColors.bodyText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contacta vía chat interno (pendiente).')),
                    );
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondary),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
