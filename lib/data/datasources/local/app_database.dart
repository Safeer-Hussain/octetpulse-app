import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../domain/services/tax_engine.dart';
import '../../../domain/services/transcript_simulator.dart';

class AppDatabase {
  static const String _dbName = 'octet_pulse_ledger.db';
  static const int _dbVersion = 4;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE payroll ADD COLUMN eobiContributionUsd REAL NOT NULL DEFAULT 1.33',
        );
        await db.execute(
          'ALTER TABLE payroll ADD COLUMN effectiveTaxRate REAL NOT NULL DEFAULT 15.0',
        );
        await db.execute(
          "ALTER TABLE payroll ADD COLUMN taxJurisdiction TEXT NOT NULL DEFAULT 'FBR_PKR'",
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS geofence_zones (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            verticesJson TEXT NOT NULL,
            colorHex TEXT NOT NULL,
            isActive INTEGER NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS voip_recordings (
            id TEXT PRIMARY KEY,
            callId TEXT NOT NULL,
            calleeId TEXT NOT NULL,
            calleeName TEXT NOT NULL,
            calleeRole TEXT NOT NULL,
            recordedAt TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            fileSizeBytes INTEGER NOT NULL,
            filePath TEXT NOT NULL,
            cipher TEXT NOT NULL,
            checksumSha256 TEXT NOT NULL,
            waveformsJson TEXT NOT NULL,
            transcriptJson TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        department TEXT NOT NULL,
        role TEXT NOT NULL,
        avatarAsset TEXT NOT NULL,
        baseSalaryUsd REAL NOT NULL,
        hourlyRateUsd REAL NOT NULL,
        presenceStatus TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        checkInTime TEXT NOT NULL,
        checkOutTime TEXT,
        durationSeconds INTEGER NOT NULL,
        status TEXT NOT NULL,
        isWithinGeofence INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        geofenceDistanceMeters REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE leave_requests (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        requestType TEXT NOT NULL,
        hours REAL NOT NULL,
        reason TEXT NOT NULL,
        submittedAt TEXT NOT NULL,
        status TEXT NOT NULL,
        approverComment TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payroll (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        department TEXT NOT NULL,
        role TEXT NOT NULL,
        baseSalaryUsd REAL NOT NULL,
        sprintBonusUsd REAL NOT NULL,
        overtimeHours REAL NOT NULL,
        overtimeRateMultiplier REAL NOT NULL,
        overtimePayUsd REAL NOT NULL,
        incomeTaxUsd REAL NOT NULL,
        providentFundUsd REAL NOT NULL,
        eobiContributionUsd REAL NOT NULL,
        effectiveTaxRate REAL NOT NULL,
        taxJurisdiction TEXT NOT NULL,
        netPayableUsd REAL NOT NULL,
        status TEXT NOT NULL,
        disbursedAt TEXT,
        monthYear TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dispatch_tasks (
        id TEXT PRIMARY KEY,
        agentId TEXT NOT NULL,
        agentName TEXT NOT NULL,
        title TEXT NOT NULL,
        clientName TEXT NOT NULL,
        locationAddress TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        assignedAt TEXT NOT NULL,
        slaDeadline TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE field_agents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        department TEXT NOT NULL,
        role TEXT NOT NULL,
        currentLat REAL NOT NULL,
        currentLng REAL NOT NULL,
        speedKmh REAL NOT NULL,
        batteryLevelPercent INTEGER NOT NULL,
        isOnline INTEGER NOT NULL,
        currentEtaMins INTEGER NOT NULL,
        destinationName TEXT NOT NULL,
        activeTaskId TEXT,
        routeCoordinates TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE voip_call_logs (
        id TEXT PRIMARY KEY,
        calleeId TEXT NOT NULL,
        calleeName TEXT NOT NULL,
        calleeRole TEXT NOT NULL,
        callType TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        cipher TEXT NOT NULL,
        audioCodec TEXT NOT NULL,
        mosScore REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE geofence_zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        verticesJson TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE voip_recordings (
        id TEXT PRIMARY KEY,
        callId TEXT NOT NULL,
        calleeId TEXT NOT NULL,
        calleeName TEXT NOT NULL,
        calleeRole TEXT NOT NULL,
        recordedAt TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        fileSizeBytes INTEGER NOT NULL,
        filePath TEXT NOT NULL,
        cipher TEXT NOT NULL,
        checksumSha256 TEXT NOT NULL,
        waveformsJson TEXT NOT NULL,
        transcriptJson TEXT NOT NULL
      )
    ''');
  }

  Future<void> seedInitialDataIfEmpty() async {
    final db = await database;
    await _seedGeofenceZonesIfEmpty(db);
    await _seedVoipRecordingsIfEmpty(db);

    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM employees'),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();

    // Seed 26 Employees across 4 Departments
    final employees = [
      {
        'id': 'EMP-101',
        'name': 'Safeer Hussain',
        'email': 'safeer.h@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'Principal Architect',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 9800.0,
        'hourly': 61.25,
        'status': 'Available',
      },
      {
        'id': 'EMP-102',
        'name': 'Zainab Tariq',
        'email': 'zainab.t@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'Lead Flutter Engineer',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 7500.0,
        'hourly': 46.88,
        'status': 'Available',
      },
      {
        'id': 'EMP-103',
        'name': 'Ahmed Raza',
        'email': 'ahmed.r@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'Senior iOS Engineer',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 6800.0,
        'hourly': 42.50,
        'status': 'In Call',
      },
      {
        'id': 'EMP-104',
        'name': 'Bilal Farooq',
        'email': 'bilal.f@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'Senior Android Engineer',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 6800.0,
        'hourly': 42.50,
        'status': 'Available',
      },
      {
        'id': 'EMP-105',
        'name': 'Fatima Noor',
        'email': 'fatima.n@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'UI/UX Design Lead',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 6200.0,
        'hourly': 38.75,
        'status': 'Available',
      },
      {
        'id': 'EMP-106',
        'name': 'Usman Ali',
        'email': 'usman.a@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Field Ops Director',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 7200.0,
        'hourly': 45.00,
        'status': 'Available',
      },
      {
        'id': 'EMP-107',
        'name': 'Hamza Sheikh',
        'email': 'hamza.s@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Senior Field Engineer',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 5400.0,
        'hourly': 33.75,
        'status': 'Field Dispatch',
      },
      {
        'id': 'EMP-108',
        'name': 'Mustafa Khan',
        'email': 'mustafa.k@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Network Dispatch Lead',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 5600.0,
        'hourly': 35.00,
        'status': 'Field Dispatch',
      },
      {
        'id': 'EMP-109',
        'name': 'Omer Qureshi',
        'email': 'omer.q@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Field Specialist',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 4800.0,
        'hourly': 30.00,
        'status': 'Available',
      },
      {
        'id': 'EMP-110',
        'name': 'Ayesha Malik',
        'email': 'ayesha.m@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Site Reliability Engineer',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 5900.0,
        'hourly': 36.88,
        'status': 'Field Dispatch',
      },
      {
        'id': 'EMP-111',
        'name': 'Danish Baig',
        'email': 'danish.b@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'Cloud Platform Architect',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 8900.0,
        'hourly': 55.63,
        'status': 'Available',
      },
      {
        'id': 'EMP-112',
        'name': 'Khadija Rehman',
        'email': 'khadija.r@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'DevOps Lead',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 7400.0,
        'hourly': 46.25,
        'status': 'In Call',
      },
      {
        'id': 'EMP-113',
        'name': 'Saad Siddiqui',
        'email': 'saad.s@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'Kubernetes Administrator',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 6600.0,
        'hourly': 41.25,
        'status': 'Available',
      },
      {
        'id': 'EMP-114',
        'name': 'Mariam Javed',
        'email': 'mariam.j@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'Backend Systems Engineer',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 6300.0,
        'hourly': 39.38,
        'status': 'Available',
      },
      {
        'id': 'EMP-115',
        'name': 'Tariq Mehmood',
        'email': 'tariq.m@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'Database Reliability Lead',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 7100.0,
        'hourly': 44.38,
        'status': 'Available',
      },
      {
        'id': 'EMP-116',
        'name': 'Shahmeer Khan',
        'email': 'shahmeer.k@octetpulse.io',
        'department': 'Security & Compliance',
        'role': 'Chief Security Officer',
        'avatar': 'assets/images/avatar_security.png',
        'salary': 9400.0,
        'hourly': 58.75,
        'status': 'Available',
      },
      {
        'id': 'EMP-117',
        'name': 'Hina Bashir',
        'email': 'hina.b@octetpulse.io',
        'department': 'Security & Compliance',
        'role': 'Security Analyst',
        'avatar': 'assets/images/avatar_security.png',
        'salary': 6500.0,
        'hourly': 40.63,
        'status': 'Available',
      },
      {
        'id': 'EMP-118',
        'name': 'Waqas Akram',
        'email': 'waqas.a@octetpulse.io',
        'department': 'Security & Compliance',
        'role': 'Compliance Auditor',
        'avatar': 'assets/images/avatar_security.png',
        'salary': 6100.0,
        'hourly': 38.13,
        'status': 'In Call',
      },
      {
        'id': 'EMP-119',
        'name': 'Noman Butt',
        'email': 'noman.b@octetpulse.io',
        'department': 'Security & Compliance',
        'role': 'Cryptographic Protocol Eng',
        'avatar': 'assets/images/avatar_security.png',
        'salary': 7800.0,
        'hourly': 48.75,
        'status': 'Available',
      },
      {
        'id': 'EMP-120',
        'name': 'Sana Yousaf',
        'email': 'sana.y@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'QA Automation Lead',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 5800.0,
        'hourly': 36.25,
        'status': 'Available',
      },
      {
        'id': 'EMP-121',
        'name': 'Adnan Zafar',
        'email': 'adnan.z@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Hardware Diagnostics Eng',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 5200.0,
        'hourly': 32.50,
        'status': 'Available',
      },
      {
        'id': 'EMP-122',
        'name': 'Rabia Chaudhry',
        'email': 'rabia.c@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'Site Telemetry Eng',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 6400.0,
        'hourly': 40.00,
        'status': 'Available',
      },
      {
        'id': 'EMP-123',
        'name': 'Kashif Lodhi',
        'email': 'kashif.l@octetpulse.io',
        'department': 'Security & Compliance',
        'role': 'Penetration Tester',
        'avatar': 'assets/images/avatar_security.png',
        'salary': 7300.0,
        'hourly': 45.63,
        'status': 'Available',
      },
      {
        'id': 'EMP-124',
        'name': 'Farhan Gill',
        'email': 'farhan.g@octetpulse.io',
        'department': 'Mobile Engineering',
        'role': 'WebRTC Protocol Engineer',
        'avatar': 'assets/images/avatar_mobile.png',
        'salary': 7600.0,
        'hourly': 47.50,
        'status': 'In Call',
      },
      {
        'id': 'EMP-125',
        'name': 'Mahnoor Aslam',
        'email': 'mahnoor.a@octetpulse.io',
        'department': 'Field Operations',
        'role': 'Client Dispatch Manager',
        'avatar': 'assets/images/avatar_field.png',
        'salary': 6100.0,
        'hourly': 38.13,
        'status': 'Available',
      },
      {
        'id': 'EMP-126',
        'name': 'Zubair Shah',
        'email': 'zubair.s@octetpulse.io',
        'department': 'Cloud Infrastructure',
        'role': 'FinOps & Billing Specialist',
        'avatar': 'assets/images/avatar_cloud.png',
        'salary': 6900.0,
        'hourly': 43.13,
        'status': 'Available',
      },
    ];

    for (final emp in employees) {
      batch.insert('employees', {
        'id': emp['id'],
        'name': emp['name'],
        'email': emp['email'],
        'department': emp['department'],
        'role': emp['role'],
        'avatarAsset': emp['avatar'],
        'baseSalaryUsd': emp['salary'],
        'hourlyRateUsd': emp['hourly'],
        'presenceStatus': emp['status'],
      });
    }

    // Seed Initial Attendance
    final now = DateTime.now();
    batch.insert('attendance', {
      'id': 'ATT-001',
      'employeeId': 'EMP-101',
      'employeeName': 'Safeer Hussain',
      'checkInTime': now
          .subtract(const Duration(hours: 4, minutes: 12))
          .toIso8601String(),
      'checkOutTime': null,
      'durationSeconds': 15120,
      'status': 'Clocked In',
      'isWithinGeofence': 1,
      'latitude': 31.4755,
      'longitude': 74.3438,
      'geofenceDistanceMeters': 28.4,
    });

    batch.insert('attendance', {
      'id': 'ATT-002',
      'employeeId': 'EMP-102',
      'employeeName': 'Zainab Tariq',
      'checkInTime': now
          .subtract(const Duration(hours: 5, minutes: 30))
          .toIso8601String(),
      'checkOutTime': null,
      'durationSeconds': 19800,
      'status': 'Clocked In',
      'isWithinGeofence': 1,
      'latitude': 31.4754,
      'longitude': 74.3435,
      'geofenceDistanceMeters': 12.0,
    });

    // Seed Pending Team Lead Leave Requests
    batch.insert('leave_requests', {
      'id': 'LV-8801',
      'employeeId': 'EMP-107',
      'employeeName': 'Hamza Sheikh',
      'requestType': 'Overtime Compensation',
      'hours': 8.0,
      'reason':
          'Deployment of Gulberg tech corridor fiber uplink over weekend.',
      'submittedAt': now.subtract(const Duration(hours: 14)).toIso8601String(),
      'status': 'Pending',
      'approverComment': null,
    });

    batch.insert('leave_requests', {
      'id': 'LV-8802',
      'employeeId': 'EMP-110',
      'employeeName': 'Ayesha Malik',
      'requestType': 'Field Travel',
      'hours': 16.0,
      'reason': 'On-site core switch disaster recovery validation at DHA Phase 5 node.',
      'submittedAt': now.subtract(const Duration(hours: 22)).toIso8601String(),
      'status': 'Pending',
      'approverComment': null,
    });

    // Seed Monthly Payroll Batch Records (26 Employees)
    for (final emp in employees) {
      final base = (emp['salary'] as num).toDouble();
      final hourly = (emp['hourly'] as num).toDouble();
      final otHours =
          (emp['id'] == 'EMP-101' ||
              emp['id'] == 'EMP-107' ||
              emp['id'] == 'EMP-111')
          ? 14.0
          : 4.0;
      final otPay = otHours * hourly * 1.5;
      final sprintBonus = 500.0;
      final gross = base + otPay + sprintBonus;
      final taxResult = TaxEngine.calculateFbrTax(monthlyGrossUsd: gross);

      batch.insert('payroll', {
        'id': 'PAY-${emp['id']}',
        'employeeId': emp['id'],
        'employeeName': emp['name'],
        'department': emp['department'],
        'role': emp['role'],
        'baseSalaryUsd': base,
        'sprintBonusUsd': sprintBonus,
        'overtimeHours': otHours,
        'overtimeRateMultiplier': 1.5,
        'overtimePayUsd': otPay,
        'incomeTaxUsd': taxResult.monthlyTaxUsd,
        'providentFundUsd': taxResult.providentFundMonthlyUsd,
        'eobiContributionUsd': taxResult.eobiEmployeeMonthlyUsd,
        'effectiveTaxRate': taxResult.effectiveTaxRate,
        'taxJurisdiction': 'FBR_PKR',
        'netPayableUsd': taxResult.netMonthlyPayableUsd,
        'status': emp['id'] == 'EMP-101' ? 'Disbursed' : 'Pending',
        'disbursedAt': emp['id'] == 'EMP-101'
            ? now.subtract(const Duration(days: 2)).toIso8601String()
            : null,
        'monthYear': 'November 2026',
      });
    }

    // Seed Field Agents across Lahore Tech Corridors
    final fieldAgents = [
      {
        'id': 'AGT-01',
        'name': 'Hamza Sheikh',
        'department': 'Field Operations',
        'role': 'Senior Field Engineer',
        'lat': 31.5204, // Gulberg Main Boulevard
        'lng': 74.3587,
        'speed': 42.5,
        'battery': 88,
        'online': 1,
        'eta': 14,
        'dest': 'Netsol IT Tower, Ring Road',
        'taskId': 'TSK-501',
        'route': [
          [31.4754, 74.3436],
          [31.4920, 74.3510],
          [31.5110, 74.3550],
          [31.5204, 74.3587],
        ],
      },
      {
        'id': 'AGT-02',
        'name': 'Mustafa Khan',
        'department': 'Field Operations',
        'role': 'Network Dispatch Lead',
        'lat': 31.4697, // Model Town Link Road
        'lng': 74.3164,
        'speed': 35.0,
        'battery': 74,
        'online': 1,
        'eta': 9,
        'dest': 'Systems Ltd Campus, Johar Town',
        'taskId': 'TSK-502',
        'route': [
          [31.4754, 74.3436],
          [31.4720, 74.3300],
          [31.4697, 74.3164],
        ],
      },
      {
        'id': 'AGT-03',
        'name': 'Ayesha Malik',
        'department': 'Field Operations',
        'role': 'Site Reliability Engineer',
        'lat': 31.4820, // DHA Phase 5 Commercial Node
        'lng': 74.4010,
        'speed': 54.2,
        'battery': 92,
        'online': 1,
        'eta': 22,
        'dest': 'DHA Phase 5 Core Telecom Vault',
        'taskId': 'TSK-503',
        'route': [
          [31.4754, 74.3436],
          [31.4780, 74.3700],
          [31.4820, 74.4010],
        ],
      },
      {
        'id': 'AGT-04',
        'name': 'Omer Qureshi',
        'department': 'Field Operations',
        'role': 'Field Specialist',
        'lat': 31.4754, // ASTP HQ Standby
        'lng': 74.3436,
        'speed': 0.0,
        'battery': 99,
        'online': 1,
        'eta': 0,
        'dest': 'HQ Standby Rapid Response',
        'taskId': null,
        'route': [
          [31.4754, 74.3436],
        ],
      },
    ];

    for (final agt in fieldAgents) {
      batch.insert('field_agents', {
        'id': agt['id'],
        'name': agt['name'],
        'department': agt['department'],
        'role': agt['role'],
        'currentLat': agt['lat'],
        'currentLng': agt['lng'],
        'speedKmh': agt['speed'],
        'batteryLevelPercent': agt['battery'],
        'isOnline': agt['online'],
        'currentEtaMins': agt['eta'],
        'destinationName': agt['dest'],
        'activeTaskId': agt['taskId'],
        'routeCoordinates': jsonEncode(agt['route']),
      });
    }

    // Seed Dispatch Tasks
    batch.insert('dispatch_tasks', {
      'id': 'TSK-501',
      'agentId': 'AGT-01',
      'agentName': 'Hamza Sheikh',
      'title': 'High-Density Switch Configuration',
      'clientName': 'Netsol Technologies',
      'locationAddress': 'Netsol IT Tower, Main Ring Road, Lahore',
      'latitude': 31.5204,
      'longitude': 74.3587,
      'priority': 'Critical',
      'status': 'In Transit',
      'assignedAt': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      'slaDeadline': now.add(const Duration(hours: 2)).toIso8601String(),
    });

    batch.insert('dispatch_tasks', {
      'id': 'TSK-502',
      'agentId': 'AGT-02',
      'agentName': 'Mustafa Khan',
      'title': 'Redundant Fiber Backhaul Audit',
      'clientName': 'Systems Limited',
      'locationAddress': 'E-1 Commercial, Johar Town, Lahore',
      'latitude': 31.4697,
      'longitude': 74.3164,
      'priority': 'High',
      'status': 'In Transit',
      'assignedAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
      'slaDeadline': now.add(const Duration(hours: 3)).toIso8601String(),
    });

    batch.insert('dispatch_tasks', {
      'id': 'TSK-503',
      'agentId': 'AGT-03',
      'agentName': 'Ayesha Malik',
      'title': 'Optical Transceiver Replacement',
      'clientName': 'Telecom Central Hub',
      'locationAddress': 'Sector C, Phase 5 DHA, Lahore',
      'latitude': 31.4820,
      'longitude': 74.4010,
      'priority': 'Standard',
      'status': 'In Transit',
      'assignedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'slaDeadline': now.add(const Duration(hours: 4)).toIso8601String(),
    });

    // Seed VoIP Call Logs
    batch.insert('voip_call_logs', {
      'id': 'CALL-901',
      'calleeId': 'EMP-102',
      'calleeName': 'Zainab Tariq',
      'calleeRole': 'Lead Flutter Engineer',
      'callType': 'Outbound',
      'durationSeconds': 245,
      'timestamp': now
          .subtract(const Duration(hours: 2, minutes: 15))
          .toIso8601String(),
      'cipher': 'SRTP-AES256',
      'audioCodec': 'OPUS-HD',
      'mosScore': 4.38,
    });

    batch.insert('voip_call_logs', {
      'id': 'CALL-902',
      'calleeId': 'EMP-111',
      'calleeName': 'Danish Baig',
      'calleeRole': 'Cloud Platform Architect',
      'callType': 'Inbound',
      'durationSeconds': 512,
      'timestamp': now
          .subtract(const Duration(hours: 4, minutes: 50))
          .toIso8601String(),
      'cipher': 'SRTP-AES256',
      'audioCodec': 'OPUS-HD',
      'mosScore': 4.42,
    });

    await batch.commit(noResult: true);
  }

  Future<void> _seedGeofenceZonesIfEmpty(Database db) async {
    try {
      final zoneCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM geofence_zones'),
          ) ??
          0;

      if (zoneCount == 0) {
        final zoneBatch = db.batch();
        zoneBatch.insert('geofence_zones', {
          'id': 'ZONE-ASTP-HQ',
          'name': 'Arfa Software Technology Park Main Campus',
          'description': 'Primary corporate IT campus polygon encompassing ASTP tower, auditorium, and parking plaza.',
          'verticesJson': jsonEncode([
            [31.4770, 74.3418],
            [31.4772, 74.3455],
            [31.4738, 74.3460],
            [31.4735, 74.3422],
            [31.4750, 74.3415],
          ]),
          'colorHex': '#1E88E5',
          'isActive': 1,
          'createdAt': DateTime.now().toIso8601String(),
        });

        zoneBatch.insert('geofence_zones', {
          'id': 'ZONE-GULBERG',
          'name': 'Gulberg Tech Hub Campus',
          'description': 'Secondary executive engineering facility along Main Boulevard Gulberg.',
          'verticesJson': jsonEncode([
            [31.5200, 74.3520],
            [31.5215, 74.3580],
            [31.5160, 74.3590],
            [31.5145, 74.3530],
          ]),
          'colorHex': '#43A047',
          'isActive': 0,
          'createdAt': DateTime.now().toIso8601String(),
        });
        await zoneBatch.commit(noResult: true);
      }
    } catch (_) {}
  }

  Future<void> _seedVoipRecordingsIfEmpty(Database db) async {
    try {
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM voip_recordings'),
          ) ??
          0;

      if (count == 0) {
        final rec1 = TranscriptSimulator.simulateRecording(
          recordingId: 'REC-74A82F',
          callId: 'call_102_001',
          calleeId: 'EMP-102',
          calleeName: 'Zainab Tariq',
          calleeRole: 'Lead Flutter Engineer',
          durationSeconds: 48,
          recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
        );

        final rec2 = TranscriptSimulator.simulateRecording(
          recordingId: 'REC-91E33B',
          callId: 'call_105_002',
          calleeId: 'EMP-105',
          calleeName: 'Tariq Mahmood',
          calleeRole: 'Field Operations Specialist',
          durationSeconds: 32,
          recordedAt: DateTime.now().subtract(
            const Duration(days: 1, hours: 2),
          ),
        );

        final batch = db.batch();
        batch.insert('voip_recordings', rec1.toMap());
        batch.insert('voip_recordings', rec2.toMap());
        await batch.commit(noResult: true);
      }
    } catch (_) {}
  }
}
