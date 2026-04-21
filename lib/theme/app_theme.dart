import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A237E); // Deep navy blue
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color accent = Color(0xFFFF6F00); // Amber orange
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}

class JobStatus {
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';

  static Color color(String status) {
    switch (status) {
      case pending:
        return AppTheme.warning;
      case inProgress:
        return AppTheme.primaryLight;
      case completed:
        return AppTheme.success;
      default:
        return Colors.grey;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case pending:
        return Icons.schedule;
      case inProgress:
        return Icons.build;
      case completed:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

class PaymentStatus {
  static const String paid = 'Paid';
  static const String unpaid = 'Unpaid';
  static const String partial = 'Partial';

  static Color color(String status) {
    switch (status) {
      case paid:
        return AppTheme.success;
      case unpaid:
        return AppTheme.danger;
      case partial:
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }
}

class UserRole {
  static const String admin = 'Admin';
  static const String technician = 'Technician';
  static const String receptionist = 'Receptionist';

  static List<String> get all => [admin, technician, receptionist];

  static Color color(String role) {
    switch (role) {
      case admin:
        return AppTheme.primary;
      case technician:
        return AppTheme.primaryLight;
      case receptionist:
        return AppTheme.accent;
      default:
        return Colors.grey;
    }
  }
}
