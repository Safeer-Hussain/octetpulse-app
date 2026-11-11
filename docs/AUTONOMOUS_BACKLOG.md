# OctetPulse Autonomous Engineering Backlog

This backlog defines the 25 granular daily engineering sprints for OctetPulse. Each sprint is self-contained, follows Clean Architecture, enforces zero hardcoded colors, ensures 360dp-height landscape safety, includes automated unit/widget tests, and passes live physical device verification via `tool/sprint_gate.dart`.

---

## Sprint Roadmap

- [x] **Sprint 1: Multi-Bracket Tax & EOBI Pension Calculation Engine**
  - Implement Pakistan Federal Board of Revenue (FBR) 2026-2027 progressive tax slabs alongside USD multi-jurisdictional withholding rules.
  - Implement Employee Old-Age Benefits Institution (EOBI) contribution calculators in `PayrollRepository`.
  - Add tax breakdown charts and payslip deduction itemization in `payslip_breakdown_sheet.dart`.
  - Unit tests for all tax brackets and exemption ceilings.

- [ ] **Sprint 2: Geofence Arbitrary Polygon Boundary Editor**
  - Upgrade circular 150m radius geofencing to arbitrary polygon geofencing using Ray-Casting Point-in-Polygon (PIP) algorithms.
  - Add interactive polygon boundary editor in `FieldTrackerView` allowing corporate admins to draw campus boundaries.
  - Persist polygon vertices in SQLite `geofence_zones` table.
  - Unit and widget tests for vertex point containment.

- [ ] **Sprint 3: Native VoIP Audio Call Recording & Encrypted Transcript Simulator**
  - Extend Kotlin and Swift VoIP bridges with audio recording buffer toggle.
  - Store encrypted call audio manifests in SQLite `voip_recordings` table with AES-256 GCM metadata.
  - Add playback scrubber and waveform playback HUD in `VoipHubView`.
  - Unit tests for recording state transitions and playback duration.

- [ ] **Sprint 4: Peer-to-Peer Shift Swap Negotiation Engine**
  - Allow employees to propose shift swaps with team members in the same department.
  - Real-time status tracking (Proposed, Countered, Accepted, Lead Approved).
  - Push notifications simulation via BLoC stream and SQLite persistence.
  - Unit tests for swap state machine transitions.

- [ ] **Sprint 5: Optical Expense Receipt OCR Scanner & Currency Converter**
  - Add mobile camera expense capture interface with client-side OCR parser for fuel, client lunch, and transit receipts.
  - Automatic tax extraction and multi-currency conversion to USD base.
  - Integration with `PayrollBloc` for expense reimbursement line items.
  - Unit tests for regex-based OCR receipt token parsing.

- [ ] **Sprint 6: Biometric Facial Liveness & Anti-Spoofing Clock-In Check**
  - Implement front camera liveness challenge (blink, nod, smile detection) before clock-in confirmation.
  - Store cryptographic attestation hash in `attendance` SQLite ledger.
  - Fallback authentication flow when lighting is below threshold.
  - Widget tests for liveness challenge state progression.

- [ ] **Sprint 7: Offline Route Optimization & Multi-Stop Dispatch Waypoints**
  - Implement Dijkstra / Travelling Salesperson Problem (TSP) heuristic for multi-client field visits.
  - Calculate optimal travel time, fuel burn estimate, and predicted client ETA.
  - Display optimized polyline order on `flutter_map` OpenStreetMap interface.
  - Unit tests for TSP distance ordering accuracy.

- [ ] **Sprint 8: Push-to-Talk (PTT) Walkie-Talkie Channel Protocol**
  - Add dedicated half-duplex Push-to-Talk audio channel for field operations.
  - Dynamic channel switching (Gulberg Dispatch, DHA Operations, Emergency Response).
  - Low-latency visual talk-spurt indicator and queue arbitrator.
  - Unit and widget tests for PTT lock and release events.

- [ ] **Sprint 9: Dynamic Bonus Pool & Velocity Performance Multiplier**
  - Connect sprint story point velocity from engineering tracker into payroll bonus pool calculator.
  - Configurable tier multipliers: 1.0x (Met SLA), 1.25x (Exceeded SLA), 1.5x (Critical Firefighter).
  - Add team velocity leaderboard view in `PayrollLedgerView`.
  - Unit tests for bonus allocation distribution.

- [ ] **Sprint 10: Cellular Signal & Battery Drain Telemetry Tracker**
  - Stream field device cellular signal strength (dBm) and battery temperature into `VoipTelemetry`.
  - Trigger automatic low-battery alert to dispatch coordinators when below 15%.
  - Persist historical device telemetry logs in SQLite for predictive failure analysis.
  - Unit tests for threshold trigger events.

- [ ] **Sprint 11: Encrypted Organization Announcements & Read Receipts**
  - Organization-wide broadcast bulletins with mandatory read acknowledgment.
  - Priority levels (Urgent Security Alert, HR Policy, Operations Update).
  - Real-time departmental acknowledgment percentage chart.
  - Widget tests for unread badge counters and dismiss actions.

