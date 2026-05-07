import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

class ServiceOrderPrint {
  static Future<void> printJob(Job job, BuildContext context) async {
    final db = DatabaseHelper.instance;

    // Get related data
    final customers = await db.getCustomers();
    final vehicles = await db.getVehicles();
    final users = await db.getUsers();
    final jobParts = await db.getJobPartsWithNames(job.id!);

    final customer =
        customers.firstWhere((c) => c.id == job.customerId, orElse: () => customers.first);
    final vehicle =
        vehicles.firstWhere((v) => v.id == job.vehicleId, orElse: () => vehicles.first);
    final technician = job.technicianId != null
        ? users.firstWhere((u) => u.id == job.technicianId,
            orElse: () => users.first)
        : null;

    // Calculate totals
    double totalMaterials = 0;
    for (final part in jobParts) {
      final qty = part['quantity'] as int;
      final price = (part['unit_price'] as num).toDouble();
      totalMaterials += qty * price;
    }
    final total = job.laborCost + totalMaterials;

    // Format date
    final dateStr = DateFormat('M/d/yy').format(DateTime.parse(job.createdAt));

    // Build the vehicle display name
    final vehicleDisplay = '${vehicle.make} ${vehicle.model}';

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'VERSED COOL CAR AIRCON SERVICE CENTER',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Jumbo Bridge, Punta Tabuc, Roxas City',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Contact No.: 0918-991-8617 / 0917-145-7867',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 12),

              // Customer & Vehicle Information
              pw.Text(
                'Customer & Vehicle Information',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 8),
              _infoLine('Customer\'s Name:', customer.name.toUpperCase()),
              _infoLine('Address:', (customer.address ?? 'N/A').toUpperCase()),
              _infoLine('Date:', dateStr),
              _infoLine('Car Type/Model:', vehicleDisplay.toUpperCase()),
              _infoLine('Plate Number:', vehicle.licensePlate.toUpperCase()),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),

              // Service Order Header
              pw.Center(
                child: pw.Text(
                  'SERVICE ORDER',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // I. Job to be done
              pw.Text(
                'I. Job to be done',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Padding(
                padding: pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final line in job.description.split('\n'))
                      pw.Padding(
                        padding: pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          '- $line',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Labor: ${_fmt(job.laborCost)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // II. Materials
              pw.Text(
                'II. Materials',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Padding(
                padding: pw.EdgeInsets.only(left: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final part in jobParts)
                      pw.Padding(
                        padding: pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          '${part['name']}: ${_fmt((part['quantity'] as int) * (part['unit_price'] as num).toDouble())}',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    if (jobParts.isEmpty)
                      pw.Text(
                        'No materials',
                        style: pw.TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Materials: ${_fmt(totalMaterials)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),

              // TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL: ___________________',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              if (total > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'P${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),

              pw.SizedBox(height: 24),

              // Prepared by
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Prepared by: ___________________',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (technician != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      technician.fullName,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static pw.Widget _infoLine(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static String _fmt(double amount) {
    return amount.toStringAsFixed(0);
  }
}