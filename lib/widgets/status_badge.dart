import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.active = true});

  final String status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isWarning =
        normalized.contains('manuten') ||
        normalized.contains('aten') ||
        normalized.contains('reparo');
    final isDanger =
        !active ||
        normalized.contains('inativ') ||
        normalized.contains('crít') ||
        normalized.contains('crit');
    final color = isDanger
        ? AppColors.danger
        : isWarning
        ? AppColors.warning
        : AppColors.success;

    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.isEmpty ? (active ? 'Ativo' : 'Inativo') : status,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
