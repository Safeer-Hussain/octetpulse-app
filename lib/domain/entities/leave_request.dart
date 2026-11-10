import 'package:equatable/equatable.dart';

class LeaveRequest extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final String requestType; // 'Annual Leave', 'Medical Emergency', 'Overtime Compensation', 'Field Travel'
  final double hours;
  final String reason;
  final DateTime submittedAt;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? approverComment;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.requestType,
    required this.hours,
    required this.reason,
    required this.submittedAt,
    this.status = 'Pending',
    this.approverComment,
  });

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? requestType,
    double? hours,
    String? reason,
    DateTime? submittedAt,
    String? status,
    String? approverComment,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      requestType: requestType ?? this.requestType,
      hours: hours ?? this.hours,
      reason: reason ?? this.reason,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      approverComment: approverComment ?? this.approverComment,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    requestType,
    hours,
    reason,
    submittedAt,
    status,
    approverComment,
  ];
}
