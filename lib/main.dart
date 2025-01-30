import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "wing_bridge.dart";
import "mixer_state.dart";
import "buttons.dart";
import "let.dart";

late WingConsole _c;
late MixerState _mixerState;
late Map<String, dynamic> config;

typedef JList = List<dynamic>;
typedef JMap = Map<String, dynamic>;

class MixerOutput {
  final String id;
  final String name;
  final Color color;
  final String output;
  final String outputSof;
  final int wingPropLevel;
  final int wingPropMute;

  double level = 0.0;
  bool enabled = false;

  final Map<String, MixerOutputSource> sources = {};

  MixerOutput._({
    required this.id,
    required this.name,
    required this.color,
    required this.output,
    required this.outputSof,
    required this.wingPropLevel,
    required this.wingPropMute,
  });

  factory MixerOutput.fromJson(Map<String, dynamic> json) {
    String output, outputSof;
    if (!json.containsKey("id")) throw Exception("Invalid output definition -- must contain 'id'");
    if (!json.containsKey("name")) throw Exception("Invalid output definition -- must contain 'name'");
    if (!json.containsKey("color")) throw Exception("Invalid output definition -- must contain 'color'");

    if (json.containsKey("bus")) {
        output    = "bus/${json["bus"]}";
        outputSof = "send/${json["bus"]}";
    } else if (json.containsKey("main")) {
        output    = "main/${json["main"]}";
        outputSof = "main/${json["main"]}";
    } else {
        throw Exception("Invalid output definition for output ${json["id"]} -- must contain either 'bus' or 'main'");
    }

    return MixerOutput._(
      id: json["id"],
      name: json["name"],
      color: HexColor.fromHex(json["color"]),
      output: output,
      outputSof: outputSof,
      wingPropLevel: WingConsole.nodeNameToId("/$output/fdr"),
      wingPropMute: WingConsole.nodeNameToId("/$output/mute"),
    );
  }

  void toggleEnabled() {
    enabled = !enabled;
    _c.setInt(wingPropMute, enabled ? 0 : 1);
    _mixerState.signal();
  }

  void changeLevel(double val) {
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
    _c.setFloat(wingPropLevel, level);
    _mixerState.signal();
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
    _c.setInt(wingPropSend, enabled ? 1 : 0);
    _mixerState.signal();
  }

  void changeLevel(double val) {
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
    _c.setFloat(wingPropLevel, level);
    _mixerState.signal();
  }
}

class MixerInput {
  final String id;
  final String name;
  final Color color;
  final int channel;

  int fx = 0;

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
  // ignore: avoid_print
  print("current dir: ${Directory.current.path}");

  WidgetsFlutterBinding.ensureInitialized();
  WingConsole.nodeInitMap("wing-schema.map");

  var consoles = WingDiscover.scan();
  for (final element in consoles) {
      // ignore: avoid_print
    print("${element.name} @ ${element.ip} [${element.model}/${element.serial}/${element.firmware}]");
  }

  _c = WingConsole.connect(consoles[0].ip);
  _mixerState = MixerState(_c);

  config = jsonDecode(
      await File("config.json").readAsString());

  (config["inputs"] as JList)
      .map((input) => MixerInput.fromJson(input))
      .forEach((input) {
    mixerInputs[input.id] = input;
  });
  (config["outputs"] as JList)
      .map((output) => MixerOutput.fromJson(output))
      .forEach((output) {
    mixerOutputs[output.id] = output;
    for (final input in mixerInputs.values) {
      output.sources[input.id] = MixerOutputSource(
          output: output,
          input: input,
          wingPropLevel: WingConsole.nodeNameToId(
              "/ch/${input.channel}/${output.outputSof}/lvl"),
          wingPropSend: WingConsole.nodeNameToId(
              "/ch/${input.channel}/${output.outputSof}/on"));
    }
  });

  for (final output in mixerOutputs.values) {
    _c.requestNodeData(WingConsole.nodeNameToId("/${output.output}/fdr"));
    _c.requestNodeData(WingConsole.nodeNameToId("/${output.output}/mute"));
    for (final input in output.sources.values.map((source) => source.input)) {
      _c.requestNodeData(WingConsole.nodeNameToId(
          "/ch/${input.channel}/${output.outputSof}/on"));
      _c.requestNodeData(WingConsole.nodeNameToId(
          "/ch/${input.channel}/${output.outputSof}/lvl"));
    }
  }

