import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../domain/entities/employee.dart';
import '../bloc/voip_bloc.dart';
import '../bloc/voip_event.dart';
import '../bloc/voip_state.dart';

class VoipHubView extends StatefulWidget {
  const VoipHubView({super.key});

  @override
  State<VoipHubView> createState() => _VoipHubViewState();
}

class _VoipHubViewState extends State<VoipHubView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _callEmployee(BuildContext context, Employee employee) {
    context.read<VoipBloc>().add(
      InitiateVoipCallEvent(
        calleeId: employee.id,
        calleeName: employee.name,
        calleeRole: employee.role,
      ),
    );
    _tabController.animateTo(1);
    AppFeedback.showInfo(
      context,
      'Calling ${employee.name} via SRTP-AES256 channel...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoipBloc, VoipState>(
      listener: (context, state) {
        if (_tabController.index != state.activeTab) {
          _tabController.animateTo(state.activeTab);
        }
        if (state.feedbackMessage != null) {
          AppFeedback.showSuccess(context, state.feedbackMessage!);
        }
        if (state.errorMessage != null) {
          AppFeedback.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_voip_dialer',
            onPressed: () {
              if (state.isCallActive) {
                context.read<VoipBloc>().add(const EndVoipCallEvent());
              } else {
                context.read<VoipBloc>().add(const SwitchVoipTabEvent(1));
              }
            },
            icon: Icon(state.isCallActive ? Icons.call_end : Icons.dialpad),
            label: Text(
              state.isCallActive ? 'Terminate Call' : 'Keypad Cockpit',
            ),
            backgroundColor: state.isCallActive
                ? colorScheme.error
                : colorScheme.primary,
            foregroundColor: state.isCallActive
                ? colorScheme.onError
                : colorScheme.onPrimary,
          ),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (idx) =>
                    context.read<VoipBloc>().add(SwitchVoipTabEvent(idx)),
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.contacts, size: 20),
                    text: 'Directory & Channels',
                  ),
                  Tab(
                    icon: Icon(Icons.phone_in_talk, size: 20),
                    text: 'Active Cockpit & Keypad',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDirectoryTab(context, state, isLandscape),
                    _buildCockpitTab(context, state, isLandscape),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectoryTab(
    BuildContext context,
    VoipState state,
    bool isLandscape,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) =>
                context.read<VoipBloc>().add(SearchDirectoryEvent(val)),
            decoration: InputDecoration(
              hintText: 'Search organization members or channels...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<VoipBloc>().add(
                          const SearchDirectoryEvent(''),
                        );
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enterprise Members (${state.filteredDirectory.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredDirectory.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: colorScheme.outlineVariant, height: 16),
                    itemBuilder: (context, idx) {
                      final emp = state.filteredDirectory[idx];
                      return Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  emp.name.substring(0, 1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: emp.presenceStatus == 'Available'
                                        ? colorScheme.secondary
                                        : (emp.presenceStatus == 'In Call'
                                              ? colorScheme.error
                                              : colorScheme.primary),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${emp.department} • ${emp.role}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _callEmployee(context, emp),
                            icon: const Icon(Icons.call, size: 18),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCockpitTab(
    BuildContext context,
    VoipState state,
    bool isLandscape,
  ) {
    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildCallCockpitCard(context, state),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildKeypadCard(context, state),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCallCockpitCard(context, state),
          const SizedBox(height: 16),
          _buildKeypadCard(context, state),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCallCockpitCard(BuildContext context, VoipState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCallActive = state.isCallActive;
    final t = state.telemetry;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCallActive
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: isCallActive
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.cipher,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCallActive
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'MOS ${t.mosScore.toStringAsFixed(2)} • ${t.audioCodec}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: isCallActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                size: 38,
                color: isCallActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.activeCalleeName ?? 'No Active Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCallActive
                  ? 'Duration: ${AppFormatters.formatVoipDuration(t.callDurationSec)}'
                  : 'Ready for Encrypted Peer Connection',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            // Acoustic Waveforms
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    (t.waveforms.isNotEmpty
                            ? t.waveforms
                            : List.filled(16, 0.1))
                        .map((amp) {
                          return Container(
                            width: 6,
                            height: (amp * 36).clamp(4.0, 38.0),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: isCallActive
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        })
                        .toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  onPressed: isCallActive
                      ? () => context.read<VoipBloc>().add(
                          const ToggleVoipMuteEvent(),
                        )
                      : null,
                  icon: Icon(state.isMuted ? Icons.mic_off : Icons.mic),
                ),
                IconButton.filledTonal(
                  onPressed: isCallActive
                      ? () => context.read<VoipBloc>().add(
                          const ToggleVoipSpeakerEvent(),
                        )
                      : null,
                  icon: Icon(
                    state.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: isCallActive
                      ? () => context.read<VoipBloc>().add(
                          const ToggleVoipHoldEvent(),
                        )
                      : null,
                  icon: Icon(state.isOnHold ? Icons.play_arrow : Icons.pause),
                ),
                IconButton.filled(
                  onPressed: isCallActive
                      ? () => context.read<VoipBloc>().add(
                          const EndVoipCallEvent(),
                        )
                      : () {
                          context.read<VoipBloc>().add(
                            const InitiateVoipCallEvent(
                              calleeId: 'EMP-102',
                              calleeName: 'Zainab Tariq',
                              calleeRole: 'Lead Flutter Engineer',
                            ),
                          );
                        },
                  style: IconButton.styleFrom(
                    backgroundColor: isCallActive
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                  icon: Icon(
                    isCallActive ? Icons.call_end : Icons.call,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadCard(BuildContext context, VoipState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.dtmfBuffer.isNotEmpty
                    ? state.dtmfBuffer
                    : 'DTMF Keypad Buffer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                  color: state.dtmfBuffer.isNotEmpty
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children:
                  [
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                    '*',
                    '0',
                    '#',
                  ].map((digit) {
                    return OutlinedButton(
                      onPressed: () {
                        context.read<VoipBloc>().add(SendDtmfToneEvent(digit));
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        digit,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
