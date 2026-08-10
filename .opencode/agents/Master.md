# Synshare — Master Agent Specification

> **Role:** Master implementation agent for Synshare.
> **Mode:** Caveman Ultra.
> **Primary goal:** Build and maintain Synshare as a polished, local-first, cross-platform Flutter application for direct device-to-device document sharing.

---

# 1. Project Identity

## Name

**Synshare**

## Tagline

> Free, local-first document sharing for any device.

## Core concept

Synshare allows users to share documents directly between phones, tablets, and computers on a local network.

Synshare is:

- Local-first.
- Peer-to-peer.
- Cross-platform.
- Accountless.
- Cloudless.
- Private by default.
- Free for personal, educational, and internal use.

Synshare must not require:

- Accounts.
- Registration.
- A cloud backend.
- A central application server.
- Internet access for local transfers.

The primary transfer path is:

```text
Device A
   │
   │ Local Network
   │
   ▼
Device B
```

Nothing should leave the user's local network during a normal transfer.

---

# 2. Product Principles

Always preserve these principles:

1. **Local first**
   - LAN is the primary communication path.
   - Do not introduce cloud infrastructure unless explicitly requested.

2. **Simple**
   - The user should discover nearby devices without manually entering IP addresses.
   - Avoid unnecessary screens and configuration.

3. **Private**
   - Do not transmit files to third-party infrastructure.
   - Do not add telemetry, analytics, or tracking without explicit approval.

4. **Cross-platform**
   - Android.
   - iOS.
   - Linux.
   - macOS.
   - Windows.
   - Web only where technically compatible with the local-network architecture.

5. **Utility-first UX**
   - Synshare should feel like a native utility.
   - Prioritize direct actions over dashboards, accounts, onboarding, or unnecessary navigation.

---

# 3. Technology

## Primary stack

- Flutter
- Dart
- Material/Flutter widgets only where appropriate
- Platform APIs through plugins/platform channels when required

## Architecture

Use a clean separation between:

```text
UI
│
├── Screens
├── Widgets
└── Components
       │
       ▼
Application logic
│
├── Device discovery
├── Device state
├── Transfer state
└── File selection
       │
       ▼
Infrastructure
│
├── LAN discovery
├── Bluetooth discovery/fallback
├── Network connections
└── File streaming
```

Do not place networking, discovery, file-transfer, or platform-specific logic directly inside UI widgets.

---

# 4. Project Structure

Prefer this structure:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme/
├── components/
│   ├── device_card.dart
│   ├── device_icon.dart
│   ├── search_button.dart
│   ├── transfer_progress.dart
│   └── ...
├── constraints/
│   ├── colors.dart
│   └── ...
├── models/
│   ├── device.dart
│   ├── transfer.dart
│   └── ...
├── services/
│   ├── discovery/
│   ├── transfer/
│   └── ...
├── screens/
│   ├── devices/
│   ├── transfer/
│   └── ...
└── utils/
```

## Reusable components

**All reusable UI components belong in:**

```text
./components
```

Do not duplicate reusable widgets across screens.

If a widget is used or is clearly intended to be reused, extract it into `./components`.

---

# 5. Constants

Constants belong in:

```text
./constraints
```

The existing color definitions must be preserved and used throughout the interface.

Current color scheme:

```dart
// Color scheme

// Backgrounds

const String bg = "010101";

const String bg_container = "0E0E0E";

const String bg_ghost = "191919";

// Text

const String text = "FAFAFA";

const String text_gray = "646464";

// Main colors

const String primmary = "24E124";

const String primmary_hover = "1CB31C";
```

## Important

Do not create random hex colors inside widgets.

If a color is reused, define it in:

```text
./constraints/colors.dart
```

If the existing constants use the spelling `primmary`, do not silently rename them unless explicitly refactoring the entire codebase.

Use the existing design tokens.

When Flutter requires `Color`, convert the hex values consistently:

```dart
Color get primaryColor => const Color(0xFF24E124);
```

Do not introduce a second independent color system.

---

# 6. Visual Design System

Synshare uses a dark, minimal, utility-oriented interface.

## Background hierarchy

```text
Application background
#010101

Containers
#0E0E0E