  _c.read();
  runApp(ChangeNotifierProvider.value(
    value: _mixerState,
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
      themeMode: ThemeMode.dark, 
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
      body: Container(
        color: Colors.black,
        width: 1280,
        height: 400,
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
  late MixerOutput selectedOutput;
  MixerOutputSource? selectedSource;

  @override
  void initState() {
    selectedOutput = mixerOutputs.values.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerState>(builder: (context, mixerState, child) {
      double pct = (((selectedOutput.level == -144.0 ? -90.0 : selectedOutput.level) + 90.0) / 100.0).clamp(0.0, 1.0);

      return Stack(
      fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // the output list
              Container(
              padding: EdgeInsets.only(right: 5),
                child: Column(spacing: 5, children: [
                  ...mixerOutputs.values.map((output) => Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (output.id == selectedOutput.id) {
                              selectedOutput.toggleEnabled();
                            } else {
                              selectedOutput = output;
                              setState(() {});
                            }
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: output.id == selectedOutput.id ? output.color : Colors.black,
                                    border: Border.all(
                                      color: output.color,
                                      width: 2,
                                    ),
                                  ),
                                  width: 120,
                                  child: Stack(
                                      fit: StackFit.expand,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            "${output.level == -144.0 ? "-∞" : output.level.toStringAsFixed(1)} dB",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: output.id == selectedOutput.id ? Colors.black : output.color,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          output.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: output.id == selectedOutput.id ? Colors.black : output.color,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      if (!output.enabled)
                                        Positioned(
                                        bottom: 0,
                                        left: 0,
                                          child: Container(
                                            height: 30,
                                            width: 30,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                stops: [.5, .5],
                                                begin: Alignment.bottomLeft,
                                                end: Alignment.topRight,
                                                colors: [
                                                  HexColor.fromHex("#ff4040"),
                                                  Colors.transparent, // top Right part
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ) as Widget,
                      )),
                ]),
              ),
              Expanded(
                // the output controls + source list
                child: Column(children: [
                  // the topbar
                  Container(
                  color: selectedOutput.color,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            selectedOutput.toggleEnabled();
                          },
                          child: Container(
                            margin: EdgeInsets.only(top: 10, bottom: 10, left: 30, right: 10),
                            height: 30,
                            child: Container(
                              width: 100,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selectedOutput.enabled ? Colors.transparent : HexColor.fromHex("#ff4040"),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Text(
                                selectedOutput.enabled ? "MUTE" : "MUTED",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              selectedOutput.changeLevel(details.delta.dx / 40.0);
                            },
                            child: Container(
                              padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 30),
                              child: Column(children: [
                                SizedBox(
                                  height: 30,
                                  child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                    return Stack(alignment: Alignment.center, children: [
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 1,
                                        bottom: 1,
                                        left: 1,
                                        right: 1 + ((constraints.maxWidth - 2) * (1.0 - pct)),
                                        child: Container(
                                          color: selectedOutput.color.addLightness(-0.1),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: 10,
                                        child: Text(
                                          "${selectedOutput.level == -144.0 ? "-∞" : selectedOutput.level.toStringAsFixed(1)} dB",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ]);
                                  }),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: selectedOutput.sources.values
                            .map(
                              (source) => ClickDragButton(
                              width: 250,
                              height: 60,
                                name: source.input.name,
                                color: source.input.color,
                                enabled: source.enabled,
                                level: source.level,
                                onTap: () {
                                  source.toggleEnabled();
                                },
                                onLongPress: () {
                                    selectedSource = source;
                                    setState(() {});
                                },
                                onDrag: (val) {
                                  source.changeLevel(val);
                                },
                              ) as Widget,
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          if (selectedSource != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                selectedSource = null;
                setState(() {});
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    width: 900,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 2,
                      ),
                      color: Colors.black,
                    ),
                    child: Row(
                      children: [
                        Text("None"),
                        Text("FX1"),
                        Text("FX2"),
                        Text("FX3"),
                        Text("FX4"),
                      ],
                    ),
                  ),
                ),
              ),
            )
        ],
      );
    });
  }
}
