import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../models/inventory_form_schema.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../widgets/category_visuals.dart';

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({
    super.key,
    required this.service,
    required this.category,
    required this.defaultOwner,
    required this.defaultDepartment,
    this.item,
  });

  final InventoryService service;
  final InventoryCategory category;
  final String defaultOwner;
  final String defaultDepartment;
  final InventoryItem? item;

  bool get isEditing => item != null;

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  static const _fallbackStatuses = <String>[
    'EmUso',
    'EmEstoque',
    'EmManutenção',
    'NecessitaManutenção',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ownerController;
  late final TextEditingController _dateController;
  late final TextEditingController _priceController;
  late final TextEditingController _departmentController;
  late final TextEditingController _observationsController;
  final _fieldControllers = <String, TextEditingController>{};
  final _toggles = <String, bool>{};
  final _options = <String, List<String>>{};
  List<InventoryLookupItem> _processors = const [];
  List<InventoryLookupItem> _phones = const [];
  List<InventoryLookupItem> _chips = const [];
  List<String> _ramModules = [];
  List<_ComponentValue> _disks = [];
  List<_ComponentValue> _videoCards = [];
  List<String> _videoConnectors = [];
  List<String> _selectedChipIds = [];
  List<String> _selectedWhatsappIds = [];

  late DateTime _acquisitionDate;
  late String _status;
  late bool _active;
  bool _submitting = false;
  bool _loadingLookups = true;
  String? _lookupError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final initial = InventoryPayloadBuilder.writablePayload(
      widget.category,
      widget.item?.raw,
    );

    _ownerController = TextEditingController(
      text: _valueOrDefault(initial['usuario'], widget.defaultOwner),
    );
    _departmentController = TextEditingController(
      text: _valueOrDefault(initial['setor'], widget.defaultDepartment),
    );
    _priceController = TextEditingController(
      text: _formatNumber(initial['precoAquisicao']),
    );
    _observationsController = TextEditingController(
      text: initial['observacoes']?.toString() ?? '',
    );
    _active = initial['ativo'] != false;
    _status = _valueOrDefault(initial['status'], 'EmEstoque');
    _acquisitionDate = _parseDate(initial['dataAquisicao']);
    _dateController = TextEditingController(
      text: _formatDate(_acquisitionDate),
    );

    for (final field in inventoryFieldsFor(widget.category)) {
      if (field.kind == InventoryFieldKind.boolean) {
        _toggles[field.key] = initial[field.key] == true;
      } else {
        _fieldControllers[field.key] = TextEditingController(
          text: InventoryPayloadBuilder.initialText(initial, field),
        );
      }
    }
    _initializeStructuredValues(initial);
    _loadLookups();
  }

  void _initializeStructuredValues(Map<String, dynamic> initial) {
    if (widget.category == InventoryCategory.computers) {
      _ramModules = _asList(initial['memoriaRAM'])
          .map((value) => value.toString())
          .toList();
      _disks = _asList(initial['discos']).map(_componentFromDisk).toList();
      _videoCards = _asList(initial['placasVideo'])
          .map(_componentFromVideoCard)
          .toList();
      _videoConnectors = _asList(initial['conectoresVideo'])
          .map((value) => value.toString())
          .toList();
    }
    if (widget.category == InventoryCategory.phones) {
      _selectedChipIds = _stringIds(initial['chipIds']);
      _selectedWhatsappIds = _stringIds(initial['contasWhatsapp']);
      _syncRelationControllers();
    }
  }

  Future<void> _loadLookups() async {
    var options = <String, List<String>>{};
    var processors = <InventoryLookupItem>[];
    var phones = <InventoryLookupItem>[];
    var chips = <InventoryLookupItem>[];
    final failedLists = <String>[];

    try {
      options = await widget.service.loadOptions();
    } catch (_) {
      failedLists.add('opções');
    }
    if (widget.category == InventoryCategory.computers) {
      try {
        processors = await widget.service.listProcessors();
      } catch (_) {
        failedLists.add('processadores');
      }
    }
    if (widget.category == InventoryCategory.simCards) {
      try {
        phones = await widget.service.listPhones();
      } catch (_) {
        failedLists.add('celulares');
      }
    }
    if (widget.category == InventoryCategory.phones) {
      try {
        chips = await widget.service.listChips();
      } catch (_) {
        failedLists.add('chips');
      }
    }

    if (!mounted) return;
    setState(() {
      _options
        ..clear()
        ..addAll(options);
      _processors = processors;
      _phones = phones;
      _chips = chips;
      _loadingLookups = false;
      _lookupError = failedLists.isEmpty
          ? null
          : 'Não foi possível carregar: ${failedLists.join(', ')}. Tente novamente.';
    });
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _departmentController.dispose();
    _observationsController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _acquisitionDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      helpText: 'Data de aquisição',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _acquisitionDate = selected;
      _dateController.text = _formatDate(selected);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    var completed = false;

    try {
      _syncComputerControllers();
      _syncRelationControllers();
      final inputs = _fieldControllers.map(
        (key, controller) => MapEntry(key, controller.text),
      );
      final payload = InventoryPayloadBuilder.build(
        category: widget.category,
        owner: _ownerController.text,
        acquisitionDate: _acquisitionDate,
        acquisitionPrice: _priceController.text,
        active: _active,
        department: _departmentController.text,
        status: _status,
        observations: _observationsController.text,
        inputs: inputs,
        toggles: _toggles,
        existingRaw: widget.item?.raw,
      );

      if (widget.isEditing) {
        await widget.service.update(widget.category, widget.item!.id, payload);
      } else {
        await widget.service.create(widget.category, payload);
      }

      if (!mounted) return;
      completed = true;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.displayMessage);
    } on FormatException catch (error) {
      if (mounted) setState(() => _submitError = error.message.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _submitError = 'Não foi possível salvar o item.');
      }
    } finally {
      if (mounted && !completed) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category.color;
    final noun = _categoryNoun(widget.category);
    final title = widget.isEditing ? 'Editar $noun' : 'Novo $noun';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormHeader(
                      icon: widget.category.icon,
                      color: categoryColor,
                      title: title,
                      code: widget.item?.code,
                    ),
                    if (_loadingLookups) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    if (_lookupError != null) ...[
                      const SizedBox(height: 12),
                      _InlineError(message: _lookupError!),
                    ],
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Dados principais',
                      icon: Icons.assignment_outlined,
                      children: [
                        TextFormField(
                          controller: _ownerController,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Usuário',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) => _requiredText(
                            value,
                            label: 'o usuário',
                            maximumLength: 60,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'department-${_departmentValues.join('|')}',
                          ),
                          initialValue: _selectInitialValue(
                            _departmentController.text,
                            _departmentValues,
                          ),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Setor',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          items: _departmentValues.map(_dropdownItem).toList(),
                          onChanged: _submitting || _loadingLookups
                              ? null
                              : (value) =>
                                    _departmentController.text = value ?? '',
                          validator: (value) => value == null || value.isEmpty
                              ? 'Selecione o setor.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _dateController,
                          enabled: !_submitting,
                          readOnly: true,
                          onTap: _submitting ? null : _pickDate,
                          decoration: const InputDecoration(
                            labelText: 'Data de aquisição',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.edit_calendar_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _priceController,
                          enabled: !_submitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Preço de aquisição',
                            prefixText: 'R\$ ',
                            prefixIcon: Icon(Icons.payments_outlined),
                            hintText: '0,00',
                          ),
                          validator: _validatePrice,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'status-${_availableStatuses.join('|')}',
                          ),
                          initialValue: _status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: _availableStatuses
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_statusLabel(status)),
                                ),
                              )
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Selecione o status.'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Características de $noun',
                      icon: widget.category.icon,
                      children: _buildSpecificFields(),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Observações',
                      icon: Icons.notes_outlined,
                      children: [
                        TextFormField(
                          controller: _observationsController,
                          enabled: !_submitting,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Observações (opcional)',
                            alignLabelWithHint: true,
                            hintText: 'Informações adicionais sobre o item',
                          ),
                          validator: (value) => _maximumLength(
                            value,
                            label: 'Observações',
                            maximumLength: 2000,
                          ),
                        ),
                      ],
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: 16),
                      _InlineError(message: _submitError!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _submitting
                            ? 'Salvando...'
                            : widget.isEditing
                            ? 'Salvar alterações'
                            : 'Cadastrar item',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSpecificFields() {
    final widgets = <Widget>[];
    for (final field in inventoryFieldsFor(widget.category)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(_buildSpecificField(field));
    }
    return widgets;
  }

  Widget _buildSpecificField(InventoryFieldSpec field) {
    if (field.kind == InventoryFieldKind.boolean) {
      return SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(field.label),
        value: _toggles[field.key] ?? false,
        onChanged: _submitting
            ? null
            : (value) => setState(() => _toggles[field.key] = value),
      );
    }
    if (field.kind == InventoryFieldKind.select) {
      return _buildOptionSelect(field);
    }
    if (field.kind == InventoryFieldKind.processorSelect) {
      return _buildLookupSelect(field, _processors);
    }
    if (field.kind == InventoryFieldKind.phoneSelect) {
      return _buildLookupSelect(field, _phones);
    }
    if (field.kind == InventoryFieldKind.chipMultiSelect) {
      return _buildMultiLookupSelect(
        field: field,
        selected: _selectedChipIds,
        maximum: 2,
      );
    }
    if (field.kind == InventoryFieldKind.whatsappMultiSelect) {
      return _buildMultiLookupSelect(
        field: field,
        selected: _selectedWhatsappIds,
        maximum: 6,
      );
    }
    if (field.kind == InventoryFieldKind.integerList) {
      return _buildRamModules(field);
    }
    if (field.kind == InventoryFieldKind.disks) {
      return _buildComponentEditor(
        field: field,
        entries: _disks,
        typeOptions: _optionValues('TipoDisco'),
        amountLabel: 'Tamanho (GB)',
        maximum: 6,
      );
    }
    if (field.kind == InventoryFieldKind.videoCards) {
      return _buildComponentEditor(
        field: field,
        entries: _videoCards,
        typeOptions: _optionValues('TipoPlacaVideo'),
        amountLabel: 'VRAM (GB)',
        maximum: 4,
      );
    }
    if (field.kind == InventoryFieldKind.stringList) {
      return _buildConnectorEditor(field);
    }

    return TextFormField(
      controller: _fieldControllers[field.key],
      enabled: !_submitting,
      keyboardType: field.maxLines > 1
          ? TextInputType.multiline
          : _keyboardTypeFor(field.kind),
      textInputAction: field.maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      textCapitalization: _capitalizationFor(field.kind),
      minLines: field.maxLines > 1 ? 2 : 1,
      maxLines: field.maxLines,
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        hintText: field.hint,
        alignLabelWithHint: field.maxLines > 1,
        helperText: _helperFor(field.kind),
      ),
      validator: (value) => _validateSpecificField(field, value ?? ''),
    );
  }

  Widget _buildOptionSelect(InventoryFieldSpec field) {
    final controller = _fieldControllers[field.key]!;
    final values = _withCurrent(
      _optionValues(field.optionType ?? ''),
      controller.text,
    );
    return DropdownButtonFormField<String>(
      key: ValueKey('option-${field.key}-${values.join('|')}'),
      initialValue: _selectInitialValue(controller.text, values),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
      ),
      items: [
        if (!field.required)
          const DropdownMenuItem(value: '', child: Text('Nenhum')),
        ...values.map(_dropdownItem),
      ],
      onChanged: _submitting || _loadingLookups
          ? null
          : (value) => controller.text = value ?? '',
      validator: (value) => field.required && (value == null || value.isEmpty)
          ? 'Selecione ${field.label.toLowerCase()}.'
          : null,
    );
  }

  Widget _buildLookupSelect(
    InventoryFieldSpec field,
    List<InventoryLookupItem> items,
  ) {
    final controller = _fieldControllers[field.key]!;
    final current = controller.text.trim();
    final lookupItems = <InventoryLookupItem>[
      ...items,
      if (current.isNotEmpty && !items.any((item) => item.id == current))
        InventoryLookupItem(id: current, label: current, raw: const {}),
    ];
    return DropdownButtonFormField<String>(
      key: ValueKey('lookup-${field.key}-${lookupItems.length}-$current'),
      initialValue: current.isEmpty ? '' : current,
      isExpanded: true,
      decoration: InputDecoration(labelText: field.label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Nenhum')),
        ...lookupItems.map(
          (item) => DropdownMenuItem(
            value: item.id,
            child: Text(item.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: _submitting || _loadingLookups
          ? null
          : (value) => controller.text = value ?? '',
    );
  }

  Widget _buildMultiLookupSelect({
    required InventoryFieldSpec field,
    required List<String> selected,
    required int maximum,
  }) {
    final rows = <Widget>[];
    for (var index = 0; index < selected.length; index++) {
      final current = selected[index];
      final items = <InventoryLookupItem>[
        ..._chips,
        if (current.isNotEmpty && !_chips.any((item) => item.id == current))
          InventoryLookupItem(id: current, label: current, raw: const {}),
      ];
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${field.key}-$index-$current-${items.length}'),
                  initialValue: current.isEmpty ? null : current,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '${field.label} ${index + 1}',
                  ),
                  items: items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting || _loadingLookups
                      ? null
                      : (value) => setState(() {
                          selected[index] = value ?? '';
                          _syncRelationControllers();
                        }),
                ),
              ),
              IconButton(
                tooltip: 'Remover',
                onPressed: _submitting
                    ? null
                    : () => setState(() {
                        selected.removeAt(index);
                        _syncRelationControllers();
                      }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(field.label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...rows,
        if (selected.length < maximum)
          OutlinedButton.icon(
            onPressed: _submitting || _loadingLookups
                ? null
                : () => setState(() => selected.add('')),
            icon: const Icon(Icons.add),
            label: Text('Adicionar ${field.label}'),
          ),
      ],
    );
  }

  Widget _buildRamModules(InventoryFieldSpec field) {
    final configured = _optionValues('TipoMemoriaRAM');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _quantitySelect(
          label: 'Qtd. Slots',
          value: _ramModules.length,
          maximum: 8,
          onChanged: (count) => setState(() {
            while (_ramModules.length < count) {
              _ramModules.add('');
            }
            if (_ramModules.length > count) {
              _ramModules = _ramModules.sublist(0, count);
            }
            _syncComputerControllers();
          }),
        ),
        for (var index = 0; index < _ramModules.length; index++) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'ram-$index-${_ramModules[index]}-${configured.length}',
            ),
            initialValue: _selectInitialValue(
              _ramModules[index],
              _withCurrent(configured, _ramModules[index]),
            ),
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Memória Slot ${index + 1}'),
            items: _withCurrent(
              configured,
              _ramModules[index],
            ).map(_dropdownItem).toList(),
            onChanged: _submitting || _loadingLookups
                ? null
                : (value) => setState(() {
                    _ramModules[index] = value ?? '';
                    _syncComputerControllers();
                  }),
          ),
        ],
      ],
    );
  }

  Widget _buildComponentEditor({
    required InventoryFieldSpec field,
    required List<_ComponentValue> entries,
    required List<String> typeOptions,
    required String amountLabel,
    required int maximum,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _quantitySelect(
          label: field.kind == InventoryFieldKind.disks
              ? 'Qtd. Discos'
              : 'Qtd. GPUs',
          value: entries.length,
          maximum: maximum,
          onChanged: (count) => setState(() {
            while (entries.length < count) {
              entries.add(const _ComponentValue());
            }
            if (entries.length > count) {
              entries.removeRange(count, entries.length);
            }
            _syncComputerControllers();
          }),
        ),
        for (var index = 0; index < entries.length; index++) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    '${field.key}-type-$index-${entries[index].type}-${typeOptions.length}',
                  ),
                  initialValue: _selectInitialValue(
                    entries[index].type,
                    _withCurrent(typeOptions, entries[index].type),
                  ),
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'Tipo ${index + 1}'),
                  items: _withCurrent(
                    typeOptions,
                    entries[index].type,
                  ).map(_dropdownItem).toList(),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Selecione o tipo.'
                      : null,
                  onChanged: _submitting || _loadingLookups
                      ? null
                      : (value) => setState(() {
                          entries[index] = entries[index].copyWith(
                            type: value ?? '',
                          );
                          _syncComputerControllers();
                        }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey('${field.key}-amount-$index'),
                  initialValue: entries[index].amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: amountLabel),
                  onChanged: (value) {
                    entries[index] = entries[index].copyWith(amount: value);
                    _syncComputerControllers();
                  },
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Informe $amountLabel.';
                    }
                    return int.tryParse(value!.trim()) == null
                        ? 'Informe um número inteiro.'
                        : null;
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildConnectorEditor(InventoryFieldSpec field) {
    final options = _optionValues('TipoConectorVideo');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _quantitySelect(
          label: 'Qtd. Conectores',
          value: _videoConnectors.length,
          maximum: 6,
          onChanged: (count) => setState(() {
            while (_videoConnectors.length < count) {
              _videoConnectors.add('');
            }
            if (_videoConnectors.length > count) {
              _videoConnectors = _videoConnectors.sublist(0, count);
            }
            _syncComputerControllers();
          }),
        ),
        for (var index = 0; index < _videoConnectors.length; index++) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'connector-$index-${_videoConnectors[index]}-${options.length}',
            ),
            initialValue: _selectInitialValue(
              _videoConnectors[index],
              _withCurrent(options, _videoConnectors[index]),
            ),
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Conector ${index + 1}'),
            items: _withCurrent(
              options,
              _videoConnectors[index],
            ).map(_dropdownItem).toList(),
            onChanged: _submitting || _loadingLookups
                ? null
                : (value) => setState(() {
                    _videoConnectors[index] = value ?? '';
                    _syncComputerControllers();
                  }),
          ),
        ],
      ],
    );
  }

  Widget _quantitySelect({
    required String label,
    required int value,
    required int maximum,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value.clamp(0, maximum).toInt(),
      decoration: InputDecoration(labelText: label),
      items: [
        for (var count = 0; count <= maximum; count++)
          DropdownMenuItem(value: count, child: Text('$count')),
      ],
      onChanged: _submitting ? null : (selected) => onChanged(selected ?? 0),
    );
  }

  List<String> get _departmentOptions => _optionValues('Setor');

  List<String> get _departmentValues =>
      _withCurrent(_departmentOptions, _departmentController.text);

  List<String> get _availableStatuses {
    final statuses = _optionValues('Status');
    final base = statuses.isEmpty ? _fallbackStatuses : statuses;
    return _withCurrent(base, _status);
  }

  List<String> _optionValues(String type) =>
      _options[type.toLowerCase()] ?? const <String>[];

  DropdownMenuItem<String> _dropdownItem(String value) => DropdownMenuItem(
    value: value,
    child: Text(_optionLabel(value), overflow: TextOverflow.ellipsis),
  );

  List<String> _withCurrent(Iterable<String> values, String current) {
    final result = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final normalizedCurrent = current.trim();
    if (normalizedCurrent.isNotEmpty && !result.contains(normalizedCurrent)) {
      result.insert(0, normalizedCurrent);
    }
    return result;
  }

  String? _selectInitialValue(String value, List<String> options) {
    final normalized = value.trim();
    if (normalized.isEmpty || !options.contains(normalized)) return null;
    return normalized;
  }

  void _syncComputerControllers() {
    if (widget.category != InventoryCategory.computers) return;
    _fieldControllers['memoriaRAM']?.text = _ramModules
        .map((value) => RegExp(r'\d+').firstMatch(value)?.group(0) ?? value)
        .where((value) => value.isNotEmpty)
        .join(', ');
    _fieldControllers['discos']?.text = _disks
        .where((entry) => entry.type.isNotEmpty || entry.amount.isNotEmpty)
        .map((entry) => '${entry.type}:${entry.amount}')
        .join('; ');
    _fieldControllers['placasVideo']?.text = _videoCards
        .where((entry) => entry.type.isNotEmpty || entry.amount.isNotEmpty)
        .map((entry) => '${entry.type}:${entry.amount}')
        .join('; ');
    _fieldControllers['conectoresVideo']?.text = _videoConnectors
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  void _syncRelationControllers() {
    _fieldControllers['chipIds']?.text = _selectedChipIds
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(', ');
    _fieldControllers['contasWhatsapp']?.text = _selectedWhatsappIds
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(', ');
  }

  String? _validateSpecificField(InventoryFieldSpec field, String value) {
    final schemaError = InventoryPayloadBuilder.validateField(
      widget.category,
      field,
      value,
    );
    if (schemaError != null) return schemaError;

    final maximumLength = _specificMaximumLength(widget.category, field.key);
    if (maximumLength != null && value.trim().length > maximumLength) {
      return '${field.label} aceita no máximo $maximumLength caracteres.';
    }
    return null;
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.code,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final normalizedCode = code?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  normalizedCode.isEmpty
                      ? 'Preencha os dados para salvar no inventário.'
                      : 'Código $normalizedCode',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.blue, size: 22),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 21),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

