import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../services/geofence_engine.dart';

class GeofenceZone extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<List<double>> vertices; // List of [lat, lng]
  final String colorHex;
  final bool isActive;
  final DateTime createdAt;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.description,
    required this.vertices,
    this.colorHex = '#1E88E5',
    this.isActive = true,
    required this.createdAt,
  });

  bool containsPoint(double lat, double lng) {
    return GeofenceEngine.isPointInPolygon(lat, lng, vertices);
  }

  double distanceToBoundaryMeters(double lat, double lng) {
    return GeofenceEngine.distanceToPolygonMeters(lat, lng, vertices);
  }

  List<double> get centerPoint {
    return GeofenceEngine.calculateCentroid(vertices);
  }

  double get areaSquareMeters {
    return GeofenceEngine.calculatePolygonAreaSquareMeters(vertices);
  }

  GeofenceZone copyWith({
    String? id,
    String? name,
    String? description,
    List<List<double>>? vertices,
    String? colorHex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GeofenceZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      vertices: vertices ?? this.vertices,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'verticesJson': jsonEncode(vertices),
      'colorHex': colorHex,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GeofenceZone.fromMap(Map<String, dynamic> map) {
    final rawVertices =
        jsonDecode(map['verticesJson'] as String) as List<dynamic>;
    final vertices = rawVertices
        .map(
          (coord) => (coord as List<dynamic>)
              .map((c) => (c as num).toDouble())
              .toList(),
        )
        .toList();

    return GeofenceZone(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      vertices: vertices,
      colorHex: (map['colorHex'] as String?) ?? '#1E88E5',
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    vertices,
    colorHex,
    isActive,
    createdAt,
  ];
}
