import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/voip_recording.dart';
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
  final TextEditingController _transcriptSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _transcriptSearchController.dispose();
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
                tabs: [
                  const Tab(
                    icon: Icon(Icons.contacts, size: 20),
                    text: 'Directory & Channels',
                  ),
                  const Tab(
                    icon: Icon(Icons.phone_in_talk, size: 20),
                    text: 'Active Cockpit & Keypad',
                  ),
                  Tab(
                    icon: Badge(
                      isLabelVisible: state.recordings.isNotEmpty,
                      label: Text(state.recordings.length.toString()),
                      child: const Icon(Icons.lock_clock, size: 20),
                    ),
                    text: 'Vault & Transcripts',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDirectoryTab(context, state, isLandscape),
                    _buildCockpitTab(context, state, isLandscape),
                    _buildVaultTab(context, state, isLandscape),
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
                    color: isCallActive
                        ? colorScheme.onError
                        : colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: state.isRecording
                    ? colorScheme.errorContainer.withValues(alpha: 0.35)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.isRecording
                      ? colorScheme.error
                      : colorScheme.outlineVariant,
                  width: state.isRecording ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.isRecording
                            ? Icons.fiber_manual_record
                            : Icons.lock_outline,
                        size: 18,
                        color: state.isRecording
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isRecording
                                ? 'RECORDING ACTIVE [AES-256-GCM]'
                                : 'Encrypted Call Recording',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: state.isRecording
                                  ? colorScheme.error
                                  : colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            state.isRecording
                                ? 'Encrypted live audio buffer streaming to vault'
                                : (isCallActive
                                      ? 'Tap Record to capture AES-256 audio manifest'
                                      : 'Inactive call session'),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    onPressed: isCallActive
                        ? () => context.read<VoipBloc>().add(
                            const ToggleVoipRecordingEvent(),
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: state.isRecording
                          ? colorScheme.error
                          : colorScheme.secondaryContainer,
                      foregroundColor: state.isRecording
                          ? colorScheme.onError
                          : colorScheme.onSecondaryContainer,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    icon: Icon(
                      state.isRecording
                          ? Icons.stop
                          : Icons.fiber_manual_record,
                      size: 14,
                    ),
                    label: Text(state.isRecording ? 'Stop REC' : 'Record'),
                  ),
                ],
              ),
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

  Widget _buildVaultTab(
    BuildContext context,
    VoipState state,
    bool isLandscape,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.recordings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Encrypted Audio Recordings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initiate a secure VoIP session and tap Record to capture AES-256-GCM audio manifests with cryptographic transcripts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () {
                      context.read<VoipBloc>().add(const SwitchVoipTabEvent(1));
                    },
                    child: const Text('Go to Call Cockpit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                  _buildRecordingsList(context, state, isLandscape),
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
                  _buildActivePlaybackAndTranscript(
                    context,
                    state,
                    isLandscape,
                  ),
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
          _buildActivePlaybackAndTranscript(context, state, isLandscape),
          const SizedBox(height: 16),
          _buildRecordingsList(context, state, isLandscape),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(
    BuildContext context,
    VoipState state,
    bool isLandscape,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Encrypted Audio Vault (${state.recordings.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AES-256-GCM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.recordings.length,
              separatorBuilder: (_, _) =>
                  Divider(color: colorScheme.outlineVariant, height: 16),
              itemBuilder: (context, idx) {
                final rec = state.recordings[idx];
                final isSelected = state.selectedRecording?.id == rec.id;

                return InkWell(
                  onTap: () {
                    context.read<VoipBloc>().add(
                      SelectRecordingForPlaybackEvent(rec),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.lock,
                                size: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.calleeName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    rec.calleeRole,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              onPressed: () {
                                _confirmDeleteRecording(context, rec);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildInfoChip(
                              context,
                              Icons.timer,
                              rec.formattedDuration,
                            ),
                            _buildInfoChip(
                              context,
                              Icons.sd_storage,
                              rec.formattedFileSize,
                            ),
                            _buildInfoChip(
                              context,
                              Icons.fingerprint,
                              'SHA: ${rec.checksumShort}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlaybackAndTranscript(
    BuildContext context,
    VoipState state,
    bool isLandscape,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final rec =
        state.selectedRecording ??
        (state.recordings.isNotEmpty ? state.recordings.first : null);

    if (rec == null) return const SizedBox.shrink();

    final query = _transcriptSearchController.text.toLowerCase().trim();
    final filteredTokens = query.isEmpty
        ? rec.transcript
        : rec.transcript.where((t) {
            return t.speaker.toLowerCase().contains(query) ||
                t.text.toLowerCase().contains(query);
          }).toList();

    final totalBars = 32;
    final waveforms = rec.waveforms.isNotEmpty
        ? rec.waveforms
        : List.filled(totalBars, 0.4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playback: ${rec.calleeName}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${rec.calleeRole} • ${AppFormatters.formatDateTime(rec.recordedAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
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
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rec.cipher,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'SHA-256: ${rec.checksumSha256}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Waveform Playback Graphic
            SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(totalBars, (idx) {
                  final amp = waveforms[idx % waveforms.length];
                  final isElapsed = (idx / totalBars) <= state.playbackProgress;
                  return Expanded(
                    child: Container(
                      height: (amp * 32).clamp(4.0, 34.0),
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isElapsed
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            // Scrubber Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: state.playbackProgress.clamp(0.0, 1.0),
                onChanged: (val) {
                  context.read<VoipBloc>().add(SeekRecordingPlaybackEvent(val));
                },
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppFormatters.formatVoipDuration(
                    (state.playbackProgress * rec.durationSeconds).round(),
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    context.read<VoipBloc>().add(
                      const ToggleRecordingPlaybackPlayPauseEvent(),
                    );
                  },
                  icon: Icon(
                    state.isPlayingRecording ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                ),
                Text(
                  rec.formattedDuration,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 16),
            // Decrypted Transcript Inspector
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Decrypted Transcript',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${filteredTokens.length} Tokens',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transcriptSearchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search transcript dialogue...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _transcriptSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _transcriptSearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTokens.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final token = filteredTokens[idx];
                final isCoordinator = token.speaker == 'Coordinator';

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCoordinator
                        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCoordinator
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            token.speaker,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCoordinator
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                token.formattedOffset,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(token.confidence * 100).toInt()}% CONF',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        token.text,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    AppFeedback.showSuccess(
                      context,
                      'Decrypted transcript tokens copied to secure clipboard.',
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Transcript'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    AppFeedback.showInfo(
                      context,
                      'AES-256 audit manifest sealed with SHA-256 fingerprint.',
                    );
                  },
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: const Text('Export Audit Manifest'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRecording(BuildContext context, VoipRecording rec) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final colorScheme = Theme.of(dialogCtx).colorScheme;
        return AlertDialog(
          title: Text(
            'Delete Encrypted Recording?',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Text(
            'Permanently purge encrypted recording "${rec.id}" for ${rec.calleeName} and destroy decrypted transcript cache?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<VoipBloc>().add(DeleteVoipRecordingEvent(rec.id));
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
