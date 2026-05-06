import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/sort_dropdown.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  List<User> _allUsers = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _sortOption = 'name_asc';

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
    final list = await DatabaseHelper.instance.getUsers();
    if (!mounted) return;
    _allUsers = list;
    _applySearchAndSort();
    _loading = false;
  }

  void _applySearchAndSort() {
    var list = List<User>.from(_allUsers);
    final search = _searchCtrl.text.toLowerCase().trim();

    // Apply search filter
    if (search.isNotEmpty) {
      list = list.where((u) {
        final name = u.fullName.toLowerCase();
        final username = u.username.toLowerCase();
        final role = u.role.toLowerCase();
        return name.contains(search) ||
            username.contains(search) ||
            role.contains(search);
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
      case 'name_asc':
        list.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        list.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'role':
        list.sort((a, b) => a.role.compareTo(b.role));
        break;
    }

    setState(() => _users = list);
  }

  Future<void> _showForm([User? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.fullName);
    final userCtrl = TextEditingController(text: existing?.username);
    final passCtrl = TextEditingController(text: existing?.password);
    String role = existing?.role ?? 'Technician';
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(existing == null ? 'Add User' : 'Edit User'),
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
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'Username *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setDlg(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.all
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDlg(() => role = v!),
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

    if (ok != true) return;

    final user = User(
      id: existing?.id,
      fullName: nameCtrl.text.trim(),
      username: userCtrl.text.trim(),
      password: passCtrl.text,
      role: role,
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (existing == null) {
      await DatabaseHelper.instance.insertUser(user);
    } else {
      await DatabaseHelper.instance.updateUser(user);
    }
    _load();
  }

  Future<void> _delete(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Remove ${u.fullName}?'),
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
      await DatabaseHelper.instance.deleteUser(u.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name, username, or role...',
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
                    SortOption('Name (A-Z)', 'name_asc'),
                    SortOption('Name (Z-A)', 'name_desc'),
                    SortOption('FIFO (Oldest)', 'fifo'),
                    SortOption('Newest First', 'newest'),
                    SortOption('Role', 'role'),
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
                : _users.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _userCard(_users[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _userCard(User u) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: UserRole.color(u.role),
            child: Text(u.fullName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white)),
          ),
          title: Text(u.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('@${u.username}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: UserRole.color(u.role).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(u.role,
                    style: TextStyle(
                        color: UserRole.color(u.role),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _showForm(u);
                  if (val == 'delete') _delete(u);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.danger), title: Text('Delete', style: TextStyle(color: AppTheme.danger)))),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No users found',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
}