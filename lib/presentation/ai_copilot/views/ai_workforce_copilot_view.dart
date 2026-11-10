import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_feedback.dart';
import '../cubit/ai_copilot_cubit.dart';
import '../cubit/ai_copilot_state.dart';

class AiWorkforceCopilotView extends StatefulWidget {
  const AiWorkforceCopilotView({super.key});

  @override
  State<AiWorkforceCopilotView> createState() => _AiWorkforceCopilotViewState();
}

class _AiWorkforceCopilotViewState extends State<AiWorkforceCopilotView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _promptChips = [
    "Audit This Month's Payroll & Overtime Variance",
    "Identify Field Dispatch Bottlenecks",
    "Draft Sprint Governance Summary",
    "Optimize Shift Coverage",
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendPrompt(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    context.read<AiCopilotCubit>().sendPrompt(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'fab_ai_ops_clear',
        tooltip: 'Clear Operations Transcript',
        onPressed: () {
          context.read<AiCopilotCubit>().clearConversation();
          AppFeedback.showInfo(context, 'Copilot transcript cleared.');
        },
        child: const Icon(Icons.clear_all),
      ),
      body: BlocConsumer<AiCopilotCubit, AiCopilotState>(
        listener: (context, state) {
          _scrollToBottom();
        },
        builder: (context, state) {
          return Column(
            children: [
              // Prompt chips bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _promptChips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final chipText = _promptChips[idx];
                    return ActionChip(
                      label: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onPressed: state.isStreaming
                          ? null
                          : () => _sendPrompt(chipText),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              // Message list
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: state.messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final msg = state.messages[idx];
                    final isUser = msg.role == 'user';

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.82,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? colorScheme.primary
                              : colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUser
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUser ? Icons.person : Icons.auto_awesome,
                                  size: 14,
                                  color: isUser
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isUser
                                      ? 'Executive Query'
                                      : 'OctetPulse Intelligence Engine',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUser
                                        ? colorScheme.onPrimary
                                        : colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              msg.content,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isUser
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.isStreaming && state.streamingStatusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.streamingStatusText!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Flush bottom input bar (safe on iOS and Android with software keyboard)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: state.isStreaming ? null : _sendPrompt,
                          decoration: InputDecoration(
                            hintText: 'Ask about attendance, payroll, or field SLAs...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.isStreaming
                            ? null
                            : () => _sendPrompt(_inputController.text),
                        icon: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
