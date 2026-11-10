import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final String id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String avatarAsset;
  final double baseSalaryUsd;
  final double hourlyRateUsd;
  final String presenceStatus; // Available, In Call, Field Dispatch, Offline

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.avatarAsset,
    required this.baseSalaryUsd,
    required this.hourlyRateUsd,
    this.presenceStatus = 'Available',
  });

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? role,
    String? avatarAsset,
    double? baseSalaryUsd,
    double? hourlyRateUsd,
    String? presenceStatus,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      baseSalaryUsd: baseSalaryUsd ?? this.baseSalaryUsd,
      hourlyRateUsd: hourlyRateUsd ?? this.hourlyRateUsd,
      presenceStatus: presenceStatus ?? this.presenceStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    department,
    role,
    avatarAsset,
    baseSalaryUsd,
    hourlyRateUsd,
    presenceStatus,
  ];
}
