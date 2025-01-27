// ignore_for_file: avoid_print

import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "wing_bridge.dart";
import "mixer_state.dart";
import "hexcolor.dart";
import "buttons.dart";
import "let.dart";

WingConsole? c;
Map<String, dynamic> config = {};

typedef JList = List<dynamic>;
typedef JMap = Map<String, dynamic>;

class MixerOutput {
  final String id;
  final String name;
  final Color color;
  final int bus;
  final int wingPropLevel;
  final int wingPropMute;

  double level = 0.0;
  bool enabled = false;

  final Map<String, MixerOutputSource> sources = {};

  MixerOutput._({
      required this.id,
      required this.name,
      required this.color,
      required this.bus,
      required this.wingPropLevel,
      required this.wingPropMute,
      });

  factory MixerOutput.fromJson(Map<String, dynamic> json) {
    return MixerOutput._(
        id: json["id"],
        name: json["name"],
        color: HexColor.fromHex(json["color"]),
        bus: json["bus"],
        wingPropLevel: WingConsole.nodeNameToId("/bus/${json["bus"]}/fdr"),
        wingPropMute: WingConsole.nodeNameToId("/bus/${json["bus"]}/mute"),
      );
  }

  void toggleEnabled() {
    enabled = !enabled;
    c!.setInt(wingPropMute, enabled ? 0 : 1);
  }

  void changeLevel(double val) {
    if (level == -90 && val < 0) {
      level = -144;
    } else {
      level += val;
      level = level.clamp(-90.0, 10.0);
    }
    c!.setFloat(wingPropLevel, val);
  }
}

class MixerOutputSource {
  final MixerOutput output;
  final MixerInput input;
  final int wingPropLevel;
  final int wingPropSend;

  double level = 0.0;
  bool enabled = false;

  MixerOutputSource({
      required this.output,
      required this.input,
      required this.wingPropLevel,
      required this.wingPropSend,
  });

  void toggleEnabled() {
    enabled = !enabled;
    c!.setInt(wingPropSend, enabled ? 1 : 0);
  }

  void changeLevel(double val) {
    if (level == -90 && val < 0) {
      level = -144;
    } else {
      level += val;
      level = level.clamp(-90.0, 10.0);
    }
    c!.setFloat(wingPropLevel, val);
  }
}

class MixerInput {
  final String id;
  final String name;
  final Color color;
  final int channel;

  MixerInput._({
      required this.id,
      required this.name,
      required this.color,
      required this.channel,
      });

  factory MixerInput.fromJson(Map<String, dynamic> json) {
    return MixerInput._(
      id: json["id"],
      name: json["name"],
      color: HexColor.fromHex(json["color"]),
      channel: json["channel"] as int,
    );
  }
}

Map<String, MixerOutput> mixerOutputs = {};
Map<String, MixerInput> mixerInputs = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var consoles = WingDiscover.scan();

  for (final element in consoles) {
    print("${element.name} @ ${element.ip} [${element.model}/${element.serial}/${element.firmware}]\n");
  }

  c = WingConsole.connect(consoles[0].ip);


  config = jsonDecode(await File("/Users/danny/work/studio161/config.json").readAsString());

  (config["inputs"] as JList).map((input) => MixerInput.fromJson(input)).forEach((input) {
    mixerInputs[input.id] = input;
  });
  (config["outputs"] as JList).map((output) => MixerOutput.fromJson(output)).forEach((output) {
    mixerOutputs[output.id] = output;
    for (final input in mixerInputs.values) {
      output.sources[input.id] = MixerOutputSource(
        output: output,
        input: input,
        wingPropLevel: WingConsole.nodeNameToId("/ch/${input.channel}/send/${output.bus}/lvl"),
        wingPropSend: WingConsole.nodeNameToId("/ch/${input.channel}/send/${output.bus}/on")
      );
    }
  });

  for (final output in mixerOutputs.values) {
    c!.requestNodeData(WingConsole.nodeNameToId("/bus/${output.bus}/fdr"));
    c!.requestNodeData(WingConsole.nodeNameToId("/bus/${output.bus}/mute"));
    for (final input in output.sources.values.map((source) => source.input)) {
      c!.requestNodeData(WingConsole.nodeNameToId("/ch/${input.channel}/send/${output.bus}/on"));
      c!.requestNodeData(WingConsole.nodeNameToId("/ch/${input.channel}/send/${output.bus}/lvl"));
    }
  }

  c!.read();
  runApp(ChangeNotifierProvider(
    create: (context) => MixerState(c!),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Studio161",
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 1000,
        height: 80,
        child: MainBar(),
      ),
    );
  }
}

class MainBar extends StatefulWidget {
  const MainBar({super.key});

  @override
  State<MainBar> createState() => _MainBarState();
}

class _MainBarState extends State<MainBar> {
  int level = 0;
  MixerOutput? selectedOutput;

  List<Widget> level1() {
    return mixerOutputs.values
        .map((output) => ClickDragButton(
              id: output.id,
              color: output.color,
              enabled: output.enabled,
              level: output.level,
              onTap: () {
                selectedOutput = output;
                level = 1;
                setState(() { });
              },
              onDrag: (val) {
                output.changeLevel(val);
              },
            ))
        .toList();
  }
  List<Widget> level2() {
    return selectedOutput!.let((output) => [
        ClickDragButton(
          id: "home",
          color: HexColor.fromHex("#808080"),
          onTap: () {
            level = 0;
            selectedOutput = null;
            setState(() { });
          },
        ),
        ClickDragButton(
          id: selectedOutput!.id,
          color: HexColor.fromHex("#ff0000"),
          enabled: selectedOutput!.enabled,
          level: selectedOutput!.level,
          onTap: () {
            selectedOutput!.toggleEnabled();
          },
          onDrag: (val) {
            selectedOutput!.changeLevel(val);
          },
        ),
        SizedBox(width: 10),
        ...(selectedOutput!.sources.values
          .map((source) =>
            ClickDragButton(
              id: source.input.id,
              color: source.input.color,
              enabled: source.enabled,
              level: source.level,
              onTap: () {
                source.toggleEnabled();
              },
              onDrag: (val) {
                source.changeLevel(val);
              },
            )).toList())
      ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerState>(
      builder: (context, mixerState, child) => Container(
      color: Colors.yellow,
      height: 80,
      child: Row(
        children:
        iff(selectedOutput == null, level1)
        .elseIf(level == 1, level2)
        .orElse(() => [])!
      ),
    );
  }
}