String _valueOrDefault(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback.trim() : text;
}

DateTime _parseDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return DateTime.now();
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatNumber(dynamic value) {
  if (value is int) return value.toString();
  if (value is double && value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value?.toString().replaceAll('.', ',') ?? '0';
}

String? _requiredText(
  String? value, {
  required String label,
  required int maximumLength,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Informe $label.';
  if (text.length > maximumLength) {
    return 'O campo aceita no máximo $maximumLength caracteres.';
  }
  return null;
}

String? _maximumLength(
  String? value, {
  required String label,
  required int maximumLength,
}) {
  if ((value?.trim().length ?? 0) > maximumLength) {
    return '$label aceita no máximo $maximumLength caracteres.';
  }
  return null;
}

String? _validatePrice(String? value) {
  final normalized = (value ?? '').trim().replaceAll(',', '.');
  if (normalized.isEmpty) return 'Informe o preço de aquisição.';
  final parsed = double.tryParse(normalized);
  if (parsed == null) return 'Informe um preço válido.';
  if (parsed < 0) return 'O preço não pode ser negativo.';
  return null;
}

TextInputType _keyboardTypeFor(InventoryFieldKind kind) {
  return switch (kind) {
    InventoryFieldKind.integer => TextInputType.number,
    InventoryFieldKind.decimal => const TextInputType.numberWithOptions(
      decimal: true,
    ),
    _ => TextInputType.text,
  };
}

TextCapitalization _capitalizationFor(InventoryFieldKind kind) {
  return switch (kind) {
    InventoryFieldKind.integer ||
    InventoryFieldKind.decimal => TextCapitalization.none,
    _ => TextCapitalization.sentences,
  };
}

String? _helperFor(InventoryFieldKind kind) {
  return switch (kind) {
    InventoryFieldKind.integerList => 'Separe os valores por vírgula.',
    InventoryFieldKind.stringList => 'Separe os itens por vírgula.',
    InventoryFieldKind.disks ||
    InventoryFieldKind.videoCards => 'Separe cada item com ponto e vírgula.',
    _ => null,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'EmUso' => 'Em uso',
    'EmEstoque' => 'Em estoque',
    'EmManutenção' => 'Em manutenção',
    'NecessitaManutenção' => 'Necessita manutenção',
    _ => status,
  };
}

String _optionLabel(String value) {
  if (value.isEmpty) return 'Nenhum';
  return value
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-zá-ú])(?=[A-ZÁ-Ú])'), (_) => ' ');
}

