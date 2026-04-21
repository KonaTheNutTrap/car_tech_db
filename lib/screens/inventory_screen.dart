import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Part> _parts = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    final list = await DatabaseHelper.instance.getParts(search: search);
    if (!mounted) return;
    setState(() {
      _parts = list;
      _loading = false;
    });
  }

  Future<void> _showForm([Part? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final partNumCtrl = TextEditingController(text: existing?.partNumber);
    final descCtrl = TextEditingController(text: existing?.description);
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '0');
    final priceCtrl =
        TextEditingController(text: existing?.unitPrice.toString() ?? '0');
    final catCtrl = TextEditingController(text: existing?.category);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Part' : 'Edit Part'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Part Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: partNumCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Part Number'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: catCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Quantity *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Unit Price *', prefixText: '₱ '),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final part = Part(
      id: existing?.id,
      name: nameCtrl.text.trim(),
      partNumber: partNumCtrl.text.trim().isEmpty
          ? null
          : partNumCtrl.text.trim(),
      description:
          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      quantity: int.tryParse(qtyCtrl.text) ?? 0,
      unitPrice: double.tryParse(priceCtrl.text) ?? 0,
      category:
          catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    if (existing == null) {
      await DatabaseHelper.instance.insertPart(part);
    } else {
      await DatabaseHelper.instance.updatePart(part);
    }
    _load(_searchCtrl.text);
  }

  Future<void> _delete(Part p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Part?'),
        content: Text('Remove ${p.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deletePart(p.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _parts.where((p) => p.quantity < 5).length;

    return Scaffold(
      body: Column(
        children: [
          if (lowStock > 0)
            Container(
              width: double.infinity,
              color: AppTheme.warning.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Text('$lowStock part(s) are low in stock',
                      style: const TextStyle(color: AppTheme.warning)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search parts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        })
                    : null,
              ),
              onChanged: (v) => _load(v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _parts.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _parts.length,
                        itemBuilder: (_, i) => _partCard(_parts[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Part'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _partCard(Part p) {
    final isLow = p.quantity < 5;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isLow ? AppTheme.warning : AppTheme.primaryLight,
          child: const Icon(Icons.settings, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(p.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600))),
            if (isLow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.warning),
                ),
                child: const Text('Low Stock',
                    style:
                        TextStyle(color: AppTheme.warning, fontSize: 10)),
              ),
          ],
        ),
        subtitle: Text(
          '${p.partNumber != null ? '#${p.partNumber} • ' : ''}${p.category ?? 'Uncategorized'}\nQty: ${p.quantity} • ₱${p.unitPrice.toStringAsFixed(2)}/unit',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') _showForm(p);
            if (val == 'delete') _delete(p);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.danger), title: Text('Delete', style: TextStyle(color: AppTheme.danger)))),
          ],
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No parts in inventory',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Part'),
            ),
          ],
        ),
      );
}
