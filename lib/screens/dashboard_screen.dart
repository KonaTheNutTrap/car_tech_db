import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Job> _recentJobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }
Future<void> _showDbPath() async {
  final dbPath = await getDatabasesPath();
  final fullPath = '$dbPath\\car_tech.db';

  if (!mounted) return;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_open, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Database Location'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your database file is saved at:',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SelectableText(
              fullPath,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You can open this file with:\n• DB Browser for SQLite\n• SQLite Viewer (VS Code extension)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final stats = await db.getDashboardStats();
    final jobs = await db.getJobs();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _recentJobs = jobs.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _statsGrid(),
            const SizedBox(height: 24),
            _jobStatusRow(),
            const SizedBox(height: 24),
            _recentJobsList(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
      children: [
        const Icon(Icons.dashboard, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text('Dashboard',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          onPressed: _load,
        ),
        IconButton(
          icon: const Icon(Icons.folder_open, color: AppTheme.primary),
          tooltip: 'Database Location',
          onPressed: _showDbPath,
        ),
      ],
    );

  Widget _statsGrid() {
    final items = [
      _StatCard('Customers', '${_stats['customers']}', Icons.people,
          AppTheme.primary),
      _StatCard('Vehicles', '${_stats['vehicles']}', Icons.directions_car,
          AppTheme.primaryLight),
      _StatCard('Revenue (Paid)', '₱${(_stats['totalRevenue'] as num).toStringAsFixed(2)}',
          Icons.payments, AppTheme.success),
      _StatCard('Outstanding', '₱${(_stats['outstanding'] as num).toStringAsFixed(2)}',
          Icons.warning_amber, AppTheme.danger),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items
          .map((s) => Card(
                color: s.color,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(s.icon, color: Colors.white54, size: 28),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          Text(s.label,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _jobStatusRow() {
    final statuses = [
      ('Pending', _stats['pendingJobs'] as int, AppTheme.warning),
      ('In Progress', _stats['inProgressJobs'] as int, AppTheme.primaryLight),
      ('Completed', _stats['completedJobs'] as int, AppTheme.success),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Status Overview',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: statuses
              .map((s) => Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('${s.$2}',
                                style: TextStyle(
                                    color: s.$3,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(s.$1,
                                style: TextStyle(
                                    color: s.$3, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _recentJobsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Jobs',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_recentJobs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No jobs yet')),
              ),
            )
          else
            ...(_recentJobs.map((j) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          JobStatus.color(j.status).withOpacity(0.15),
                      child: Icon(JobStatus.icon(j.status),
                          color: JobStatus.color(j.status), size: 20),
                    ),
                    title: Text(j.description,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Customer ID: ${j.customerId}'),
                    trailing: Chip(
                      label: Text(j.status,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      backgroundColor: JobStatus.color(j.status),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ))),
        ],
      );
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatCard(this.label, this.value, this.icon, this.color);
}
