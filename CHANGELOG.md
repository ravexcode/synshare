# Changelog

## [0.4.1]

### Fixes
- Android fix: mDNS service registration issue.

## [0.4.0]

### Added
- Device pairing over TCP: tap a device, HELLO handshake validates the peer, card flips to connected.
- Send screen: back header with device name, device platform icon, "Select files" button, sortable file list, sticky send button.
- File sorting: latest, oldest, A-Z, Z-A, char-num, num-char.
- File selection via `file_picker`; native dialogs on desktop, system picker on mobile.
- Streaming file transfer over LAN (`SYNSHARE/1 SEND` protocol); no whole-file reads into memory.
- Incoming transfer dialog with accept/reject, then progress + save to downloads (desktop) or app documents (mobile).
- Loopback pairing + transfer test (`test/transfer_service_test.dart`).

### Changed
- Devices screen: tapping a device now pairs and opens the send screen; handles inbound transfers.
- `TransferService` is injectable and supports custom port for tests.

### Technical
- Added `file_picker ^11.0.3` and `path_provider ^2.1.6`.

## [0.3.0]

### Added
- Real LAN device discovery over WiFi using mDNS (`bonsoir` package).
- `DeviceDiscoveryService` (`ChangeNotifier`): advertises this device as `_synshare._tcp` and browses for peers.
- Network constants: service type and reserved transfer port (`lib/constraints/network.dart`).
- UI states for discovery: idle, searching, found, error.
- Refresh action restarts discovery and clears the device list.
- Platform config for mDNS: Android permissions, iOS/macOS local-network usage description, Bonjour services, macOS network entitlements.

### Changed
- Devices screen now reads live discovery state instead of example data.
- `SynshareApp` owns the discovery service lifecycle and accepts an injectable service for tests.

### Technical
- Added `bonsoir ^7.1.4` dependency.
- Linux requires the Avahi daemon for mDNS.

## [0.2.0]

### Added
- Devices screen with header and reload button.
- Reusable `DeviceCard` and `DeviceIcon` components.
- `Device` model with platform and connection enums.
- `AppColors` Color tokens built from the existing hex scheme.
- App shell with dark Synshare theme.
- Example-only device data (no discovery logic yet).

### Changed
- Replaced default Flutter counter scaffold.
- Rewrote widget test to cover devices screen rendering.

### Fixed
- Invalid `mainAxisAlignment` syntax in old scaffold.

## [0.1.0]

### Added
- Initial Synshare Flutter application.
- Color scheme constants.
- OpenCode master agent specification.
