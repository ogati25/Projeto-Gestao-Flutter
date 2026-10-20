import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/inventory_item.dart';
import '../widgets/category_visuals.dart';
import '../widgets/status_badge.dart';

class InventoryDetailScreen extends StatelessWidget {
  const InventoryDetailScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final details = item.raw.entries
        .where((entry) => entry.value != null)
        .where((entry) => entry.key != 'id')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do item')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: item.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      item.category.icon,
                      color: item.category.color,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.category.label,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        StatusBadge(status: item.status, active: item.active),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações cadastradas',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...details.indexed.map((indexedEntry) {
                    final index = indexedEntry.$1;
                    final entry = indexedEntry.$2;
                    return Column(
                      children: [
                        _DetailRow(
                          label: _friendlyLabel(entry.key),
                          value: _formatValue(entry.key, entry.value),
                        ),
                        if (index < details.length - 1)
                          const Divider(height: 22),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 126,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

String _friendlyLabel(String key) {
  const labels = <String, String>{
    'codigo': 'Código',
    'usuario': 'Responsável',
    'dataAquisicao': 'Aquisição',
    'precoAquisicao': 'Valor',
    'ativo': 'Ativo',
    'setor': 'Setor',
    'status': 'Status',
    'observacoes': 'Observações',
    'modelo': 'Modelo',
    'tipo': 'Tipo',
    'processadorId': 'Processador',
    'geracaoRAM': 'Geração da RAM',
    'quantidadeSlots': 'Slots de RAM',
    'memoriaRAM': 'Memórias RAM',
    'memoriaRAMTotal': 'RAM total',
    'velocidadeRAM': 'Velocidade da RAM',
    'quantidadeDiscos': 'Quantidade de discos',
    'discos': 'Discos',
    'quantidadePlacasVideo': 'Placas de vídeo',
    'placasVideo': 'Detalhes das placas',
    'quantidadeConectoresVideo': 'Conectores de vídeo',
    'conectoresVideo': 'Tipos de conectores',
    'sistemaOperacional': 'Sistema operacional',
    'ativacaoSO': 'Ativação do sistema',
    'office': 'Office',
    'ativacaoOffice': 'Ativação do Office',
    'ip': 'IP',
    'tamanho': 'Tamanho',
    'resolucao': 'Resolução',
    'frequencia': 'Frequência',
    'hdmi': 'HDMI',
    'displayPort': 'DisplayPort',
    'vga': 'VGA',
    'dvi': 'DVI',
    'armazenamento': 'Armazenamento',
    'conectividade': 'Conectividade',
    'chipIds': 'Chips vinculados',
    'contasWhatsapp': 'Contas de WhatsApp',
    'operadora': 'Operadora',
    'numero': 'Número',
    'dono': 'Titular',
    'plano': 'Plano',
    'celularId': 'Celular vinculado',
    'switch': 'Switch',
    'microfone': 'Microfone',
    'cor': 'Cor',
    'configurado': 'Configurado',
    'linha': 'Linha',
    'mac': 'MAC',
    'categoria': 'Categoria',
    'descricao': 'Descrição',
    'quantidade': 'Quantidade',
  };
  return labels[key] ?? _splitCamelCase(key);
}

String _formatValue(String key, dynamic value) {
  if (value is bool) return value ? 'Sim' : 'Não';
  if (key == 'dataAquisicao') {
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date != null) {
      return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
    }
  }
  if (key == 'precoAquisicao' && value is num) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
  if (value is List || value is Map) {
    if (value is List && value.isEmpty) return '—';
    if (value is Map && value.isEmpty) return '—';
    return const JsonEncoder.withIndent('  ').convert(value);
  }
  final text = value.toString().trim();
  return text.isEmpty ? '—' : text;
}

String _splitCamelCase(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  if (spaced.isEmpty) return value;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
