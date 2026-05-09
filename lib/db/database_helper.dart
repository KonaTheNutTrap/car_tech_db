import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('car_tech.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        full_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Vehicles table
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        vin TEXT,
        license_plate TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // Car parts / inventory table
    await db.execute('''
      CREATE TABLE parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        part_number TEXT,
        description TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        unit_price REAL NOT NULL,
        category TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Repair jobs table
    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        technician_id INTEGER,
        description TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        labor_cost REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
        FOREIGN KEY (technician_id) REFERENCES users(id)
      )
    ''');

    // Job parts (parts used in a job)
    await db.execute('''
      CREATE TABLE job_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL,
        part_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (job_id) REFERENCES jobs(id),
        FOREIGN KEY (part_id) REFERENCES parts(id)
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'Unpaid',
        created_at TEXT NOT NULL,
        FOREIGN KEY (job_id) REFERENCES jobs(id)
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      )
    ''');

    // Seed admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'Admin',
      'full_name': 'System Administrator',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed demo data
    await _seedDemoData(db);
  }

  Future _seedDemoData(Database db) async {
    // Technician
    await db.insert('users', {
      'username': 'tech1',
      'password': 'tech123',
      'role': 'Technician',
      'full_name': 'Juan dela Cruz',
      'created_at': DateTime.now().toIso8601String(),
    });
    // Receptionist
    await db.insert('users', {
      'username': 'recep1',
      'password': 'recep123',
      'role': 'Receptionist',
      'full_name': 'Maria Santos',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Customers
    int c1 = await db.insert('customers', {
      'name': 'Pedro Reyes',
      'phone': '09171234567',
      'email': 'pedro@email.com',
      'address': 'Iloilo City',
      'created_at': DateTime.now().toIso8601String(),
    });
    int c2 = await db.insert('customers', {
      'name': 'Ana Gomez',
      'phone': '09281234567',
      'email': 'ana@email.com',
      'address': 'Mandurriao, Iloilo',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Vehicles
    int v1 = await db.insert('vehicles', {
      'customer_id': c1,
      'make': 'Toyota',
      'model': 'Vios',
      'year': 2019,
      'vin': 'JT2BF28K1W0123456',
      'license_plate': 'ABC-1234',
    });
    await db.insert('vehicles', {
      'customer_id': c2,
      'make': 'Honda',
      'model': 'Civic',
      'year': 2021,
      'vin': '2HGFB2F59BH123456',
      'license_plate': 'XYZ-5678',
    });

    // Parts
    await db.insert('parts', {
      'name': 'Oil Filter',
      'part_number': 'OF-001',
      'description': 'Standard oil filter',
      'quantity': 50,
      'unit_price': 250.0,
      'category': 'Filters',
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('parts', {
      'name': 'Brake Pads (Front)',
      'part_number': 'BP-F01',
      'description': 'Front brake pad set',
      'quantity': 20,
      'unit_price': 1200.0,
      'category': 'Brakes',
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('parts', {
      'name': 'Air Filter',
      'part_number': 'AF-002',
      'description': 'Engine air filter',
      'quantity': 30,
      'unit_price': 350.0,
      'category': 'Filters',
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('parts', {
      'name': 'Spark Plugs (set of 4)',
      'part_number': 'SP-004',
      'description': 'Iridium spark plugs',
      'quantity': 15,
      'unit_price': 800.0,
      'category': 'Engine',
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Job
    int j1 = await db.insert('jobs', {
      'customer_id': c1,
      'vehicle_id': v1,
      'technician_id': 2,
      'description': 'Full service oil change and brake inspection',
      'status': 'Completed',
      'labor_cost': 500.0,
      'notes': 'Customer requested synthetic oil',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('job_parts', {
      'job_id': j1,
      'part_id': 1,
      'quantity': 1,
      'unit_price': 250.0,
    });

    // Invoice
    await db.insert('invoices', {
      'job_id': j1,
      'invoice_number': 'INV-0001',
      'total_amount': 750.0,
      'payment_status': 'Paid',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('payments', {
      'invoice_id': 1,
      'amount': 750.0,
      'method': 'Cash',
      'paid_at': DateTime.now().toIso8601String(),
    });
  }

  // ── USERS ──────────────────────────────────────
  Future<User?> login(String username, String password) async {
    final db = await database;
    final result = await db.query('users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'full_name');
    return result.map((e) => User.fromMap(e)).toList();
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ── CUSTOMERS ──────────────────────────────────
  Future<List<Customer>> getCustomers({String? search}) async {
    final db = await database;
    if (search != null && search.isNotEmpty) {
      final result = await db.query('customers',
          where: 'name LIKE ? OR phone LIKE ?',
          whereArgs: ['%$search%', '%$search%'],
          orderBy: 'name');
      return result.map((e) => Customer.fromMap(e)).toList();
    }
    final result = await db.query('customers', orderBy: 'name');
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> insertCustomer(Customer c) async {
    final db = await database;
    return await db.insert('customers', c.toMap());
  }

  Future<int> updateCustomer(Customer c) async {
    final db = await database;
    return await db.update('customers', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ── VEHICLES ───────────────────────────────────
  Future<List<Vehicle>> getVehicles({int? customerId, String? search}) async {
    final db = await database;
    if (customerId != null) {
      final result = await db.query('vehicles',
          where: 'customer_id = ?', whereArgs: [customerId]);
      return result.map((e) => Vehicle.fromMap(e)).toList();
    }
    if (search != null && search.isNotEmpty) {
      final result = await db.query('vehicles',
          where: 'license_plate LIKE ? OR make LIKE ? OR model LIKE ?',
          whereArgs: ['%$search%', '%$search%', '%$search%']);
      return result.map((e) => Vehicle.fromMap(e)).toList();
    }
    final result = await db.query('vehicles');
    return result.map((e) => Vehicle.fromMap(e)).toList();
  }

  Future<int> insertVehicle(Vehicle v) async {
    final db = await database;
    return await db.insert('vehicles', v.toMap());
  }

  Future<int> updateVehicle(Vehicle v) async {
    final db = await database;
    return await db.update('vehicles', v.toMap(),
        where: 'id = ?', whereArgs: [v.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ── PARTS ──────────────────────────────────────
  Future<List<Part>> getParts({String? search}) async {
    final db = await database;
    if (search != null && search.isNotEmpty) {
      final result = await db.query('parts',
          where: 'name LIKE ? OR part_number LIKE ? OR category LIKE ?',
          whereArgs: ['%$search%', '%$search%', '%$search%'],
          orderBy: 'name');
      return result.map((e) => Part.fromMap(e)).toList();
    }
    final result = await db.query('parts', orderBy: 'name');
    return result.map((e) => Part.fromMap(e)).toList();
  }

  Future<int> insertPart(Part p) async {
    final db = await database;
    return await db.insert('parts', p.toMap());
  }

  Future<int> updatePart(Part p) async {
    final db = await database;
    return await db.update('parts', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePart(int id) async {
    final db = await database;
    return await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }

  // ── JOBS ───────────────────────────────────────
  Future<List<Job>> getJobs({String? status}) async {
    final db = await database;
    if (status != null) {
      final result = await db.query('jobs',
          where: 'status = ?', whereArgs: [status], orderBy: 'created_at DESC');
      return result.map((e) => Job.fromMap(e)).toList();
    }
    final result = await db.query('jobs', orderBy: 'created_at DESC');
    return result.map((e) => Job.fromMap(e)).toList();
  }

  Future<Job?> getJob(int id) async {
    final db = await database;
    final result =
        await db.query('jobs', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Job.fromMap(result.first);
  }

  Future<int> insertJob(Job j) async {
    final db = await database;
    return await db.insert('jobs', j.toMap());
  }

  Future<int> updateJob(Job j) async {
    final db = await database;
    return await db.update('jobs', j.toMap(),
        where: 'id = ?', whereArgs: [j.id]);
  }

  // ── JOB PARTS ──────────────────────────────────
  Future<List<JobPart>> getJobParts(int jobId) async {
    final db = await database;
    final result = await db.query('job_parts',
        where: 'job_id = ?', whereArgs: [jobId]);
    return result.map((e) => JobPart.fromMap(e)).toList();
  }

  /// Get job parts with part names from the parts table
  Future<List<Map<String, dynamic>>> getJobPartsWithNames(int jobId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT jp.quantity, jp.unit_price, p.name
      FROM job_parts jp
      INNER JOIN parts p ON jp.part_id = p.id
      WHERE jp.job_id = ?
    ''', [jobId]);
    return result;
  }

  Future<int> insertJobPart(JobPart jp) async {
    final db = await database;
    return await db.insert('job_parts', jp.toMap());
  }

  Future<int> deleteJobPart(int id) async {
    final db = await database;
    return await db.delete('job_parts', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all job_parts for a given job (used when editing a job's materials)
  Future<void> deleteJobPartsByJob(int jobId) async {
    final db = await database;
    await db.delete('job_parts', where: 'job_id = ?', whereArgs: [jobId]);
  }

  /// Deduct stock from a part. Throws if insufficient stock.
  Future<void> deductPartStock(int partId, int quantity) async {
    final db = await database;
    final result = await db.rawUpdate('''
      UPDATE parts SET quantity = quantity - ?
      WHERE id = ? AND quantity >= ?
    ''', [quantity, partId, quantity]);
    if (result == 0) {
      throw Exception('Insufficient stock for part ID $partId');
    }
  }

  /// Restore stock to a part (undo deduction).
  Future<void> restorePartStock(int partId, int quantity) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE parts SET quantity = quantity + ?
      WHERE id = ?
    ''', [quantity, partId]);
  }

  // ── INVOICES ───────────────────────────────────
  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final result = await db.query('invoices', orderBy: 'created_at DESC');
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<Invoice?> getInvoiceByJob(int jobId) async {
    final db = await database;
    final result = await db.query('invoices',
        where: 'job_id = ?', whereArgs: [jobId]);
    if (result.isEmpty) return null;
    return Invoice.fromMap(result.first);
  }

  Future<int> insertInvoice(Invoice inv) async {
    final db = await database;
    return await db.insert('invoices', inv.toMap());
  }

  Future<int> updateInvoice(Invoice inv) async {
    final db = await database;
    return await db.update('invoices', inv.toMap(),
        where: 'id = ?', whereArgs: [inv.id]);
  }

  // ── PAYMENTS ───────────────────────────────────
  Future<List<Payment>> getPayments({int? invoiceId}) async {
    final db = await database;
    if (invoiceId != null) {
      final result = await db.query('payments',
          where: 'invoice_id = ?', whereArgs: [invoiceId]);
      return result.map((e) => Payment.fromMap(e)).toList();
    }
    final result = await db.query('payments', orderBy: 'paid_at DESC');
    return result.map((e) => Payment.fromMap(e)).toList();
  }

  Future<int> insertPayment(Payment p) async {
    final db = await database;
    return await db.insert('payments', p.toMap());
  }

  // ── DASHBOARD STATS ────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
  final db = await database;

  final customers = (await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers')).first['count'] as int? ?? 0;
  final vehicles = (await db.rawQuery(
      'SELECT COUNT(*) as count FROM vehicles')).first['count'] as int? ?? 0;
  final pendingJobs = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM jobs WHERE status = 'Pending'")).first['count'] as int? ?? 0;
  final inProgressJobs = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM jobs WHERE status = 'In Progress'")).first['count'] as int? ?? 0;
  final completedJobs = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM jobs WHERE status = 'Completed'")).first['count'] as int? ?? 0;
  final totalRevenue = (await db.rawQuery(
      "SELECT COALESCE(SUM(total_amount),0) as total FROM invoices WHERE payment_status = 'Paid'"))
      .first['total'] as num? ?? 0;
  final outstanding = (await db.rawQuery(
      "SELECT COALESCE(SUM(total_amount),0) as total FROM invoices WHERE payment_status = 'Unpaid'"))
      .first['total'] as num? ?? 0;

  return {
    'customers': customers,
    'vehicles': vehicles,
    'pendingJobs': pendingJobs,
    'inProgressJobs': inProgressJobs,
    'completedJobs': completedJobs,
    'totalRevenue': totalRevenue,
    'outstanding': outstanding,
  };
}
}