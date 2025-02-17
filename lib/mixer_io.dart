import "package:flutter/material.dart";
import "wing_bridge.dart";
import "mixer.dart";
import "let.dart";

abstract class MixerBase {
  final String id;
  final String name;
  final Color color;

  String? icon;
  double? iconScale;

  MixerBase({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.iconScale,
  });

  List<MixerSource> get sources => [];
  void requestData(Mixer mixer);
}

class MixerInput extends MixerBase {
  final int channel;

  MixerInput._({
    required super.id,
    required super.name,
    required super.color,
    super.icon,
    super.iconScale,
    required this.channel,
  });

  factory MixerInput.fromJson(Map<String, dynamic> json) {
    return MixerInput._(
      id: json["id"],
      name: json["name"],
      icon: json["icon"],
      iconScale: json["iconScale"],
      color: HexColor.fromHex(json["color"]),
      channel: json["channel"] as int,
    );
  }

  @override
  void requestData(Mixer mixer) {}
}

class MixerOutput extends MixerBase {
  final String outputSof;
  final int wingPropLevel;
  final int wingPropMute;

  double level = 0.0;
  bool muted = false;

  final List<MixerSource> _sources = [];

  MixerOutput._({
    required super.id,
    required super.name,
    required super.color,
    super.icon,
    super.iconScale,
    required this.outputSof,
    required this.wingPropLevel,
    required this.wingPropMute,
  });

  factory MixerOutput.fromJson(Map<String, dynamic> json) {
    String outputSof;
    if (!json.containsKey("id")) throw Exception("Invalid output definition -- must contain 'id'");
    if (!json.containsKey("name")) throw Exception("Invalid output definition -- must contain 'name'");
    if (!json.containsKey("color")) throw Exception("Invalid output definition -- must contain 'color'");

    int wingPropMute;
    int wingPropLevel;
    if (json.containsKey("bus")) {
      wingPropMute = WingConsole.nameToId("/bus/${json["bus"]}/mute");
      wingPropLevel = WingConsole.nameToId("/bus/${json["bus"]}/fdr");
      outputSof = "send/${json["bus"]}";
    } else if (json.containsKey("main")) {
      wingPropMute = WingConsole.nameToId("/main/${json["main"]}/mute");
      wingPropLevel = WingConsole.nameToId("/main/${json["main"]}/fdr");
      outputSof = "main/${json["main"]}";
    } else {
      throw Exception("Invalid output definition for output ${json["id"]} -- must contain either 'bus' or 'main'");
    }

    return MixerOutput._(
      id: json["id"],
      name: json["name"],
      icon: json["icon"],
      iconScale: json["iconScale"],
      color: HexColor.fromHex(json["color"]),
      outputSof: outputSof,
      wingPropLevel: wingPropLevel,
      wingPropMute: wingPropMute,
    );
  }

  @override
  get sources => _sources;

  void toggleMute(Mixer mixer) {
    muted = !muted;
    mixer.console!.setInt(wingPropMute, muted ? 1 : 0);
    mixer.signal();
  }

  void changeLevel({required double by, required Mixer mixer}) {
    if (level == -144 && by < 0) {
      return;
    } else if (level == -144 && by >= 0) {
      level = -90 + by;
      level = level.clamp(-90.0, 10.0);
    } else if (level == -90 && by < 0) {
      level = -144;
    } else {
      level += by;
      level = level.clamp(-90.0, 10.0);
    }
    mixer.console!.setFloat(wingPropLevel, level);
    mixer.signal();
  }

  bool onMixerData(Response r) {
    bool changed = false;
    if (r.dataId == wingPropLevel) {
      // print("output ${id} lvl ${wingPropLevel} ${level} => ${r.dataFloatValue}");
      level = r.dataFloatValue;
      changed = true;
    }
    if (r.dataId == wingPropMute) {
      // print("output ${id} mute ${wingPropMute} ${enabled} => ${r.dataIntValue == 0}");
      muted = r.dataIntValue != 0;
      changed = true;
    }

    for (final source in sources) {
      if (source.onMixerData(r)) changed = true;
    }

    return changed;
  }

  @override
  void requestData(Mixer mixer) {
    // print("R: O$id, level: $wingPropLevel, mute: $wingPropMute");
    mixer.console!.requestNodeData(wingPropLevel);
    mixer.console!.requestNodeData(wingPropMute);
    for (final src in _sources) {
      // print("    Rin: O$id, source ${src.name}");
      src.requestData(mixer);
    }
  }
}

class MixerFx extends MixerBase {
  final String outputSof;
  final String bus;

