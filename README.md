# Car Technician Database System
**Group 6 — Car Tech DB**

A Flutter web/desktop/mobile app for managing a car repair workshop.

---

## Features
- **Login** — Role-based access (Admin, Technician, Receptionist)
- **Dashboard** — Stats: customers, vehicles, revenue, outstanding, job status
- **Customers** — Add/edit/delete, search by name or phone
- **Vehicles** — Add/edit/delete, linked to customers, search by plate/make/model
- **Jobs** — Create repair jobs, update status (Pending → In Progress → Completed), generate invoices
- **Inventory** — Car parts management with low-stock alerts
- **Invoices** — View all invoices, record payments (Cash / GCash / Card / Bank Transfer)
- **Users** *(Admin only)* — Create/edit/delete staff accounts

---

## Tech Stack
| Layer      | Technology            |
|------------|-----------------------|
| Framework  | Flutter 3.x           |
| Language   | Dart                  |
| Database   | SQLite via `sqflite`  |
| State Mgmt | `provider`            |
| Charts     | `fl_chart`            |

---

## Project Structure
```
lib/
├── main.dart                  # Entry point
├── db/
│   └── database_helper.dart   # SQLite CRUD layer
├── models/
│   └── models.dart            # Data models (User, Customer, Vehicle, Part, Job, Invoice, Payment)
├── providers/
│   └── auth_provider.dart     # Session / login state
├── screens/
│   ├── login_screen.dart
│   ├── main_shell.dart        # Nav rail + bottom nav
│   ├── dashboard_screen.dart
│   ├── customers_screen.dart
│   ├── vehicles_screen.dart
│   ├── jobs_screen.dart
│   ├── inventory_screen.dart
│   ├── invoices_screen.dart
│   └── users_screen.dart
└── theme/
    └── app_theme.dart         # Colors, theme, status helpers
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK 3.10+ → https://flutter.dev/docs/get-started/install
- Dart SDK (included with Flutter)
- Android Studio **or** VS Code with Flutter extension

### Steps

```bash
# 1. Extract the project folder
cd car_tech_db

# 2. Install dependencies
flutter pub get

# 3a. Run on Android (connect device or start emulator first)
flutter run

# 3b. Run on Web
flutter run -d chrome

# 3c. Run on Windows desktop. (this is what we are using right now)
flutter run -d windows

# 4. Build APK (Android)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# 5. Build for Web
flutter build web
# Output: build/web/
```

### First Launch
The app seeds demo data automatically on first run.

| Username | Password | Role         |
|----------|----------|--------------|
| admin    | admin123 | Admin        |
| tech1    | tech123  | Technician   |
| recep1   | recep123 | Receptionist |

---

## Database Schema
```
users         → id, username, password, role, full_name, created_at
customers     → id, name, phone, email, address, created_at
vehicles      → id, customer_id, make, model, year, vin, license_plate
parts         → id, name, part_number, description, quantity, unit_price, category, updated_at
jobs          → id, customer_id, vehicle_id, technician_id, description, status, labor_cost, notes, created_at, updated_at
job_parts     → id, job_id, part_id, quantity, unit_price
invoices      → id, job_id, invoice_number, total_amount, payment_status, created_at
payments      → id, invoice_id, amount, method, paid_at
```

---

## Sprint Schedule (per SPMP)
| Sprint | Dates            | Module                    |
|--------|-----------------|---------------------------|
| 1      | Feb 16 – Mar 1  | Car Parts Database Module |
| 2      | Mar 2 – Mar 22  | Customer Database Module  |
| 3      | Mar 23 – Apr 12 | Admin/Staff Database Module |
| 4      | Apr 13 – Apr 26 | Finalization & Integration |

---

## Team — Group 6
| Name                     | Role               |
|--------------------------|--------------------|
| Joaquin Daniel E. Jurquina | Project Manager  |
| K Giulian Cartojano      | Front End Developer |
| Seth Kyrios VM Gaitano   | Back End Developer |
| Lester Gianne Suerte     | Database Manager   |
| Daniel Vincent Loma      | Full Stack Support |
