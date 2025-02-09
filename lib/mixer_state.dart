import 'dart:isolate';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'wing_bridge.dart';
import 'wing_bindings.dart';
import 'main.dart';

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

      for (final output in mixerOutputs.values) {
        if (r.dataId == output.wingPropLevel) {
          // print("output ${output.id} lvl ${output.wingPropLevel} ${output.level} => ${r.dataFloatValue}");
          output.level = r.dataFloatValue;
          changed = true;
        }
        if (r.dataId == output.wingPropMute) {
          // print("output ${output.id} mute ${output.wingPropMute} ${output.enabled} => ${r.dataIntValue == 0}");
          output.enabled = r.dataIntValue == 0;
          changed = true;
        }

        for (final source in output.sources.values) {
          if (r.dataId == source.wingPropLevel) {
            // print("source ${source.input.id} lvl ${source.wingPropLevel} ${source.level} => ${r.dataFloatValue}");
            source.level = r.dataFloatValue;
            changed = true;
          }
          if (r.dataId == source.wingPropSend) {
            // print("source ${source.input.id} send ${source.wingPropSend} ${source.enabled} => ${r.dataIntValue != 0}");
            source.enabled = r.dataIntValue != 0;
            changed = true;
          }
        }
      }

      if (changed) {
        // print("notifyListeners");
        notifyListeners();
      }
    }
  }

  void signal() {
    notifyListeners();
  }
}