  final List<MixerSource> _sources = [];

  MixerFx._({
    required super.id,
    required super.name,
    required super.color,
    super.icon,
    super.iconScale,
    required this.outputSof,
    required this.bus,
  });

  factory MixerFx.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("id")) throw Exception("Invalid output definition -- must contain 'id'");
    if (!json.containsKey("name")) throw Exception("Invalid output definition -- must contain 'name'");
    if (!json.containsKey("color")) throw Exception("Invalid output definition -- must contain 'color'");
    if (!json.containsKey("bus")) throw Exception("Invalid output definition -- must contain 'bus'");

    return MixerFx._(
      id: json["id"],
      name: json["name"],
      icon: json["icon"],
      iconScale: json["iconScale"],
      color: HexColor.fromHex(json["color"]),
      bus: "bus/${json["bus"]}",
      outputSof: "send/${json["bus"]}",
    );
  }

  @override
  get sources => _sources;

  bool isEnabled(MixerInput input) {
    return _sources.any((src) => src is MixerInputSource && src.input == input && src.enabled);
  }

  void toggleEnabled(Mixer mixer, MixerInput input) {
    for (final src in _sources) {
      if (src is MixerInputSource && src.input == input) {
        src.toggleEnabled(mixer);
        break;
      }
    }
  }

  bool onMixerData(Response r) {
    bool changed = false;
    for (final source in sources) {
      if (source.onMixerData(r)) changed = true;
    }
    return changed;
  }

  @override
  void requestData(Mixer mixer) {
    // print("R: F$id");
    for (final src in _sources) {
      // print("    Rin: F$id, source ${src.name}");
      src.requestData(mixer);
    }
  }
}

abstract class MixerSource {
  Color get color;
  String get name;
  String? get icon;
  double? get iconScale;

  final int wingPropSend;

  MixerSource({
    required this.wingPropSend,
  });

  bool enabled = false;

  void toggleEnabled(Mixer mixer) {
    enabled = !enabled;
    mixer.console!.setInt(wingPropSend, enabled ? 1 : 0);
    mixer.signal();
  }

  bool onMixerData(Response r) {
    bool changed = false;
    if (r.dataId == wingPropSend) {
      // print("source ${input.id} send ${wingPropSend} ${enabled} => ${r.dataIntValue != 0}");
      enabled = r.dataIntValue != 0;
      changed = true;
    }
    return changed;
  }

  void requestData(Mixer mixer) {
    // print("        R: mixersource $name, send: $wingPropSend");
    mixer.console!.requestNodeData(wingPropSend);
  }
}

class MixerFxSource extends MixerSource {
  final MixerFx fx;
  final MixerOutput output;

  MixerFxSource({
    required this.fx,
    required this.output,
    required super.wingPropSend,
  });

  @override
  Color get color => fx.color;
  @override
  String get name => fx.name;
  @override
  String? get icon => fx.icon;
  @override
  double? get iconScale => fx.iconScale;
}

class MixerInputSource extends MixerSource {
  final MixerBase output;
  final MixerInput input;
  final int wingPropLevel;

  double level = 0.0;

  MixerInputSource({
    required this.output,
    required this.input,
    required this.wingPropLevel,
    required super.wingPropSend,
  });

  @override
  Color get color => input.color;
  @override
  String get name => input.name;
  @override
  String? get icon => input.icon;
  @override
  double? get iconScale => input.iconScale;

  void setLevel(Mixer mixer, double val) {
    if (val != -144) {
      val = val.clamp(-90.0, 10.0);
    }
    level = val;
    mixer.console!.setFloat(wingPropLevel, level);
    mixer.signal();
  }

  void changeLevel(Mixer mixer, double val) {
    if (level == -144 && val < 0) {
      return;
    } else if (level == -144 && val >= 0) {
      level = -90 + val;
      level = level.clamp(-90.0, 10.0);
    } else if (level == -90 && val < 0) {
      level = -144;
    } else {
      level += val;
      level = level.clamp(-90.0, 10.0);
    }
    setLevel(mixer, level);
  }

  @override
  bool onMixerData(Response r) {
    bool changed = super.onMixerData(r);

    if (r.dataId == wingPropLevel) {
      // print("source ${input.id} lvl ${wingPropLevel} ${level} => ${r.dataFloatValue}");
      level = r.dataFloatValue;
      changed = true;
    }

    return changed;
  }

  @override
  void requestData(Mixer mixer) {
    super.requestData(mixer);
    // print("        R: mixerinputsource $name, send: $wingPropLevel");
    mixer.console!.requestNodeData(wingPropLevel);
  }
}
