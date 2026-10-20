import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';
import '../widgets/app_states.dart';
import '../widgets/category_visuals.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.service, required this.user});

  final DashboardService service;
  final AppUser user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  String? _error;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final summary = await widget.service.loadSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _updatedAt = DateTime.now();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.displayMessage);
    } on FormatException {
      if (mounted) {
        setState(() => _error = 'O servidor enviou dados inesperados.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível abrir o dashboard.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null && _error == null) {
      return const AppLoadingState(label: 'Carregando dashboard...');
    }
    if (_summary == null) {
      return AppErrorState(message: _error!, onRetry: _load);
    }

    final summary = _summary!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          _DashboardGreeting(user: widget.user, updatedAt: _updatedAt),
          const SizedBox(height: 20),
          _MetricsGrid(summary: summary),
          const SizedBox(height: 18),
          _CategoryTotalsCard(counts: summary.totals),
          const SizedBox(height: 18),
          _DistributionCard(entries: summary.distribution),
          const SizedBox(height: 18),
          _CriticalItemsCard(items: summary.criticalItems),
          const SizedBox(height: 18),
          _ActivitiesCard(activities: summary.activities),
        ],
      ),
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting({required this.user, required this.updatedAt});

  final AppUser user;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${user.firstName.isEmpty ? 'usuário' : user.firstName}',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Este é o panorama atual dos ativos de TI.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (updatedAt != null)
          Tooltip(
            message: 'Última atualização',
            child: Text(
              '${_twoDigits(updatedAt!.hour)}:${_twoDigits(updatedAt!.minute)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 2;
        final aspectRatio = constraints.maxWidth < 390 ? 1.18 : 1.45;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            MetricCard(
              label: 'Total de ativos',
              value: summary.totals.total.toString(),
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
            ),
            MetricCard(
              label: 'Ativos em uso',
              value: summary.activeTotal.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
            MetricCard(
              label: 'Em manutenção',
              value: summary.maintenance.total.toString(),
              icon: Icons.build_outlined,
              color: AppColors.warning,
            ),
            MetricCard(
              label: 'Itens críticos',
              value: summary.criticalItems.length.toString(),
              icon: Icons.warning_amber_rounded,
              color: AppColors.danger,
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTotalsCard extends StatelessWidget {
  const _CategoryTotalsCard({required this.counts});

  final CategoryCounts counts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Ativos por categoria',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: counts.labeledValues.entries.map((entry) {
                final color = categoryColorForLabel(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${entry.value} ',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: entry.key),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.entries});

  final List<DistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Distribuição do inventário',
              icon: Icons.bar_chart,
            ),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              const Text(
                'Ainda não há dados para exibir.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              ...entries.map((entry) {
                final progress = (entry.percentage / 100).clamp(0.0, 1.0);
                final color = categoryColorForLabel(entry.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.quantity}  •  ${entry.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(20),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.11),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CriticalItemsCard extends StatelessWidget {
  const _CriticalItemsCard({required this.items});

  final List<CriticalItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Itens que exigem atenção',
              icon: Icons.report_problem_outlined,
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(child: Text('Nenhum item crítico no momento.')),
                  ],
                ),
              )
            else
              ...items
                  .take(6)
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: categoryColorForLabel(item.category)
                            .withValues(alpha: 0.12),
                        foregroundColor: categoryColorForLabel(item.category),
                        child: const Icon(
                          Icons.devices_other_outlined,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          item.category,
                          item.code,
                        ].where((value) => value.isNotEmpty).join(' • '),
                      ),
                      trailing: StatusBadge(
                        status: item.status,
                        active: item.active,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActivitiesCard extends StatelessWidget {
  const _ActivitiesCard({required this.activities});

  final List<RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Atividades recentes',
              icon: Icons.history,
            ),
            const SizedBox(height: 10),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Nenhuma atividade recente.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...activities
                  .take(8)
                  .map(
                    (activity) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: categoryColorForLabel(activity.category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        activity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          activity.category,
                          activity.user,
                          if (activity.acquiredAt != null)
                            _formatDate(activity.acquiredAt!),
                        ].where((value) => value.isNotEmpty).join(' • '),
                      ),
                      trailing: StatusBadge(status: activity.status),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.blue),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year}';
}
