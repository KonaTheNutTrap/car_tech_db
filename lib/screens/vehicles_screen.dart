import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class VehiclesScreen extends StatefulWidget {
  final int? customerId;
  final String? customerName;

  const VehiclesScreen({super.key, this.customerId, this.customerName});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Vehicle> _vehicles = [];
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final vehicles = await db.getVehicles(
        customerId: widget.customerId, search: search);
    final customers = await db.getCustomers();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _customers = customers;
      _loading = false;
    });
  }

  String _customerName(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _showForm([Vehicle? existing]) async {
    final makeCtrl = TextEditingController(text: existing?.make);
    final modelCtrl = TextEditingController(text: existing?.model);
    final yearCtrl =
        TextEditingController(text: existing?.year.toString());
    final vinCtrl = TextEditingController(text: existing?.vin);
    final plateCtrl = TextEditingController(text: existing?.licensePlate);
    final formKey = GlobalKey<FormState>();
    int? selectedCustomerId = existing?.customerId ?? widget.customerId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (widget.customerId == null) ...[
                  DropdownButtonFormField<int>(
                    initialValue: selectedCustomerId,
                    decoration: const InputDecoration(labelText: 'Customer *'),
                    items: _customers
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDlg(() => selectedCustomerId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: makeCtrl,
                      decoration: const InputDecoration(labelText: 'Make *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: modelCtrl,
                      decoration: const InputDecoration(labelText: 'Model *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: yearCtrl,
                      decoration: const InputDecoration(labelText: 'Year *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: plateCtrl,
                      decoration:
                          const InputDecoration(labelText: 'License Plate *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: vinCtrl,
                  decoration: const InputDecoration(labelText: 'VIN'),
                ),
              ]),
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
      ),
    );

    if (ok != true || selectedCustomerId == null) return;

    final vehicle = Vehicle(
      id: existing?.id,
      customerId: selectedCustomerId!,
      make: makeCtrl.text.trim(),
      model: modelCtrl.text.trim(),
      year: int.tryParse(yearCtrl.text) ?? 2020,
      vin: vinCtrl.text.trim().isEmpty ? null : vinCtrl.text.trim(),
      licensePlate: plateCtrl.text.trim(),
    );

    if (existing == null) {
      await DatabaseHelper.instance.insertVehicle(vehicle);
    } else {
      await DatabaseHelper.instance.updateVehicle(vehicle);
    }
    _load(_searchCtrl.text);
  }

  Future<void> _delete(Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Remove ${v.displayName}?'),
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
      await DatabaseHelper.instance.deleteVehicle(v.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.customerId != null
          ? AppBar(
              title: Text(
                  widget.customerName != null
                      ? '${widget.customerName}\'s Vehicles'
                      : 'Vehicles'),
            )
          : null,
      body: Column(
        children: [
          if (widget.customerId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by plate, make, or model...',
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
                : _vehicles.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _vehicles.length,
                        itemBuilder: (_, i) => _vehicleCard(_vehicles[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _vehicleCard(Vehicle v) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.primaryLight,
            child: Icon(Icons.directions_car,
                color: Colors.white, size: 20),
          ),
          title: Text(v.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '🔖 ${v.licensePlate}${v.vin != null ? '\nVIN: ${v.vin}' : ''}\n👤 ${_customerName(v.customerId)}'),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') _showForm(v);
              if (val == 'delete') _delete(v);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.danger), title: Text('Delete', style: TextStyle(color: AppTheme.danger)))),
            ],
          ),
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No vehicles found',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            ),
          ],
        ),
      );
}
