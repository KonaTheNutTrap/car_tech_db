// ── USER ──────────────────────────────────────────
class User {
  final int? id;
  final String username;
  final String password;
  final String role; // Admin | Technician | Receptionist
  final String fullName;
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        password: map['password'],
        role: map['role'],
        fullName: map['full_name'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password': password,
        'role': role,
        'full_name': fullName,
        'created_at': createdAt,
      };

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? fullName,
    String? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ── CUSTOMER ──────────────────────────────────────
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        email: map['email'],
        address: map['address'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'created_at': createdAt,
      };

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? createdAt,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ── VEHICLE ───────────────────────────────────────
class Vehicle {
  final int? id;
  final int customerId;
  final String make;
  final String model;
  final int year;
  final String? vin;
  final String licensePlate;

  Vehicle({
    this.id,
    required this.customerId,
    required this.make,
    required this.model,
    required this.year,
    this.vin,
    required this.licensePlate,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'],
        customerId: map['customer_id'],
        make: map['make'],
        model: map['model'],
        year: map['year'],
        vin: map['vin'],
        licensePlate: map['license_plate'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'make': make,
        'model': model,
        'year': year,
        'vin': vin,
        'license_plate': licensePlate,
      };

  String get displayName => '$year $make $model';

  Vehicle copyWith({
    int? id,
    int? customerId,
    String? make,
    String? model,
    int? year,
    String? vin,
    String? licensePlate,
  }) =>
      Vehicle(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        make: make ?? this.make,
        model: model ?? this.model,
        year: year ?? this.year,
        vin: vin ?? this.vin,
        licensePlate: licensePlate ?? this.licensePlate,
      );
}

// ── PART ──────────────────────────────────────────
class Part {
  final int? id;
  final String name;
  final String? partNumber;
  final String? description;
  final int quantity;
  final double unitPrice;
  final String? category;
  final String updatedAt;

  Part({
    this.id,
    required this.name,
    this.partNumber,
    this.description,
    required this.quantity,
    required this.unitPrice,
    this.category,
    required this.updatedAt,
  });

  factory Part.fromMap(Map<String, dynamic> map) => Part(
        id: map['id'],
        name: map['name'],
        partNumber: map['part_number'],
        description: map['description'],
        quantity: map['quantity'],
        unitPrice: (map['unit_price'] as num).toDouble(),
        category: map['category'],
        updatedAt: map['updated_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'part_number': partNumber,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'category': category,
        'updated_at': updatedAt,
      };

  Part copyWith({
    int? id,
    String? name,
    String? partNumber,
    String? description,
    int? quantity,
    double? unitPrice,
    String? category,
    String? updatedAt,
  }) =>
      Part(
        id: id ?? this.id,
        name: name ?? this.name,
        partNumber: partNumber ?? this.partNumber,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        category: category ?? this.category,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── JOB ───────────────────────────────────────────
class Job {
  final int? id;
  final int customerId;
  final int vehicleId;
  final int? technicianId;
  final String description;
  final String status; // Pending | In Progress | Completed
  final double laborCost;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Job({
    this.id,
    required this.customerId,
    required this.vehicleId,
    this.technicianId,
    required this.description,
    this.status = 'Pending',
    this.laborCost = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Job.fromMap(Map<String, dynamic> map) => Job(
        id: map['id'],
        customerId: map['customer_id'],
        vehicleId: map['vehicle_id'],
        technicianId: map['technician_id'],
        description: map['description'],
        status: map['status'],
        laborCost: (map['labor_cost'] as num?)?.toDouble() ?? 0,
        notes: map['notes'],
        createdAt: map['created_at'],
        updatedAt: map['updated_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'technician_id': technicianId,
        'description': description,
        'status': status,
        'labor_cost': laborCost,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Job copyWith({
    int? id,
    int? customerId,
    int? vehicleId,
    int? technicianId,
    String? description,
    String? status,
    double? laborCost,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) =>
      Job(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        vehicleId: vehicleId ?? this.vehicleId,
        technicianId: technicianId ?? this.technicianId,
        description: description ?? this.description,
        status: status ?? this.status,
        laborCost: laborCost ?? this.laborCost,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── JOB PART ──────────────────────────────────────
class JobPart {
  final int? id;
  final int jobId;
  final int partId;
  final int quantity;
  final double unitPrice;

  JobPart({
    this.id,
    required this.jobId,
    required this.partId,
    required this.quantity,
    required this.unitPrice,
  });

  factory JobPart.fromMap(Map<String, dynamic> map) => JobPart(
        id: map['id'],
        jobId: map['job_id'],
        partId: map['part_id'],
        quantity: map['quantity'],
        unitPrice: (map['unit_price'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'job_id': jobId,
        'part_id': partId,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  double get subtotal => quantity * unitPrice;
}

// ── INVOICE ───────────────────────────────────────
class Invoice {
  final int? id;
  final int jobId;
  final String invoiceNumber;
  final double totalAmount;
  final String paymentStatus; // Paid | Unpaid | Partial
  final String createdAt;

  Invoice({
    this.id,
    required this.jobId,
    required this.invoiceNumber,
    required this.totalAmount,
    this.paymentStatus = 'Unpaid',
    required this.createdAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
        id: map['id'],
        jobId: map['job_id'],
        invoiceNumber: map['invoice_number'],
        totalAmount: (map['total_amount'] as num).toDouble(),
        paymentStatus: map['payment_status'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'job_id': jobId,
        'invoice_number': invoiceNumber,
        'total_amount': totalAmount,
        'payment_status': paymentStatus,
        'created_at': createdAt,
      };

  Invoice copyWith({
    int? id,
    int? jobId,
    String? invoiceNumber,
    double? totalAmount,
    String? paymentStatus,
    String? createdAt,
  }) =>
      Invoice(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        totalAmount: totalAmount ?? this.totalAmount,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ── PAYMENT ───────────────────────────────────────
class Payment {
  final int? id;
  final int invoiceId;
  final double amount;
  final String method; // Cash | GCash | Card | Bank Transfer
  final String paidAt;

  Payment({
    this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.paidAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'],
        invoiceId: map['invoice_id'],
        amount: (map['amount'] as num).toDouble(),
        method: map['method'],
        paidAt: map['paid_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'invoice_id': invoiceId,
        'amount': amount,
        'method': method,
        'paid_at': paidAt,
      };
}
