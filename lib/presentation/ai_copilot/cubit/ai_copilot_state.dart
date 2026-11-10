import 'package:equatable/equatable.dart';

class CopilotMessage extends Equatable {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  const CopilotMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  CopilotMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return CopilotMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [id, role, content, timestamp, isStreaming];
}

class AiCopilotState extends Equatable {
  final List<CopilotMessage> messages;
  final bool isStreaming;
  final String? streamingStatusText;

  const AiCopilotState({
    this.messages = const [],
    this.isStreaming = false,
    this.streamingStatusText,
  });

  AiCopilotState copyWith({
    List<CopilotMessage>? messages,
    bool? isStreaming,
    String? streamingStatusText,
    bool clearStatusText = false,
  }) {
    return AiCopilotState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingStatusText: clearStatusText
          ? null
          : (streamingStatusText ?? this.streamingStatusText),
    );
  }

  @override
  List<Object?> get props => [messages, isStreaming, streamingStatusText];
}