List<dynamic> _asList(dynamic value) =>
    value is Iterable ? value.toList() : const <dynamic>[];

List<String> _stringIds(dynamic value) {
  return _asList(value)
      .map((entry) {
        if (entry is Map) {
          return (entry['id'] ?? entry['chipId'])?.toString() ?? '';
        }
        return entry.toString();
      })
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList();
}

_ComponentValue _componentFromDisk(dynamic value) {
  if (value is! Map) return const _ComponentValue();
  return _ComponentValue(
    type: value['tipo']?.toString() ?? '',
    amount: value['tamanho']?.toString() ?? '',
  );
}

_ComponentValue _componentFromVideoCard(dynamic value) {
  if (value is! Map) return const _ComponentValue();
  return _ComponentValue(
    type: value['tipo']?.toString() ?? '',
    amount: value['vram']?.toString() ?? '',
  );
}

class _ComponentValue {
  const _ComponentValue({this.type = '', this.amount = ''});

  final String type;
  final String amount;

  _ComponentValue copyWith({String? type, String? amount}) =>
      _ComponentValue(type: type ?? this.type, amount: amount ?? this.amount);
}

String _categoryNoun(InventoryCategory category) {
  return switch (category) {
    InventoryCategory.computers => 'computador',
    InventoryCategory.monitors => 'monitor',
    InventoryCategory.phones => 'celular',
    InventoryCategory.simCards => 'chip',
    InventoryCategory.mice => 'mouse',
    InventoryCategory.keyboards => 'teclado',
    InventoryCategory.headsets => 'fone',
    InventoryCategory.extensions => 'ramal',
    InventoryCategory.extras => 'item extra',
  };
}