- [ ] **Sprint 12: Automated Statutory Payroll PDF Exporter & Watermarking**
  - Generate pixel-perfect corporate salary slip PDFs with company seal and digital verification QR code.
  - Save to device documents directory and trigger system share sheet.
  - Confidential watermark overlay for executive compensation protection.
  - Unit tests for PDF bytes generation and metadata integrity.

- [ ] **Sprint 13: Emergency SOS Panic Beacon & Rapid Security Dispatch**
  - Add 3-second hold emergency SOS button in field tracking view.
  - Immediately broadcasts coordinates, nearest hospital/police node, and initiates high-priority VoIP bridge to CSO.
  - Automatic silent GPS tracking frequency boost to 1-second intervals.
  - Unit and widget tests for SOS countdown and cancel mechanics.

- [ ] **Sprint 14: Dark/Light Adaptive High-Contrast Accessibility Theme**
  - Implement WCAG AAA compliant high-contrast theme option for outdoor field sunlight readability.
  - Dynamic font scaling support across all tables, charts, and dialer pads.
  - Screen-reader semantic labels across every interactive widget.
  - Widget tests verifying semantic annotations and minimum tap targets.

- [ ] **Sprint 15: Corporate Asset & Hardware Tooling Checkout Ledger**
  - Track assigned hardware tools (OTDR optical meters, laptops, field tablets, telecom test kits).
  - Barcode / QR asset scanning for field checkout and return validation.
  - Asset condition reporting and automatic damage deduction calculator.
  - Unit tests for asset check-out/in state transitions.

- [ ] **Sprint 16: Multi-Tenant Corporate Switcher & Role-Based Access Control (RBAC)**
  - Support switching between corporate subsidiaries and international entities.
  - Enforce granular RBAC permissions: Executive Admin, Team Lead, Field Specialist, Auditor.
  - Obfuscate salary data from non-authorized viewers.
  - Unit tests for RBAC permission gate evaluation.

- [ ] **Sprint 17: Field Hazard & SLA Incident Reporting Ticket Desk**
  - Incident ticket creation with image attachment simulation and geo-tagged coordinates.
  - SLA countdown timer with automatic escalation to Operations Director.
  - Resolution workflow: Open -> In Progress -> Validated -> Closed.
  - Unit tests for ticket escalation timer logic.

- [ ] **Sprint 18: Client Digital Signature & Job Completion Certificate**
  - On-site touch signature canvas for client job sign-off upon dispatch task resolution.
  - Cryptographic SHA-256 signature stamping and receipt generation.
  - Automatically transitions task status to 'Resolved' and updates agent availability.
  - Widget tests for signature capture and clear actions.

- [ ] **Sprint 19: Bluetooth Low Energy (BLE) Beacon Indoor Attendance**
  - Add BLE beacon RSSI proximity detector for multi-story office indoor attendance where GPS signal is degraded.
  - Floor-by-floor presence detection (ASTP 4th Floor Lab vs. 9th Floor Operations).
  - Smooth fallback from GPS to BLE beacon telemetry.
  - Unit tests for RSSI distance approximation filter.

- [ ] **Sprint 20: Predictive Overtime Burn & Budget Exhaustion Forecaster**
  - On-device linear regression forecasting projected monthly overtime expenditure.
  - Visual budget burn warning line on `fl_chart` attendance and payroll charts.
  - Departmental budget variance alerts sent to AI Copilot.
  - Unit tests for statistical projection formula.

- [ ] **Sprint 21: VoIP Conference Bridge & Multi-Party Room Audio**
  - Expand point-to-point native VoIP bridge to support 8-party conference rooms.
  - Active speaker detection and dynamic dominant speaker waveform highlighting.
  - Participant mute controls for room moderator.
  - Unit tests for conference state membership and mixing.

- [ ] **Sprint 22: Historical Route Replay & Fleet Speed Heatmap**
  - Add interactive time-slider scrubbing agent historical routes over the past 24 hours.
  - Color-coded speed segments on polylines (Green: <40 km/h, Orange: 40-70 km/h, Red: >70 km/h).
  - Stop detection marker highlighting vehicle idle time.
  - Widget tests for playback slider and pause/resume states.

- [ ] **Sprint 23: Automated Provident Fund & Gratuity Accrual Ledger**
  - Long-term employee retirement fund growth projection calculator.
  - Annual compounding interest calculation with voluntary employee contribution matching.
  - Visual gratuity accumulation curve over tenure years.
  - Unit tests for compounding interest math.

- [ ] **Sprint 24: Enterprise Audit Log Vault & Tamper-Evident Hash Chain**
  - Cryptographic Merkle tree / blockchain-style hash chain of all payroll and attendance ledger mutations.
  - Auditor verification tool detecting any out-of-band SQLite database modifications.
  - Exportable cryptographically verifiable compliance audit bundle.
  - Unit tests for hash chain integrity and tamper detection.

- [ ] **Sprint 25: AI Workforce SLA & Capacity Optimization Simulator**
  - Monte Carlo simulation engine inside AI Copilot predicting field response times under severe weather/traffic spikes.
  - Prescriptive recommendations for re-allocating engineers across Lahore zones.
  - 1-tap automated dispatch rebalancing plan.
  - Unit tests for Monte Carlo simulation convergence and deterministic seeding.
