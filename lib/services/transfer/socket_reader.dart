import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Buffered reader over a [Socket].
///
/// Reads newline-delimited text lines for the handshake/header phase, then
/// hands over the remaining bytes as a raw stream once the header is done.
/// Needed because a raw `socket.listen` would treat file bytes as more
/// lines and cannot push back leftovers.
class SocketReader {
  final Socket socket;

  final List<Uint8List> _chunks = [];
  int _head = 0;
  bool _closed = false;
  Completer<void>? _onData;
  StreamSubscription<List<int>>? _sub;
  Object? _error;

  bool _rawMode = false;
  StreamController<List<int>>? _rawController;
  bool _rawClosed = false;

  SocketReader(this.socket) {
    _sub = socket.listen(
      _onChunk,
      onDone: _onDone,
      onError: (Object e, StackTrace _) {
        _error = e;
        _onDone();
      },
    );
  }

  int get _buffered =>
      _chunks.fold(0, (sum, chunk) => sum + chunk.length) - _head;

  void _onChunk(List<int> chunk) {
    if (_rawMode) {
      _rawController?.add(chunk);
    } else {
      _chunks.add(Uint8List.fromList(chunk));
      _onData?.complete();
      _onData = null;
    }
  }

  void _onDone() {
    _closed = true;
    _onData?.complete();
    _onData = null;
    if (_rawMode && !_rawClosed) {
      _rawClosed = true;
      _rawController?.close();
    }
  }

  Future<bool> _wait() async {
    while (_buffered == 0 && !_closed && _error == null) {
      final completer = Completer<void>();
      _onData = completer;
      await completer.future;
    }
    return _buffered > 0;
  }

  /// Reads one line without the trailing `\n`. Returns null on EOF.
  Future<String?> readLine() async {
    final bytes = await readLineBytes();
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<Uint8List?> readLineBytes() async {
    final out = BytesBuilder();
    while (true) {
      while (_chunks.isNotEmpty) {
        final first = _chunks.first;
        var i = _head;
        for (; i < first.length; i++) {
          if (first[i] == 0x0A) {
            out.add(first.sublist(_head, i));
            _advance(i - _head + 1);
            return out.takeBytes();
          }
        }
        out.add(first.sublist(_head));
        _advance(first.length - _head);
      }
      if (!await _wait()) {
        if (_error != null) throw SocketException('$_error');
        return null;
      }
    }
  }

  /// Switches to raw byte mode. Emits any buffered remainder first, then
  /// all future socket bytes. Call only after the text header is consumed.
  Stream<List<int>> raw() {
    if (_rawMode) return _rawController!.stream;
    _rawMode = true;
    final controller = StreamController<List<int>>();
    _rawController = controller;
    if (_buffered > 0) {
      final pending = BytesBuilder();
      if (_chunks.isNotEmpty) {
        pending.add(_chunks.first.sublist(_head));
        for (var i = 1; i < _chunks.length; i++) {
          pending.add(_chunks[i]);
        }
      }
      _chunks.clear();
      _head = 0;
      controller.add(pending.takeBytes());
    }
    if (_closed && !_rawClosed) {
      _rawClosed = true;
      controller.close();
    }
    return controller.stream;
  }

  void _advance(int n) {
    while (n > 0 && _chunks.isNotEmpty) {
      final first = _chunks.first;
      final remaining = first.length - _head;
      if (n >= remaining) {
        n -= remaining;
        _chunks.removeAt(0);
        _head = 0;
      } else {
        _head += n;
        n = 0;
      }
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    if (_rawMode && !_rawClosed) {
      _rawClosed = true;
      await _rawController?.close();
    }
  }
}
