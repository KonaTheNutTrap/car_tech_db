import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sort_dropdown.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Invoice> _invoices = [];
  List<Invoice> _allInvoices = [];
  List<Job> _jobs = [];
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _sortOption = 'newest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final invoices = await db.getInvoices();
    final jobs = await db.getJobs();
    final customers = await db.getCustomers();
    if (!mounted) return;
    _allInvoices = invoices;
    _jobs = jobs;
    _customers = customers;
    _applySearchAndSort();
    _loading = false;
  }

  void _applySearchAndSort() {
    var list = List<Invoice>.from(_allInvoices);
    final search = _searchCtrl.text.toLowerCase().trim();

    // Apply search filter
    if (search.isNotEmpty) {
      list = list.where((inv) {
        final invNum = inv.invoiceNumber.toLowerCase();
        final custName = _custName(inv.jobId).toLowerCase();
        final jobDesc = _jobDesc(inv.jobId).toLowerCase();
        return invNum.contains(search) ||
            custName.contains(search) ||
            jobDesc.contains(search);
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
      case 'amount_asc':
        list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'amount_desc':
        list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'status':
        list.sort((a, b) => a.paymentStatus.compareTo(b.paymentStatus));
        break;
    }

    setState(() => _invoices = list);
  }

  String _custName(int jobId) {
    try {
      final job = _jobs.firstWhere((j) => j.id == jobId);
      return _customers.firstWhere((c) => c.id == job.customerId).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  String _jobDesc(int jobId) {
    try {
      return _jobs.firstWhere((j) => j.id == jobId).description;
    } catch (_) {
      return '';
    }
  }

  Future<void> _recordPayment(Invoice inv) async {
    final amtCtrl =
        TextEditingController(text: inv.totalAmount.toStringAsFixed(2));
    String method = 'Cash';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Invoice: ${inv.invoiceNumber}'),
            Text('Total: ₱${inv.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: amtCtrl,
              decoration: const InputDecoration(
                  labelText: 'Amount', prefixText: '₱ '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: ['Cash', 'GCash', 'Card', 'Bank Transfer']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setDlg(() => method = v!),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final payment = Payment(
      invoiceId: inv.id!,
      amount: double.tryParse(amtCtrl.text) ?? inv.totalAmount,
      method: method,
      paidAt: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.insertPayment(payment);

    // update invoice status
    final updatedInv = inv.copyWith(paymentStatus: 'Paid');
    await DatabaseHelper.instance.updateInvoice(updatedInv);
    _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment recorded successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue =
        _invoices.where((i) => i.paymentStatus == 'Paid').fold<double>(
            0, (sum, i) => sum + i.totalAmount);
    final outstanding =
        _invoices.where((i) => i.paymentStatus == 'Unpaid').fold<double>(
            0, (sum, i) => sum + i.totalAmount);

    return Scaffold(
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary.withOpacity(0.05),
            child: Row(
              children: [
                _summaryTile('Total Revenue', '₱${totalRevenue.toStringAsFixed(2)}',
                    AppTheme.success),
                const SizedBox(width: 12),
                _summaryTile('Outstanding',
                    '₱${outstanding.toStringAsFixed(2)}', AppTheme.danger),
                const SizedBox(width: 12),
                _summaryTile(
                    'Invoices', '${_invoices.length}', AppTheme.primary),
              ],
            ),
          ),
          // Search & Sort row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by invoice #, customer, or job...',
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
                    SortOption('Amount (Low→High)', 'amount_asc'),
                    SortOption('Amount (High→Low)', 'amount_desc'),
                    SortOption('Payment Status', 'status'),
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
                : _invoices.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _invoices.length,
                          itemBuilder: (_, i) => _invoiceCard(_invoices[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _invoiceCard(Invoice inv) {
    final auth = context.watch<AuthProvider>();
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inv.invoiceNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_custName(inv.jobId),
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₱${inv.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PaymentStatus.color(inv.paymentStatus)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(inv.paymentStatus,
                            style: TextStyle(
                                color: PaymentStatus.color(inv.paymentStatus),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Icon(Icons.build_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(_jobDesc(inv.jobId),
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(
                        DateTime.parse(inv.createdAt)),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (inv.paymentStatus != 'Paid')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payments, size: 16),
                      label: const Text('Pay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _recordPayment(inv),
                    ),

                  const SizedBox(width: 8),

                  // Delete button - admin only
                  if (auth.isAdmin)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Invoice'),
                            content: const Text(
                              'Are you sure you want to delete this invoice?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await DatabaseHelper.instance.deleteInvoice(inv.id!);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invoice deleted successfully'),
                            ),
                          );
                          _load();
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No invoices yet',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            const Text('Complete a job and generate an invoice from the Jobs tab'),
          ],
        ),
      );
}