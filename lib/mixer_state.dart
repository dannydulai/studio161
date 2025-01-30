import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'wing_bridge.dart';
import 'main.dart';

class MixerState extends ChangeNotifier {
  final WingConsole console;

  MixerState(this.console) {
    console.setNodeDataCallback(_onNodeData);
  }

  void _onNodeData(int id, NodeData data) {
    String name = WingConsole.nodeIdToName(id);
    if (name == "") name = "<UnknownId:$id>";
    // print("onData: $id / $name: ${data.stringValue}");

    bool changed = false;

    for (final output in mixerOutputs.values) {
      if (id == output.wingPropLevel) {
        // print("output ${output.id} lvl ${output.wingPropLevel} ${output.level} => ${data.floatValue}");
        output.level = data.floatValue;
        changed = true;
      }
      if (id == output.wingPropMute) {
        // print("output ${output.id} mute ${output.wingPropMute} ${output.enabled} => ${data.intValue == 0}");
        output.enabled = data.intValue == 0;
        changed = true;
      }

      for (final source in output.sources.values) {
        if (id == source.wingPropLevel) {
          // print("source ${source.input.id} lvl ${source.wingPropLevel} ${source.level} => ${data.floatValue}");
          source.level = data.floatValue;
          changed = true;
        }
        if (id == source.wingPropSend) {
          // print("source ${source.input.id} send ${source.wingPropSend} ${source.enabled} => ${data.intValue != 0}");
          source.enabled = data.intValue != 0;
          changed = true;
        }
      }
    }

    if (changed) {
      // print("notifyListeners");
      notifyListeners();
    }
  }

  void signal() {
    notifyListeners();
  }
}
