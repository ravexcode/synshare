import 'package:flutter_test/flutter_test.dart';

import 'package:synshare/app/app.dart';
import 'package:synshare/models/device.dart';
import 'package:synshare/screens/devices/devices_screen.dart';
import 'package:synshare/services/discovery/discovery_service.dart';

const _fakeDevice = Device(
  id: 'test-1',
  name: 'Moto de Rafael',
  platform: DevicePlatform.android,
  connected: false,
  connectionType: ConnectionType.lan,
);

void main() {
  testWidgets('Devices screen renders header', (tester) async {
    await tester.pumpWidget(const SynshareApp());
    await tester.pump();

    expect(find.text('Devices'), findsOneWidget);
    expect(find.byType(DevicesScreen), findsOneWidget);
    // No mDNS plugin in the test environment: start() fails and the
    // screen falls back to the error state without crashing.
  });

  testWidgets('Devices screen shows discovered devices', (tester) async {
    final service = DeviceDiscoveryService();
    await tester.pumpWidget(SynshareApp(discoveryService: service));
    await tester.pump();

    service.debugSetDevices(const [_fakeDevice]);
    await tester.pump();

    expect(find.text('Moto de Rafael'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
  });
}
