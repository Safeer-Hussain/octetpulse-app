import 'package:equatable/equatable.dart';

class FieldAgent extends Equatable {
  final String id;
  final String name;
  final String department;
  final String role;
  final double currentLat;
  final double currentLng;
  final double speedKmh;
  final int batteryLevelPercent;
  final bool isOnline;
  final int currentEtaMins;
  final String destinationName;
  final String? activeTaskId;
  final List<List<double>> routeCoordinates; // [[lat, lng], ...]

  const FieldAgent({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.currentLat,
    required this.currentLng,
    required this.speedKmh,
    required this.batteryLevelPercent,
    required this.isOnline,
    required this.currentEtaMins,
    required this.destinationName,
    this.activeTaskId,
    this.routeCoordinates = const [],
  });

  FieldAgent copyWith({
    String? id,
    String? name,
    String? department,
    String? role,
    double? currentLat,
    double? currentLng,
    double? speedKmh,
    int? batteryLevelPercent,
    bool? isOnline,
    int? currentEtaMins,
    String? destinationName,
    String? activeTaskId,
    List<List<double>>? routeCoordinates,
  }) {
    return FieldAgent(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      role: role ?? this.role,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      speedKmh: speedKmh ?? this.speedKmh,
      batteryLevelPercent: batteryLevelPercent ?? this.batteryLevelPercent,
      isOnline: isOnline ?? this.isOnline,
      currentEtaMins: currentEtaMins ?? this.currentEtaMins,
      destinationName: destinationName ?? this.destinationName,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        department,
        role,
        currentLat,
        currentLng,
        speedKmh,
        batteryLevelPercent,
        isOnline,
        currentEtaMins,
        destinationName,
        activeTaskId,
        routeCoordinates,
      ];
}
