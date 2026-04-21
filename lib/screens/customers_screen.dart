import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'vehicles_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
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
    final list = await DatabaseHelper.instance.getCustomers(search: search);
    if (!mounted) return;
    setState(() {
      _customers = list;
      _loading = false;
    });
  }

  Future<void> _showForm([Customer? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final emailCtrl = TextEditingController(text: existing?.email);
    final addrCtrl = TextEditingController(text: existing?.address);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Customer' : 'Edit Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone *'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
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
    );

    if (ok != true) return;

    final customer = Customer(
      id: existing?.id,
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (existing == null) {
      await DatabaseHelper.instance.insertCustomer(customer);
    } else {
      await DatabaseHelper.instance.updateCustomer(customer);
    }
    _load(_searchCtrl.text);
  }

  Future<void> _delete(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Remove ${c.name}? This action cannot be undone.'),
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
      await DatabaseHelper.instance.deleteCustomer(c.id!);
      _load(_searchCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _toolbar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _customers.length,
                        itemBuilder: (_, i) => _customerCard(_customers[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _toolbar() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
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
          ],
        ),
      );

  Widget _customerCard(Customer c) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: Text(c.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white)),
          ),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('📞 ${c.phone}${c.email != null ? '\n✉️ ${c.email}' : ''}'),
          isThreeLine: c.email != null,
          trailing: PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') _showForm(c);
              if (val == 'delete') _delete(c);
              if (val == 'vehicles') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehiclesScreen(customerId: c.id, customerName: c.name),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'vehicles', child: ListTile(leading: Icon(Icons.directions_car), title: Text('Vehicles'))),
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
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No customers found',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Customer'),
            ),
          ],
        ),
      );
}
