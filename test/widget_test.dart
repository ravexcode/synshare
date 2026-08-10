import 'package:flutter_test/flutter_test.dart';

import 'package:synshare/app/app.dart';
import 'package:synshare/components/device_card.dart';
import 'package:synshare/screens/devices/devices_screen.dart';

void main() {
  testWidgets('Devices screen renders header and cards', (tester) async {
    await tester.pumpWidget(const SynshareApp());

    expect(find.text('Devices'), findsOneWidget);
    expect(find.byType(DeviceCard), findsNWidgets(3));
    expect(find.byType(DevicesScreen), findsOneWidget);
  });
}