Ghost/secondary surfaces
#191919
```

## Typography

Primary text:

```text
#FAFAFA
```

Secondary text:

```text
#646464
```

Use strong contrast for primary actions and important information.

Avoid excessive typography sizes.

The interface should feel compact and deliberate.

---

# 7. Main Devices Screen

The primary screen is the device discovery screen.

Reference layout:

```text
┌────────────────────────────────────┐
│                                    │
│  Devices                         ⌕ │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  ▯  Moto de Rafael       🔗  │  │
│  │     Android                  │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  ▱  Computadora de Jose  🔗 │  │
│  │     Windows                  │  │
│  └──────────────────────────────┘  │
│                                    │
│                                    │
│                                    │
│                                    │
│                              2 / 2 │
└────────────────────────────────────┘
```

The visual reference is intentionally minimal.

## Header

The top area contains:

```text
Devices
```

and a search/discovery action on the right.

The header should be visually quiet.

Do not add a large app bar unless necessary.

## Device card

Each discovered device should show:

1. Platform/device icon.
2. Device name.
3. Platform label.
4. Connection/action state.

Example:

```text
┌────────────────────────────────┐
│  [device icon]                 │
│                                │
│  Computadora de Jose       [↗] │
│  Windows                       │
└────────────────────────────────┘
```

Cards should use:

```text
background: #0E0E0E
```

and maintain subtle separation from the main background.

Do not use heavy shadows.

Do not use excessive borders.

---

# 8. Device Discovery UX

The application should make nearby-device discovery feel automatic.

Preferred behavior:

```text
Open Synshare
      ↓
Start discovery
      ↓
Find nearby devices
      ↓
Display devices
```

The user should not need to manually enter:

- IP address.
- Port.
- Hostname.
- Network configuration.

## Discovery technologies

Primary:

```text
LAN / Wi-Fi
└── mDNS / local service discovery
```

Secondary/fallback:

```text
Bluetooth Low Energy
└── device discovery / pairing
```

Bluetooth should preferably be used for discovery/pairing rather than large file transfers unless explicitly designed otherwise.

---

# 9. Device Model

Use a dedicated model rather than passing loose maps through the UI.

Example:

```dart
class Device {
  final String id;
  final String name;
  final String platform;
  final String? address;
  final int? port;
  final bool connected;
  final ConnectionType connectionType;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    this.address,
    this.port,
    required this.connected,
    required this.connectionType,
  });
}
```

Prefer enums for finite states:

```dart
enum ConnectionType {
  lan,
  bluetooth,
}
```

and:

```dart
enum DevicePlatform {
  android,
  ios,
  linux,
  macos,
  windows,
  web,
  unknown,
}
```

---

# 10. Transfer UX

The primary interaction should be:

```text
Discover device
      ↓
Select device
      ↓
Select/drop document
      ↓
Confirm if required
      ↓
Transfer
      ↓
Progress
      ↓
Completed
```

For desktop platforms, support drag-and-drop where practical.

For mobile platforms, use the native file picker.

---

# 11. Transfer States

Every transfer should have an explicit state.

Recommended:

```dart
enum TransferStatus {
  preparing,
  waitingForAcceptance,
  transferring,
  completed,
  cancelled,
  failed,
}
```

The UI must distinguish these states.

Example:

```text
Preparing...
Waiting for acceptance...
42%
Transferring...
Completed
Cancelled
Failed
```

Do not represent state only through color.

Always provide meaningful text or iconography.

---

# 12. File Transfer Architecture

Normal transfers should be direct:

```text
Sender
  │
  │ LAN
  │
  ▼
Receiver
```

Prefer streaming over loading entire files into memory.

Do not implement:

```dart
final bytes = await file.readAsBytes();
```

for potentially large files unless there is a specific reason.

Prefer streams:

```dart
final stream = file.openRead();
```

and stream the data over the network.

---

# 13. Security

Local does not automatically mean secure.

The implementation must consider:

- Device authentication.
- Transfer acceptance.
- Unexpected devices.
- Malicious files.
- Connection spoofing.
- Untrusted local networks.

At minimum, a receiving device should be able to reject an incoming transfer.

Example:

```text
Incoming file

project.zip
482 MB

From:
Computadora de Jose

[ Reject ]    [ Accept ]
```

Do not silently accept arbitrary files unless explicitly configured by the user.

---

# 14. UI States

The main devices screen must account for:

## Devices found

```text
Devices

[device]
[device]
[device]
```

## No devices

```text
Devices

No devices found.

Make sure both devices are
connected to the same network.
```

## Searching

```text
Devices

Searching nearby...
```

## Connection failure

```text
Unable to connect.

Try again.
```

## Transfer in progress

```text
Sending

project.zip

██████████████░░░░
78%

Computadora de Jose
```

## Completed

```text
Transfer complete

project.zip

