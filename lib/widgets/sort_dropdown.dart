import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SortOption {
  final String label;
  final String value;
  const SortOption(this.label, this.value);
}

class SortDropdown extends StatelessWidget {
  final String currentValue;
  final List<SortOption> options;
  final ValueChanged<String> onChanged;

  const SortDropdown({
    super.key,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLabel = options
        .firstWhere((o) => o.value == currentValue,
            orElse: () => options.first)
        .label;

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showMenu(context),
        icon: const Icon(Icons.swap_vert, size: 18),
        label: Text(currentLabel, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset(renderBox.size.width, renderBox.size.height));

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 200,
        offset.dy,
        offset.dx,
        offset.dy + 400,
      ),
      items: options.map((o) {
        return PopupMenuItem<String>(
          value: o.value,
          child: Row(
            children: [
              if (o.value == currentValue)
                const Icon(Icons.check, size: 18, color: AppTheme.primary)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(o.label),
            ],
          ),
        );
      }).toList(),
    ).then((v) {
      if (v != null && v != currentValue) onChanged(v);
    });
  }
}