int? _specificMaximumLength(InventoryCategory category, String key) {
  if (key == 'modelo') return 200;
  return switch ((category, key)) {
    (InventoryCategory.computers, 'tipo') => 80,
    (InventoryCategory.computers, 'geracaoRAM') => 40,
    (InventoryCategory.computers, 'sistemaOperacional') => 100,
    (InventoryCategory.computers, 'ativacaoSO') => 100,
    (InventoryCategory.computers, 'office') => 100,
    (InventoryCategory.computers, 'ativacaoOffice') => 100,
    (InventoryCategory.computers, 'ip') => 45,
    (InventoryCategory.monitors, 'resolucao') => 80,
    (InventoryCategory.phones, 'conectividade') => 80,
    (InventoryCategory.simCards, 'operadora') => 80,
    (InventoryCategory.simCards, 'numero') => 30,
    (InventoryCategory.simCards, 'dono') => 160,
    (InventoryCategory.simCards, 'celularId') => 64,
    (InventoryCategory.mice, 'tipo') => 80,
    (InventoryCategory.mice, 'conectividade') => 80,
    (InventoryCategory.keyboards, 'tipo') => 80,
    (InventoryCategory.keyboards, 'conectividade') => 80,
    (InventoryCategory.keyboards, 'switch') => 80,
    (InventoryCategory.headsets, 'tipo') => 80,
    (InventoryCategory.headsets, 'conectividade') => 80,
    (InventoryCategory.extensions, 'cor') => 60,
    (InventoryCategory.extensions, 'tipo') => 80,
    (InventoryCategory.extensions, 'linha') => 80,
    (InventoryCategory.extensions, 'numero') => 30,
    (InventoryCategory.extensions, 'ip') => 45,
    (InventoryCategory.extensions, 'mac') => 17,
    (InventoryCategory.extras, 'categoria') => 100,
    (InventoryCategory.extras, 'descricao') => 1000,
    _ => null,
  };
}