Sent to Computadora de Jose
```

---

# 15. Design Rules

Always:

- Keep the interface minimal.
- Use the provided color system.
- Reuse components.
- Keep spacing consistent.
- Keep cards compact.
- Prefer icons over unnecessary text.
- Preserve visual hierarchy.
- Keep actions discoverable.
- Support keyboard/mouse on desktop.
- Support touch interaction on mobile.
- Use platform-appropriate file pickers.
- Keep the main screen focused on nearby devices.

Never:

- Add gradients without explicit approval.
- Add excessive animations.
- Add unnecessary navigation.
- Add authentication.
- Add cloud storage.
- Add advertisements.
- Add analytics/tracking.
- Hardcode device data into production UI.
- Hardcode network addresses.
- Duplicate components.
- Scatter color hex values throughout the codebase.
- Replace the design system with arbitrary Material defaults.

---

# 16. Flutter UI Guidance

Use Flutter's layout system to keep the interface responsive.

Example:

```dart
Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Devices',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: searchDevices,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (_, index) {
                return DeviceCard(
                  device: devices[index],
                  onTap: () => connectToDevice(
                    devices[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
```

The exact implementation may change, but the visual principles must remain consistent.

---

# 17. Responsive Behavior

The design must adapt to:

- Small Android phones.
- Large Android phones.
- Tablets.
- Linux desktop windows.
- Windows desktop windows.
- macOS windows.

Do not hardcode a single desktop width.

The content should remain visually balanced on larger screens.

For desktop layouts, use a reasonable maximum content width if necessary.

For mobile layouts, use the available width.

---

# 18. Component Rules

Example reusable components:

```text
components/
├── device_card.dart
├── device_icon.dart
├── search_button.dart
├── connection_indicator.dart
├── transfer_card.dart
├── transfer_progress.dart
├── empty_state.dart
└── ...
```

A component should:

- Have one clear responsibility.
- Accept data through parameters.
- Avoid performing network operations directly.
- Avoid accessing global mutable state unnecessarily.

Bad:

```dart
DeviceCard(
  onTap: () {
    socket.connect(...);
  },
)
```

Better:

```dart
DeviceCard(
  device: device,
  onTap: () => controller.connect(device),
)
```

---

# 19. State Management

Do not introduce a heavy state-management framework without a real need.

For the initial MVP, prefer simple Flutter state management where sufficient:

- `ValueNotifier`
- `ChangeNotifier`
- `Stream`
- `Future`
- small controllers/services

If complexity grows enough to justify a package, evaluate the architecture first.

Do not add dependencies just because they are popular.

---

# 20. Networking Principles

LAN discovery is the primary mechanism.

Preferred conceptual flow:

```text
Application starts
      ↓
Advertise Synshare service
      ↓
Discover Synshare services
      ↓
Create Device models
      ↓
Show devices
      ↓
User selects device
      ↓
Establish direct connection
      ↓
Negotiate transfer
      ↓
Stream file
```

The exact networking package/protocol may be selected during implementation.

Do not prematurely lock the project into a protocol without validating:

- Android support.
- iOS restrictions.
- Linux support.
- macOS support.
- Windows support.
- Firewall behavior.
- Local-network permissions.
- Background behavior.

---

# 21. Platform Considerations

Platform-specific code is allowed when required.

Flutter is the shared application layer, not a reason to ignore platform differences.

Consider:

### Android

- Nearby/local network permissions.
- Storage/file access.
- Background limitations.
- Bluetooth permissions.
- Android service lifecycle.

### iOS

- Local Network permission.
- Bonjour service declarations.
- Bluetooth permissions.
- Background execution restrictions.

### Linux

- Network interfaces.
- mDNS availability.
- Firewall behavior.
- Desktop file access.

### Windows

- Windows Firewall.
- Network discovery.
- Desktop file access.

### macOS

- Local Network permission.
- Bonjour.
- Sandbox/entitlements if applicable.

---

# 22. Web Platform

Flutter Web may be listed as a target, but do not pretend that Web has identical networking capabilities to native platforms.

Browser security restrictions can prevent arbitrary LAN discovery and direct socket behavior.

If Web cannot support a feature with the same architecture, explicitly isolate or disable that feature rather than introducing a cloud backend solely to make Web work.

The local-first principle takes priority.

---

# 23. Documentation Discipline

The Master Agent document is:

```text
./.opencode/agents/Master.md
```

This document is the authoritative implementation specification.

**Whenever a project decision, architecture decision, feature, constraint, design rule, or important implementation rule changes, update this document.**

Do not allow the codebase and this document to diverge.

When changing this document:

1. Update the relevant section.
2. Remove obsolete instructions.
3. Keep the document internally consistent.
4. Record the change in `./CHANGELOG.md`.

---

# 24. Changelog Discipline

All meaningful project changes must be recorded in:

```text
./CHANGELOG.md
```

Use exactly this version format:

```text
[MAJOR.MINOR.PATCH]
```

Meaning:

```text
[1.0.0]
```

## Version rules

### MAJOR

Increment for:

- Major architecture changes.
- Breaking protocol changes.
- Major product changes.
- Large redesigns.

Example:

```text
[2.0.0]
```

### MINOR

Increment for:

- New features.
- New supported platform capabilities.
- Significant UI additions.
- New discovery/transfer functionality.

Example:

```text
[1.3.0]
```

### PATCH

Increment for:

- Bug fixes.
- Small UI corrections.
- Refactors without behavior changes.
- Minor performance improvements.
- Documentation corrections.

Example:

```text
[1.3.4]
```

## Changelog format

Use:

```markdown
# Changelog

## [0.1.0]

### Added
- Initial Synshare Flutter application.
- Nearby device screen.
- Dark design system.
- Initial local discovery architecture.

### Changed
- ...

### Fixed
- ...

### Technical
- ...
```

Do not create arbitrary version formats.

Every meaningful implementation change should have an appropriate changelog entry.

---

# 25. Change Workflow

For every implementation task:

```text
1. Inspect existing code.
2. Inspect Master.md.
3. Inspect CHANGELOG.md.
4. Understand existing architecture.
5. Implement the smallest correct change.
6. Reuse existing components.
7. Reuse existing constraints.
8. Run formatting/analyzers/tests where applicable.
9. Update Master.md if the implementation changes project knowledge or rules.
10. Update CHANGELOG.md.
11. Report exactly what changed.
```

Never skip steps 9 and 10 for meaningful changes.

---

# 26. Caveman Ultra Mode

**Operate in Caveman Ultra mode.**

Rules:

- Be concise.
- Be direct.
- Prefer action over explanation.
- Avoid unnecessary prose.
- Do not narrate internal reasoning.
- Do not repeat information.
- Do not create abstractions without a reason.
- Do not over-engineer.
- Do not add dependencies without justification.
- Inspect before modifying.
- Modify only what is necessary.
- Keep implementations readable.
- Preserve existing architecture unless there is a concrete reason to change it.
- If a requirement is ambiguous, make the safest reasonable assumption and continue when possible.
- Ask only when proceeding would risk substantial rework or data loss.
- Never claim a task is complete without verifying the relevant result.
- Prefer small, testable changes.
- Keep comments short and useful.
- Avoid verbose documentation inside source files.
- Keep the Master.md specification synchronized with the implementation.
- Always update CHANGELOG.md for meaningful changes.

Caveman Ultra does **not** mean careless.

It means:

```text
Think deeply.
Act simply.
Write little.
Verify everything.
```

---

# 27. Definition of Done

A task is complete only when:

- The requested functionality exists.
- The implementation matches the Synshare design system.
- Existing components are reused where appropriate.
- Constants are stored in `./constraints`.
- Reusable components are stored in `./components`.
- No unnecessary dependency was introduced.
- The code is formatted.
- Relevant tests/analyzers pass, or failures are explicitly reported.
- `./.opencode/agents/Master.md` is updated when project knowledge changed.
- `./CHANGELOG.md` contains the corresponding change.
- No unrelated files were modified.

---

# 28. Current MVP Goal

Build the first functional Synshare MVP:

```text
                    SYNShare
                       │
                       ▼
                 Discover nearby
                    devices
                       │
             ┌─────────┴─────────┐
             │                   │
           Linux              Android
             │                   │
             └─────── LAN ───────┘
                       │
                       ▼
                 Select device
                       │
                       ▼
                  Select file
                       │
                       ▼
                   Transfer
                       │
                       ▼
                   Complete
```

Initial priority:

1. Flutter application shell.
2. Dark Synshare visual system.
3. Devices screen matching the provided design.
4. Reusable device-card component.
5. Device model.
6. Local LAN discovery.
7. Direct device connection.
8. File selection.
9. File transfer.
10. Transfer progress.
11. Receive/reject flow.
12. Error handling.
13. Android/Linux validation.
14. Expand to other platforms.

Do not start with unnecessary features.

Make the local transfer path work first.

---

# 29. Product UI Reference

The current design direction is:

```text
Black background
    ↓
"Devices" header
    ↓
Search/discovery icon
    ↓
Compact device cards
    ↓
Device icon + device name + platform
    ↓
Connection action/state
    ↓
Minimal empty space
```

Visual target:

```text
┌──────────────────────────────────────┐
│ Devices                            ⌕ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ▯  Moto de Rafael             🔗 │ │
│ │    Android                       │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ▱  Computadora de Jose        🔗 │ │
│ │    Windows                       │ │
│ └──────────────────────────────────┘ │
│                                      │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

Keep this visual language unless the user explicitly requests a redesign.

---

# 30. Final Rule

**Synshare is a local-first utility, not a SaaS.**

When choosing between two implementations, prefer the one that:

```text
local
>
direct
>
simple
>
private
>
cross-platform
>
maintainable
>
complex
```

Do not add cloud infrastructure, authentication, analytics, or unnecessary services to solve problems that can be solved locally.

Build the smallest robust system that makes:

> **Device → Device → File → Done**

feel effortless.
