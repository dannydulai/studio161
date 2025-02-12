import 'dart:isolate';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'wing_bridge.dart';
import 'wing_bindings.dart';
import 'mixer_io.dart';

class ReadIsolateData {
    final Pointer<NativeWingConsole> nativeConsole;
    final SendPort sendPort;
    ReadIsolateData(this.nativeConsole, this.sendPort);
}

class IsolateResponse {
    final Pointer<NativeResponse> response;
    IsolateResponse(this.response);
}

void _task(ReadIsolateData iso) {
    while (true) {
      final r = ffiBindings.consoleRead(iso.nativeConsole);
      iso.sendPort.send(IsolateResponse(r));
      if (r == nullptr) {
        break;
      }
    }
}

class MixerState extends ChangeNotifier {
  WingConsole console;

  MixerState(this.console);

  void read() async {
    final receivePort = ReceivePort();
    receivePort.listen((message) {
      if (message is IsolateResponse) {
        _onNodeData(Response.fromNative(message.response));
      } else {
        throw UnimplementedError();
      }
    });
    await Isolate.spawn<ReadIsolateData>(_task, ReadIsolateData(console.nativePointer, receivePort.sendPort));
  }

  void _onNodeData(Response r) {
    if (r.type == ResponseType.nodeData) {
      String? name = WingConsole.idToName(r.dataId);
      if (name == "") name = "<UnknownId:${r.dataId}>";
      // print("onData: ${r.dataId} / $name: ${r.dataStringValue}");

      bool changed = false;

      for (final output in mixerOutputs) {
        if (output.onMixerData(r)) changed = true;
      }

      if (changed) { signal(); }
    }
  }

  void signal() {
    // print("notifyListeners");
    notifyListeners();
  }
}
