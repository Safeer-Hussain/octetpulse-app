# Product Requirements Document (PRD): OctetPulse

## 1. Executive Summary
**OctetPulse** is an enterprise-grade mobile platform architected in Flutter for workforce operations management, automated payroll ledger calculation, real-time field workforce GPS tracking, geofenced shift attendance, and encrypted native VoIP/WebRTC communications.

- **GitHub Repository**: [Safeer-Hussain/octet-pulse](https://github.com/Safeer-Hussain/octet-pulse)
- **Architect & Lead Developer**: Safeer Hussain
- **Target OS**: Android (API 21-36), iOS (15+)
- **Primary Framework**: Flutter 3.47 / Dart 3.13
- **Architecture**: Clean Architecture (Feature-First) + MVVM / BLoC Pattern

---

## 2. Core Pillars & Architecture Overview

### 2.1 Feature-First Clean Architecture
```
lib/
├── core/               # Global singletons, constants, theme, DI, utils, feedback
├── data/               # SQLite database, native platform bridges, repository implementations
├── domain/             # Entities, repository contracts, business rules
└── presentation/       # Feature modules: BLoC/Cubit, UI views, sheets, widgets
```

### 2.2 Offline-First Zero-Cost Infrastructure
- No external paid APIs, Firebase projects, or cloud subscriptions required.
- Robust on-device SQLite database (`AppDatabase`) maintaining persistent records for employees, shifts, payroll batches, dispatch tasks, and encrypted VoIP call logs.
- Custom `Dio` Mock Network Interceptor providing configurable simulated network latency (400ms-850ms) and HTTP 503 error injection.

### 2.3 Native VoIP & Telemetry Audio Bridge
- Native platform channels:
  - Android: `MainActivity.kt` with `MethodChannel("com.safeer.octetpulse/voip_control")` and `EventChannel("com.safeer.octetpulse/voip_telemetry")`.
  - iOS: `AppDelegate.swift` with matching MethodChannel and EventChannel.
- Encrypted SRTP-AES256 audio sessions, live acoustic waveform analysis, MOS score calculation, jitter, and packet loss telemetry streamed every 1.5 seconds.

---

## 3. Detailed Module Specifications

### Module 1: Geofenced Attendance, Shift Roster & Clock-In Hub
- High-precision distance calculation from Arfa Software Technology Park (ASTP) HQ coordinates (`31.4754, 74.3436`) with 150-meter verified geofence boundary.
- 1-tap Clock-In, Clock-Out, and Break toggles with live shift duration timer.
- Team Lead Approval Queue for leave and overtime requests with first-tap approval mutation.
- Weekly Workforce Attendance & Operational Efficiency trendline (`fl_chart`).

### Module 2: Automated Payroll Engine & Payslip Generator
- 25+ seeded enterprise personnel spanning Mobile Engineering, Field Operations, Cloud Infrastructure, and Security & Compliance.
- Gross-to-net salary calculator with 1.5x overtime multiplier, sprint bonus, 15% income tax withholding, and 5% provident fund.
- Dual-currency display toggle (USD and PKR at 1:278.50 rate).
- Digital payslip modal breakdown with formatted summary copy to clipboard and SQLite disbursement status tracking.

### Module 3: Real-Time Field Workforce GPS Tracker (`flutter_map`)
- Zero-cost OpenStreetMap integration tracking field engineers across Lahore tech corridors (Gulberg, Ring Road, Johar Town, DHA Phase 5).
- Live fleet movement simulator with route polylines, speed, battery level, and client site ETA.
- Agent detail card with 1-tap VoIP call launch and task dispatch modal.

### Module 4: Encrypted Enterprise VoIP Dialer & Call Cockpit
- Organization directory with live presence indicators (Available, In Call, Field Dispatch).
- Call cockpit with dynamic acoustic waveforms, live SRTP-AES256 cipher badge, MOS score, Mute, Speakerphone, Hold, and DTMF dialpad buffer.
- Persistent call history log in SQLite.

### Module 5: On-Device AI Workforce Operations Copilot
- Real-time audit assistant reading live SQLite workforce metrics.
- Token-by-token streaming response with `try ... finally` protection ensuring `isStreaming: false` termination.
- Executive prompt chips for payroll variance, dispatch bottlenecks, and shift optimization.

---

## 4. UI/UX & Non-Functional Specifications
- **Zero Hardcoded Colors**: 100% adherence to `Theme.of(context).colorScheme` across Dark Slate and Executive Light modes.
- **Landscape Safety**: Micro-toolbar height (36dp), compact NavigationRail without labels, and two-pane independent scroll containers ensuring zero overflow on 360dp height screens.
- **No Emojis**: Strictly vector Material Symbols and Icons across all code and UI.
- **Hero Tags**: Explicit, unique strings on all Floating Action Buttons.
