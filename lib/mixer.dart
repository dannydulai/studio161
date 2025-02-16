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

void _task(ReadIsolateData iso) async {
    while (true) {

    await Future.delayed(Duration(milliseconds: 100));

      // final r = ffiBindings.consoleRead(iso.nativeConsole);
      // iso.sendPort.send(IsolateResponse(r));
      // if (r == nullptr) {
      //     print("null from nativeread()");
      //   break;
      // }
    }
}

class Mixer extends ChangeNotifier {
    var connected = false;
    var connecting = false;
    WingConsole? console;

  void connect() async {
    print("connecting");
    connecting = true;
    signal();
    console = WingConsole.connect(null);
    print(console);
    connecting = false;
    if (console == null) {
      print("failed to connect");
      connected = false;
      signal();
      return;
    }

    print("connected");
    connected = true;
    signal();

    for (final output in mixerOutputs) {
      output.requestData(this);
    }
    for (final fx in mixerFxs) {
      fx.requestData(this);
    }
    read();
  }

  void terminate() {
      connecting = false;
      connected = false;
      console!.close();
      console = null;
  }
  void disconnect() {
      connecting = false;
      connected = false;
      console!.close();
      console = null;
      signal();
  }

  Future read() async {
    final receivePort = ReceivePort();
    receivePort.listen((message) {
      if (message is IsolateResponse) {
        if (message.response == nullptr) {
          print("lost connection");
          if (connected) {
            connecting = false;
            connected = false;
            signal();
            connect();
          }
        } else {
          _onNodeData(Response.fromNative(message.response));
        }
      } else {
        throw UnimplementedError();
      }
    });
    await Isolate.spawn<ReadIsolateData>(_task, ReadIsolateData(console!.nativePointer, receivePort.sendPort));
  }

  void _onNodeData(Response r) {
    if (r.type == ResponseType.nodeData) {

    if (mixerOutputs.map((output) => output.onMixerData(r)).any((r) => r) ||
        mixerFxs.map((fx) => fx.onMixerData(r)).any((r) => r)) {
          signal();
      }
    }
  }

  void signal() {
    // print("notifyListeners");
    notifyListeners();
  }
}
