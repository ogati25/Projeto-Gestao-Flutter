import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/inventory_form_schema.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../widgets/app_states.dart';
import '../widgets/category_visuals.dart';
import '../widgets/status_badge.dart';
import 'inventory_detail_screen.dart';
import 'inventory_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.service,
    required this.defaultOwner,
    required this.defaultDepartment,
  });

  final InventoryService service;
  final String defaultOwner;
  final String defaultDepartment;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  InventoryCategory _category = InventoryCategory.computers;
  List<InventoryItem>? _items;
  String? _error;
  String _query = '';
  int _loadGeneration = 0;
  final Set<String> _busyItemIds = <String>{};

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

  Future<void> _load({bool showLoading = false}) async {
    final generation = ++_loadGeneration;
    final category = _category;
    setState(() {
      _error = null;
      if (showLoading) _items = null;
    });
    try {
      final items = await widget.service.list(category);
      if (!mounted || generation != _loadGeneration || category != _category) {
        return;
      }
      setState(() => _items = items);
    } on ApiException catch (error) {
      if (mounted && generation == _loadGeneration && category == _category) {
        setState(() => _error = error.displayMessage);
      }
    } on FormatException {
      if (mounted && generation == _loadGeneration && category == _category) {
        setState(() => _error = 'O servidor enviou dados inesperados.');
      }
    } catch (_) {
      if (mounted && generation == _loadGeneration && category == _category) {
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
    await _load(showLoading: true);
  }

  Future<void> _openDetails(InventoryItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InventoryDetailScreen(item: item),
      ),
    );
  }

  Future<void> _createItem() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => InventoryFormScreen(
          service: widget.service,
          category: _category,
          defaultOwner: widget.defaultOwner,
          defaultDepartment: widget.defaultDepartment,
        ),
      ),
    );
    if (created != true || !mounted) return;
    await _load();
    if (mounted) _showMessage('Item cadastrado com sucesso.');
  }

  Future<void> _editItem(InventoryItem item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => InventoryFormScreen(
          service: widget.service,
          category: item.category,
          item: item,
          defaultOwner: widget.defaultOwner,
          defaultDepartment: widget.defaultDepartment,
        ),
      ),
    );
    if (updated != true || !mounted) return;
    await _load();
    if (mounted) _showMessage('Item atualizado com sucesso.');
  }

  Future<void> _toggleItem(InventoryItem item) async {
    final payload = InventoryPayloadBuilder.writablePayload(
      item.category,
      item.raw,
    );
    payload['ativo'] = !item.active;
    await _mutateItem(
      item,
      operation: () => widget.service.update(item.category, item.id, payload),
      successMessage: item.active
          ? 'Item inativado com sucesso.'
          : 'Item ativado com sucesso.',
    );
  }

  Future<void> _confirmDelete(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
        title: const Text('Excluir item?'),
        content: Text(
          '“${item.title}” será removido definitivamente do inventário. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutateItem(
      item,
      operation: () => widget.service.delete(item.category, item.id),
      successMessage: 'Item excluído com sucesso.',
    );
  }

  Future<void> _mutateItem(
    InventoryItem item, {
    required Future<void> Function() operation,
    required String successMessage,
  }) async {
    if (item.id.isEmpty || _busyItemIds.contains(item.id)) return;
    setState(() => _busyItemIds.add(item.id));
    try {
      await operation();
      await _load();
      if (mounted) _showMessage(successMessage);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.displayMessage, isError: true);
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível concluir a operação.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(item.id));
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createItem,
        icon: const Icon(Icons.add),
        label: Text('Novo ${_category.singularLabel.toLowerCase()}'),
      ),
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
          return _InventoryCard(
            item: item,
            busy: _busyItemIds.contains(item.id),
            onTap: () => _openDetails(item),
            onEdit: () => _editItem(item),
            onToggle: () => _toggleItem(item),
            onDelete: () => _confirmDelete(item),
          );
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
  const _InventoryCard({
    required this.item,
    required this.busy,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final InventoryItem item;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: busy ? 0.58 : 1,
      duration: const Duration(milliseconds: 180),
      child: Card(
        child: InkWell(
          onTap: busy ? null : onTap,
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
                if (busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                else
                  PopupMenuButton<_InventoryAction>(
                    tooltip: 'Ações do item',
                    onSelected: (action) {
                      switch (action) {
                        case _InventoryAction.edit:
                          onEdit();
                        case _InventoryAction.toggle:
                          onToggle();
                        case _InventoryAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _InventoryAction.edit,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _InventoryAction.toggle,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.active
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                          ),
                          title: Text(item.active ? 'Inativar' : 'Ativar'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: _InventoryAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                          title: Text(
                            'Excluir',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _InventoryAction { edit, toggle, delete }
