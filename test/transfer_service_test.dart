import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:synshare/models/device.dart';
import 'package:synshare/models/transfer_file.dart';
import 'package:synshare/services/transfer/transfer_service.dart';

void main() {
  test(
    'pairing + file transfer loopback',
    () async {
      final dir = await Directory.systemTemp.createTemp('synshare_test');
      final source = File('${dir.path}/hello.txt');
      await source.writeAsString('hello synshare');
      const content = 'hello synshare';

      final receiver = TransferService(deviceName: 'Receiver', port: 58411);
      final sender = TransferService(deviceName: 'Sender', port: 58412);
      await receiver.start();
      await sender.start();

      final incomingCompleter = Completer<IncomingTransfer?>();
      void onIncoming() {
        if (!incomingCompleter.isCompleted) {
          incomingCompleter.complete(receiver.incoming.value);
        }
      }

      receiver.incoming.addListener(onIncoming);

      final device = Device(
        id: 'receiver',
        name: 'Receiver',
        platform: DevicePlatform.linux,
        address: '127.0.0.1',
        port: 58411,
        connected: false,
        connectionType: ConnectionType.lan,
      );

      // Pairing handshake.
      await sender.connect(device);

      // Transfer.
      await sender.sendFiles(
        device: device,
        files: [
          OutgoingFile(
            name: 'hello.txt',
            size: content.length,
            path: source.path,
            modified: DateTime.now(),
          ),
        ],
      );

      final incoming = await incomingCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      receiver.incoming.removeListener(onIncoming);
      expect(incoming, isNotNull);
      expect(incoming!.fileName, 'hello.txt');
      expect(incoming.size, content.length);

      final savedPath = await receiver.saveIncoming(incoming, directory: dir);
      expect(await File(savedPath).readAsString(), content);

      await sender.stop();
      await receiver.stop();
      await dir.delete(recursive: true);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
