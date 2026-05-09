import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/service_order_print.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<String> _statuses = ['All', 'Pending', 'In Progress', 'Completed'];
  List<Job> _jobs = [];
  List<Job> _allJobs = [];
  List<Customer> _customers = [];
  List<Vehicle> _vehicles = [];
  List<User> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _sortOption = 'newest';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final status =
        _statuses[_tab.index] == 'All' ? null : _statuses[_tab.index];
    final jobs = await db.getJobs(status: status);
    final customers = await db.getCustomers();
    final vehicles = await db.getVehicles();
    final users = await db.getUsers();
    if (!mounted) return;
    _allJobs = jobs;
    _customers = customers;
    _vehicles = vehicles;
    _users = users;
    _applySearchAndSort();
    _loading = false;
  }

  void _applySearchAndSort() {
    var list = List<Job>.from(_allJobs);
    final search = _searchCtrl.text.toLowerCase().trim();

    // Apply search filter
    if (search.isNotEmpty) {
      list = list.where((j) {
        final desc = j.description.toLowerCase();
        final custName = _cName(j.customerId).toLowerCase();
        final vehName = _vName(j.vehicleId).toLowerCase();
        final techName = _uName(j.technicianId).toLowerCase();
        return desc.contains(search) ||
            custName.contains(search) ||
            vehName.contains(search) ||
            techName.contains(search);
      }).toList();
    }

    // Apply sort
    switch (_sortOption) {
      case 'fifo':
        list.sort((a, b) => a.id!.compareTo(b.id!));
        break;
      case 'newest':
        list.sort((a, b) => b.id!.compareTo(a.id!));
        break;
      case 'status':
        list.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'cust_asc':
        list.sort((a, b) => _cName(a.customerId).compareTo(_cName(b.customerId)));
        break;
      case 'labor_asc':
        list.sort((a, b) => a.laborCost.compareTo(b.laborCost));
        break;
      case 'labor_desc':
        list.sort((a, b) => b.laborCost.compareTo(a.laborCost));
        break;
    }

    setState(() {
      _jobs = list;
      _loading = false;
    });
  }

  String _cName(int id) {
    try { return _customers.firstWhere((c) => c.id == id).name; } catch (_) { return '?'; }
  }
  String _vName(int id) {
    try { return _vehicles.firstWhere((v) => v.id == id).displayName; } catch (_) { return '?'; }
  }
  String _uName(int? id) {
    if (id == null) return 'Unassigned';
    try { return _users.firstWhere((u) => u.id == id).fullName; } catch (_) { return '?'; }
  }

  Future<void> _showJobForm([Job? existing]) async {
    final descCtrl = TextEditingController(text: existing?.description);
    final laborCtrl =
        TextEditingController(text: existing?.laborCost.toString() ?? '0');
    final notesCtrl = TextEditingController(text: existing?.notes);
    final formKey = GlobalKey<FormState>();
    int? custId = existing?.customerId;
    int? vehId = existing?.vehicleId;
    int? techId = existing?.technicianId;
    String status = existing?.status ?? 'Pending';

    // Load all parts from inventory for the materials picker
    final allParts = await DatabaseHelper.instance.getParts();

    // Load existing job parts if editing
    List<Map<String, dynamic>> selectedParts = [];
    if (existing != null) {
      final existingJobParts = await DatabaseHelper.instance.getJobParts(existing.id!);
      for (final jp in existingJobParts) {
        final part = allParts.firstWhere((p) => p.id == jp.partId,
            orElse: () => Part(
                name: 'Unknown',
                quantity: 0,
                unitPrice: jp.unitPrice,
                updatedAt: ''));
        selectedParts.add({
          'part': part,
          'quantity': jp.quantity,
          'unit_price': jp.unitPrice,
        });
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final custVehicles =
              custId != null ? _vehicles.where((v) => v.customerId == custId).toList() : <Vehicle>[];

          // Parts available to add (in stock and not already fully selected)
          final availableParts = allParts.where((p) {
            if (p.quantity <= 0) return false;
            final alreadySelected = selectedParts
                .where((sp) => (sp['part'] as Part).id == p.id)
                .fold<int>(0, (sum, sp) => sum + (sp['quantity'] as int));
            return alreadySelected < p.quantity;
          }).toList();

          Future<void> addMaterial() async {
            // Show a sub-dialog to pick a part and quantity
            Part? selectedPart;
            final qtyCtrl = TextEditingController(text: '1');
            final subKey = GlobalKey<FormState>();

            final added = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Add Material'),
                content: Form(
                  key: subKey,
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Part *'),
                          items: availableParts.map((p) {
                            final alreadyUsed = selectedParts
                                .where((sp) => (sp['part'] as Part).id == p.id)
                                .fold<int>(0,
                                    (sum, sp) => sum + (sp['quantity'] as int));
                            final remaining = p.quantity - alreadyUsed;
                            return DropdownMenuItem(
                              value: p.id,
                              child: SizedBox(
                                width: 300,
                                child: Text(
                                  '${p.name} (Stock: $remaining) — ₱${p.unitPrice.toStringAsFixed(2)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            selectedPart = allParts.firstWhere((p) => p.id == v);
                            setDlg(() {}); // not used for display, just hold state
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: qtyCtrl,
                          decoration: const InputDecoration(labelText: 'Quantity *'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            final n = int.tryParse(v);
                            if (n == null || n < 1) return 'Invalid quantity';
                            if (selectedPart != null) {
                              final alreadyUsed = selectedParts
                                  .where((sp) => (sp['part'] as Part).id == selectedPart!.id)
                                  .fold<int>(0, (sum, sp) => sum + (sp['quantity'] as int));
                              if (n > selectedPart!.quantity - alreadyUsed) {
                                return 'Only ${selectedPart!.quantity - alreadyUsed} available';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      if (subKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );

            if (added == true && selectedPart != null) {
              final qty2 = int.tryParse(qtyCtrl.text) ?? 1;
              setDlg(() {
                selectedParts.add({
                  'part': selectedPart,
                  'quantity': qty2,
                  'unit_price': selectedPart!.unitPrice,
                });
              });
            }
          }

          return AlertDialog(
            title: Text(existing == null ? 'New Repair Job' : 'Edit Job'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<int>(
                      initialValue: custId,
                      decoration: const InputDecoration(labelText: 'Customer *'),
                      items: _customers
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setDlg(() {
                        custId = v;
                        vehId = null;
                      }),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: vehId,
                      decoration: const InputDecoration(labelText: 'Vehicle *'),
                      items: custVehicles
                          .map((v) => DropdownMenuItem(
                              value: v.id, child: Text(v.displayName)))
                          .toList(),
                      onChanged: (v) => setDlg(() => vehId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: techId,
                      decoration: const InputDecoration(labelText: 'Technician'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Unassigned')),
                        ..._users
                            .where((u) =>
                                u.role == 'Technician' || u.role == 'Admin')
                            .map((u) => DropdownMenuItem(
                                value: u.id, child: Text(u.fullName)))
                      ],
                      onChanged: (v) => setDlg(() => techId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Job Description *'),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    if (existing != null)
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Pending', 'In Progress', 'Completed']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setDlg(() => status = v!),
                      ),
                    if (existing != null) const SizedBox(height: 12),
                    TextFormField(
                      controller: laborCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Labor Cost (₱)',
                          prefixText: '₱ '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // ── Materials Section ──
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.inventory, size: 18),
                        const SizedBox(width: 6),
                        const Text('Materials',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Material'),
                          onPressed: availableParts.isNotEmpty
                              ? addMaterial
                              : null,
                        ),
                      ],
                    ),
                    if (selectedParts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No materials added yet',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...selectedParts.asMap().entries.map((entry) {
                        final i = entry.key;
                        final sp = entry.value;
                        final part = sp['part'] as Part;
                        final qty = sp['quantity'] as int;
                        final price = sp['unit_price'] as double;
                        final subtotal = qty * price;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${part.name} x$qty',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '₱${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  setDlg(() {
                                    selectedParts.removeAt(i);
                                  });
                                },
                                child: const Icon(Icons.remove_circle_outline,
                                    size: 16, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }),
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
          );
        },
      ),
    );

    if (ok != true) return;

    final now = DateTime.now().toIso8601String();
    final job = Job(
      id: existing?.id,
      customerId: custId!,
      vehicleId: vehId!,
      technicianId: techId,
      description: descCtrl.text.trim(),
      status: status,
      laborCost: double.tryParse(laborCtrl.text) ?? 0,
      notes:
          notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final db = DatabaseHelper.instance;

    if (existing == null) {
      // New job: insert job, then add job_parts and deduct stock
      final jobId = await db.insertJob(job);
      for (final sp in selectedParts) {
        final part = sp['part'] as Part;
        final qty = sp['quantity'] as int;
        final price = sp['unit_price'] as double;
        await db.insertJobPart(JobPart(
          jobId: jobId,
          partId: part.id!,
          quantity: qty,
          unitPrice: price,
        ));
        await db.deductPartStock(part.id!, qty);
      }
    } else {
      // Editing existing job:
      // 1. Restore stock for old job_parts
      final oldParts = await db.getJobParts(existing.id!);
      for (final oldJp in oldParts) {
        await db.restorePartStock(oldJp.partId, oldJp.quantity);
      }
      // 2. Delete old job_parts
      await db.deleteJobPartsByJob(existing.id!);
      // 3. Update the job
      await db.updateJob(job);
      // 4. Insert new job_parts and deduct stock
      for (final sp in selectedParts) {
        final part = sp['part'] as Part;
        final qty = sp['quantity'] as int;
        final price = sp['unit_price'] as double;
        await db.insertJobPart(JobPart(
          jobId: existing.id!,
          partId: part.id!,
          quantity: qty,
          unitPrice: price,
        ));
        await db.deductPartStock(part.id!, qty);
      }
    }
    _load(_searchCtrl.text);
  }

  Future<void> _updateStatus(Job job, String newStatus) async {
    final updated = job.copyWith(
        status: newStatus, updatedAt: DateTime.now().toIso8601String());
    await DatabaseHelper.instance.updateJob(updated);
    _load();
  }

  Future<void> _generateInvoice(Job job) async {
    final existing = await DatabaseHelper.instance.getInvoiceByJob(job.id!);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice already exists for this job')),
      );
      return;
    }

    // Calculate parts cost
    final jobParts = await DatabaseHelper.instance.getJobParts(job.id!);
    final partsCost = jobParts.fold<double>(0, (sum, p) => sum + p.subtotal);
    final total = job.laborCost + partsCost;

    final invNum = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final invoice = Invoice(
      jobId: job.id!,
      invoiceNumber: invNum,
      totalAmount: total,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertInvoice(invoice);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice $invNum created — Total: ₱${total.toStringAsFixed(2)}'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: AppTheme.accent,
              tabs: _statuses.map((s) => Tab(text: s)).toList(),
              onTap: (_) => _load(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by description, customer, or vehicle...',
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
                const SizedBox(width: 8),
                SortDropdown(
                  currentValue: _sortOption,
                  options: const [
                    SortOption('Newest First', 'newest'),
                    SortOption('FIFO (Oldest)', 'fifo'),
                    SortOption('Status', 'status'),
                    SortOption('Customer (A-Z)', 'cust_asc'),
                    SortOption('Labor (Low→High)', 'labor_asc'),
                    SortOption('Labor (High→Low)', 'labor_desc'),
                  ],
                  onChanged: (v) {
                    setState(() => _sortOption = v);
                    _applySearchAndSort();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _jobs.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: () => _load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _jobs.length,
                          itemBuilder: (_, i) => _jobCard(_jobs[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJobForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _jobCard(Job job) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.description,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  _statusChip(job.status),
                ],
              ),
              const SizedBox(height: 8),
              _infoRow(Icons.person, _cName(job.customerId)),
              _infoRow(Icons.directions_car, _vName(job.vehicleId)),
              _infoRow(Icons.build, 'Technician: ${_uName(job.technicianId)}'),
              _infoRow(Icons.payments, 'Labor: ₱${job.laborCost.toStringAsFixed(2)}'),
              if (job.notes != null)
                _infoRow(Icons.note, job.notes!),
              const Divider(height: 16),
              Row(
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(
                        DateTime.parse(job.createdAt)),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  if (job.status != 'In Progress' && job.status != 'Completed')
                    TextButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Start'),
                      onPressed: () => _updateStatus(job, 'In Progress'),
                    ),
                  if (job.status == 'In Progress')
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.success),
                      onPressed: () => _updateStatus(job, 'Completed'),
                    ),
                  if (job.status == 'Completed')
                    TextButton.icon(
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Invoice'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                      onPressed: () => _generateInvoice(job),
                    ),
                  if (job.status == 'Completed')
                    TextButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                      onPressed: () => ServiceOrderPrint.printJob(job, context),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showJobForm(job),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black87))),
          ],
        ),
      );

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: JobStatus.color(status).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: JobStatus.color(status)),
        ),
        child: Text(status,
            style: TextStyle(
                color: JobStatus.color(status),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No jobs found', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showJobForm(),
              icon: const Icon(Icons.add),
              label: const Text('Create First Job'),
            ),
          ],
        ),
      );
}