import '../entities/dispatch_task.dart';
import '../entities/field_agent.dart';

abstract class DispatchRepository {
  Future<List<FieldAgent>> getFieldAgents();
  Future<List<DispatchTask>> getDispatchTasks();
  Future<void> updateAgentLocation(String agentId, double lat, double lng, double speed);
  Future<DispatchTask> assignTask(DispatchTask task);
  Future<DispatchTask> updateTaskStatus(String taskId, String status);
}
