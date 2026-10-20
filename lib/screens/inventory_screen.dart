import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../widgets/app_states.dart';
import '../widgets/category_visuals.dart';
import '../widgets/status_badge.dart';
import 'inventory_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.service});

  final InventoryService service;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  InventoryCategory _category = InventoryCategory.computers;
  List<InventoryItem>? _items;
  String? _error;
  String _query = '';

  List<InventoryItem> get _filteredItems {
    final items = _items ?? const <InventoryItem>[];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) => item.searchableText.contains(query)).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await widget.service.list(_category);
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.displayMessage);
    } on FormatException {
      if (mounted) {
        setState(() => _error = 'O servidor enviou dados inesperados.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível abrir o inventário.');
      }
    }
  }

  Future<void> _selectCategory(InventoryCategory category) async {
    if (category == _category) return;
    setState(() {
      _category = category;
      _items = null;
      _error = null;
      _query = '';
      _searchController.clear();
    });
    await _load();
  }

  void _openDetails(InventoryItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InventoryDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryPicker(selected: _category, onSelected: _selectCategory),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Buscar em ${_category.label.toLowerCase()}...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_items == null && _error == null) {
      return AppLoadingState(
        label: 'Carregando ${_category.label.toLowerCase()}...',
      );
    }
    if (_items == null) {
      return AppErrorState(message: _error!, onRetry: _load);
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 380,
              child: AppEmptyState(
                title: _query.isEmpty
                    ? 'Nenhum item cadastrado'
                    : 'Nada encontrado',
                message: _query.isEmpty
                    ? 'A categoria ${_category.label.toLowerCase()} ainda está vazia.'
                    : 'Tente buscar por outro termo.',
                icon: _category.icon,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 6 : 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${items.length} ${items.length == 1 ? 'registro' : 'registros'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            );
          }
          final item = items[index - 1];
          return _InventoryCard(item: item, onTap: () => _openDetails(item));
        },
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelected});

  final InventoryCategory selected;
  final ValueChanged<InventoryCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: 66,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          scrollDirection: Axis.horizontal,
          itemCount: InventoryCategory.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = InventoryCategory.values[index];
            final isSelected = category == selected;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) => onSelected(category),
              avatar: Icon(
                category.icon,
                size: 18,
                color: isSelected ? Colors.white : category.color,
              ),
              label: Text(category.label),
              showCheckmark: false,
              selectedColor: category.color,
              backgroundColor: category.color.withValues(alpha: 0.08),
              side: BorderSide(color: category.color.withValues(alpha: 0.22)),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.text,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.category.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.category.icon, color: item.category.color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.code.isNotEmpty) item.code,
                        item.department,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusBadge(status: item.status, active: item.active),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
