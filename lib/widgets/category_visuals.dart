import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

extension InventoryCategoryVisuals on InventoryCategory {
  IconData get icon => switch (this) {
    InventoryCategory.computers => Icons.computer,
    InventoryCategory.monitors => Icons.desktop_windows_outlined,
    InventoryCategory.phones => Icons.smartphone,
    InventoryCategory.simCards => Icons.sim_card_outlined,
    InventoryCategory.mice => Icons.mouse_outlined,
    InventoryCategory.keyboards => Icons.keyboard_outlined,
    InventoryCategory.headsets => Icons.headphones_outlined,
    InventoryCategory.extensions => Icons.phone_in_talk_outlined,
    InventoryCategory.extras => Icons.extension_outlined,
  };

  Color get color => switch (this) {
    InventoryCategory.computers => const Color(0xFF6366F1),
    InventoryCategory.monitors => const Color(0xFF22C55E),
    InventoryCategory.phones => const Color(0xFFF59E0B),
    InventoryCategory.simCards => const Color(0xFF06B6D4),
    InventoryCategory.mice => const Color(0xFFEC4899),
    InventoryCategory.keyboards => const Color(0xFF8B5CF6),
    InventoryCategory.headsets => const Color(0xFFF97316),
    InventoryCategory.extensions => const Color(0xFF14B8A6),
    InventoryCategory.extras => const Color(0xFF64748B),
  };
}

Color categoryColorForLabel(String label) {
  final normalized = label.toLowerCase();
  for (final category in InventoryCategory.values) {
    if (normalized.contains(category.label.toLowerCase()) ||
        normalized.contains(category.endpoint.toLowerCase())) {
      return category.color;
    }
  }
  return const Color(0xFF64748B);
}
