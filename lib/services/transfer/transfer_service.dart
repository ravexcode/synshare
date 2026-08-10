import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../constraints/network.dart';
import '../../models/device.dart';
import '../../models/transfer_file.dart';
import 'socket_reader.dart';

/// An inbound file transfer waiting for the user's decision.
class IncomingTransfer {
  final String fileName;
  final int size;
  final Socket socket;
  final SocketReader reader;
  final Completer<bool> _decision = Completer<bool>();

  IncomingTransfer({
    required this.fileName,
    required this.size,
    required this.socket,
    required this.reader,
  });

  /// Remaining file bytes.
  Stream<List<int>> get stream => reader.raw();

  /// Completes true when accepted, false when rejected.
  Future<bool> get decision => _decision.future;

  void accept() {
    if (!_decision.isCompleted) _decision.complete(true);
  }

  void reject() {
    if (!_decision.isCompleted) _decision.complete(false);
    socket.destroy();
  }
}

/// Owns the TCP transfer server, device pairing, and file sending.
///
/// Wire protocol (newline-delimited text header, then raw bytes):
///
/// Pairing:        `SYNSHARE/1 HELLO <myName>` -> `SYNSHARE/1 HELLO-ACK`
/// Sending:        `SYNSHARE/1 SEND\n<fileName>\n<size>\n<file bytes>`
class TransferService extends ChangeNotifier {
  final String _deviceName;
  final int port;

  ServerSocket? _server;
  final Map<String, Socket> _paired = {};
  final ValueNotifier<IncomingTransfer?> _incoming =
      ValueNotifier<IncomingTransfer?>(null);

  /// Last server bind failure, if any.
  String? serverError;

  TransferService({
    required this._deviceName,
    this.port = NetworkConfig.transferPort,
  });

  ValueNotifier<IncomingTransfer?> get incoming => _incoming;

  /// Binds the transfer server and starts accepting connections.
  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      unawaited(_acceptLoop(_server!));
    } catch (e) {
      serverError = 'Transfer server unavailable: $e';
    }
  }

  Future<void> _acceptLoop(ServerSocket server) async {
    await for (final socket in server) {
      unawaited(_handleIncoming(socket));
    }
  }

  Future<void> _handleIncoming(Socket socket) async {
    final reader = SocketReader(socket);
    try {
      final header = await reader.readLine();
      if (header == null) {
        socket.destroy();
        return;
      }
      final parts = header.split(' ');
      if (parts.isEmpty || parts.first != NetworkConfig.protocol) {
        socket.destroy();
        return;
      }
      final verb = parts.length > 1 ? parts[1] : '';
      switch (verb) {
        case 'HELLO':
          socket.add(utf8.encode('${NetworkConfig.protocol} HELLO-ACK\n'));
          await socket.flush();
          await socket.close();
        case 'SEND':
          final fileName = await reader.readLine();
          final sizeStr = await reader.readLine();
          final size = int.tryParse(sizeStr ?? '');
          if (fileName == null || size == null || size < 0) {
            socket.destroy();
            return;
          }
          if (_incoming.value != null) {
            socket.destroy(); // One inbound transfer at a time (MVP).
            return;
          }
          final transfer = IncomingTransfer(
            fileName: fileName,
            size: size,
            socket: socket,
            reader: reader,
          );
          _incoming.value = transfer;
          // Save/reject is driven by the UI through [accept]/[reject].
          return;
        default:
          socket.destroy();
      }
    } catch (_) {
      socket.destroy();
    }
  }

  /// Pairs with a device: opens a TCP connection and validates the peer
  /// with a HELLO handshake. Keeps the socket open as the paired link.
  Future<void> connect(Device device) async {
    if (_paired.containsKey(device.id)) return;
    final address = device.address;
    if (address == null) {
      throw SocketException('No address for ${device.name}');
    }
    final port = device.port ?? NetworkConfig.transferPort;
    final socket = await Socket.connect(
      address,
      port,
      timeout: NetworkConfig.connectTimeout,
    );
    final reader = SocketReader(socket);
    try {
      socket.add(
        utf8.encode(
          '${NetworkConfig.protocol} HELLO ${_escape(_deviceName)}\n',
        ),
      );
      await socket.flush();
      final ack = await reader.readLine().timeout(NetworkConfig.connectTimeout);
      if (ack == null || !ack.startsWith(NetworkConfig.protocol)) {
        throw SocketException('Pairing rejected by ${device.name}');
      }
    } catch (e) {
      socket.destroy();
      rethrow;
    }
    _paired[device.id] = socket;
  }

  /// Streams each file to the device over a fresh TCP connection.
  Future<void> sendFiles({
    required Device device,
    required List<OutgoingFile> files,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (files.isEmpty) return;
    final address = device.address;
    if (address == null) {
      throw SocketException('No address for ${device.name}');
    }
    final port = device.port ?? NetworkConfig.transferPort;
    var sent = 0;
    final total = files.fold<int>(0, (sum, f) => sum + f.size);
    for (final file in files) {
      final socket = await Socket.connect(
        address,
        port,
        timeout: NetworkConfig.connectTimeout,
      );
      try {
        final header =
            '${NetworkConfig.protocol} SEND\n${_escape(file.name)}\n${file.size}\n';
        socket.add(utf8.encode(header));
        await socket.flush();
        final counting = File(file.path).openRead().transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, sink) {
              sent += chunk.length;
              sink.add(chunk);
              onProgress?.call(sent, total);
            },
          ),
        );
        await socket.addStream(counting);
      } catch (e) {
        socket.destroy();
        rethrow;
      }
      await socket.flush();
      await socket.close();
    }
  }

  /// Rejects a pending inbound transfer.
  void rejectIncoming(IncomingTransfer incoming) {
    incoming.reject();
    if (identical(_incoming.value, incoming)) _incoming.value = null;
  }

  /// Saves an accepted inbound transfer to disk. Returns the saved path.
  Future<String> saveIncoming(
    IncomingTransfer incoming, {
    Directory? directory,
  }) async {
    incoming.accept();
    final dir = directory ?? await _saveDirectory();
    final file = File('${dir.path}/${_sanitizeName(incoming.fileName)}');
    final sink = file.openWrite();
    await sink.addStream(incoming.stream);
    await sink.close();
    await incoming.socket.close();
    if (identical(_incoming.value, incoming)) _incoming.value = null;
    return file.path;
  }

  Future<Directory> _saveDirectory() async {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  static String _escape(String value) =>
      value.replaceAll('\n', ' ').replaceAll('\r', ' ');

  static String _sanitizeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'received_file' : cleaned;
  }

  /// Stops the server and closes all connections.
  Future<void> stop() async {
    for (final socket in _paired.values) {
      socket.destroy();
    }
    _paired.clear();
    if (_incoming.value != null) {
      _incoming.value!.reject();
      _incoming.value = null;
    }
    await _server?.close();
    _server = null;
  }
}
