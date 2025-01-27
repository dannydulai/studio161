import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'wing_bridge.dart';
import 'main.dart';

class MixerState extends ChangeNotifier {
  final WingConsole console;
  
  MixerState(this.console) {
    console.setNodeDataCallback(_onNodeData);
  }

  void _onNodeData(int id, WingData data) {
    String name = WingConsole.nodeIdToName(id);
    if (name == "") name = "<UnknownId:$id>";
    print("flutter onData: $name: ${data.stringValue}");

    bool changed = false;

    for (final output in mixerOutputs.values) {
      if (id == output.wingPropLevel) {
        output.level = data.floatValue;
        changed = true;
      }
      if (id == output.wingPropMute) {
        output.enabled = data.intValue == 0;
        changed = true;
      }

      for (final source in output.sources.values) {
        if (id == source.wingPropLevel) {
          source.level = data.floatValue;
          changed = true;
        }
        if (id == source.wingPropSend) {
          source.enabled = data.intValue != 0;
          changed = true;
        }
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
}
