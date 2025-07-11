import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'wing_bridge.dart';
import 'wing_bindings.dart';
import 'mixer_io.dart';

// class ReadIsolateData {
//     final Pointer<NativeWingConsole> nativeConsole;
//     final SendPort sendPort;
//     ReadIsolateData(this.nativeConsole, this.sendPort);
// }
//
// class ReadIsolateMeter {
//     final Pointer<NativeWingConsole> nativeConsole;
//     final SendPort sendPort;
//     ReadIsolateMeter(this.nativeConsole, this.sendPort);
// }
//
// class IsolateResponse {
//     final Pointer<NativeResponse> response;
//     IsolateResponse(this.response);
// }

// void _taskData(ReadIsolateData iso) async {
//     while (true) {
//       final r = ffiBindings.consoleRead(iso.nativeConsole);
//       iso.sendPort.send(IsolateResponse(r));
//       if (r == nullptr) {
//           // print("null from nativeread()");
//         break;
//       }
//     }
// }

// void _taskMeter(ReadIsolateMeter iso) async {
//     while (true) {
//         final data = malloc<Int16>(8192);
//         final id = malloc<Uint16>(1);
//       try {
//           final n = ffiBindings.consoleReadMeter(iso.nativeConsole, id, data);
//           if (n < 0) {
//               iso.sendPort.send(n);
//               break;
//           }
//           final list = <int>[];
//           for (int i = 0; i < n; i++) {
//               list.add(data[i]);
//           }
//           iso.sendPort.send((id[0], list));
//       } finally {
//           malloc.free(data);
//       }
//     }
// }

class Mixer extends ChangeNotifier {
  var connected = false;
  var connecting = false;
  WingConsole? console;

  List<MixerOutput> outputs = [];
  List<MixerInput> inputs = [];
  List<MixerFx> fxs = [];

  void connect() async {
    // print("connecting");
    connecting = true;
    signal();
    console = WingConsole.connect(null);
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

    for (final output in outputs) {
      output.requestData(this);
    }
    for (final fx in fxs) {
      fx.requestData(this);
    }

    // await for (final msg in console!.read()) {
    //   if (msg == null) {
    //     // print("lost connection");
    //     connecting = false;
    //     connected = false;
    //     signal();
    //     connect();
    //     break;
    //   } else if (msg.type == ResponseType.nodeData) {
    //     if (outputs.map((output) => output.onMixerData(msg)).any((r) => r) ||
    //         fxs.map((fx) => fx.onMixerData(msg)).any((r) => r)) {
    //       signal();
    //     }
    //   }
    // }
    console!.read().listen(onDone: () {
      // print("lost connection due to hangup");
      if (connected) {
        // print("... but reconnecting");
        connecting = false;
        connected = false;
        signal();
        connect();
      }
    }, (r) {
      if (r.type == ResponseType.nodeData) {
        if (outputs.map((output) => output.onMixerData(r)).any((r) => r) ||
            fxs.map((fx) => fx.onMixerData(r)).any((r) => r)) {
          signal();
        }
      }
    });
    // final mid = requestMeters([Meter(MeterType.channel, 7)]);
    // print("meter request 1: $mid");
    // console!.readMeter().listen((x) {
    //   print("${x.$1} => [ ${x.$2.map((r) => r.toRadixString(16)).join(" ")} ]");
    // });
  }

  void terminate() {
    console!.close();
    console = null;
  }

  void disconnect() {
    connecting = false;
    connected = false;
    if (console != null) {
      console!.close();
      console = null;
    }
    signal();
  }

  int requestMeters(List<Meter> meters) {
    return console!.requestMeters(meters);
  }

  // Future<Stream> readMeters() async {
  //   final StreamController stream = StreamController();
  //   final receivePort = ReceivePort();
  //   receivePort.listen((message) {
  //     if (message is (int, List<int>)) {
  //       stream.add(message);
  //     }
  //   });
  //   await Isolate.spawn<ReadIsolateMeter>(
  //       _taskMeter, ReadIsolateMeter(console!.nativePointer, receivePort.sendPort));
  //   return stream.stream;
  // }

  void signal() {
    // print("notifyListeners");
    notifyListeners();
  }
}
