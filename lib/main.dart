import 'package:flutter/services.dart' show rootBundle;

import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:flutter_svg/flutter_svg.dart';

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
  String? icon;
  double? iconScale;

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
    this.icon,
    this.iconScale,
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
      icon: json["icon"],
      iconScale: json["iconScale"],
      color: HexColor.fromHex(json["color"]),
      output: output,
      outputSof: outputSof,
      wingPropLevel: WingConsole.nameToId("/$output/fdr"),
      wingPropMute: WingConsole.nameToId("/$output/mute"),
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

  int fx = 0;
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

  void setLevel(double val) {
    if (val != -144) {
      val = val.clamp(-90.0, 10.0);
    }
    level = val;
    _c.setFloat(wingPropLevel, level);
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
  String? icon;
  double? iconScale;

  int fx = 0;

  MixerInput._({
    required this.id,
    required this.name,
    required this.color,
    required this.channel,
    this.icon,
    this.iconScale,
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
}

Map<String, MixerOutput> mixerOutputs = {};
Map<String, MixerInput> mixerInputs = {};

void main() async {
  // ignore: avoid_print
  print("current dir: ${Directory.current.path}");

  WidgetsFlutterBinding.ensureInitialized();

  var consoles = WingDiscover.scan();
  for (final element in consoles) {
      // ignore: avoid_print
    print("${element.name} @ ${element.ip} [${element.model}/${element.serial}/${element.firmware}]");
  }

  _c = WingConsole.connect(consoles[0].ip);
  _mixerState = MixerState(_c);

  config = jsonDecode(await rootBundle.loadString('config.json'));

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
          wingPropLevel: WingConsole.nameToId(
              "/ch/${input.channel}/${output.outputSof}/lvl"),
          wingPropSend: WingConsole.nameToId(
              "/ch/${input.channel}/${output.outputSof}/on"));
    }
  });

  for (final output in mixerOutputs.values) {
    _c.requestNodeData(WingConsole.nameToId("/${output.output}/fdr"));
    _c.requestNodeData(WingConsole.nameToId("/${output.output}/mute"));
    for (final input in output.sources.values.map((source) => source.input)) {
      _c.requestNodeData(WingConsole.nameToId(
          "/ch/${input.channel}/${output.outputSof}/on"));
      _c.requestNodeData(WingConsole.nameToId(
          "/ch/${input.channel}/${output.outputSof}/lvl"));
    }
  }

  _mixerState.read();
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
        width: 960,
        height: 600,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // the output list
                Row(
                  spacing: 3,
                  children: [
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
                            child: Container(
                              margin: EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: output.id == selectedOutput.id ? output.color : Colors.black,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                border: Border(
                                  top: BorderSide(color: output.color, width: 2),
                                  left: BorderSide(color: output.color, width: 2),
                                  right: BorderSide(color: output.color, width: 2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (output.icon != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4, bottom: 4, left: 8),
                                      child: SvgPicture.file(
                                        File(output.icon!),
                                        height: 25 * (output.iconScale ?? 1.0),
                                        colorFilter: ColorFilter.mode(
                                          output.id == selectedOutput.id ? Colors.black : output.color,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 4, bottom: 4, left: 8),
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
                                  ),
                                  if (!output.enabled)
                                    Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Container(
                                          height: 10,
                                          width: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: HexColor.fromHex("#ff4040"),
                                          ),
                                        ))
                                ],
                              ),
                            ),
                          ) as Widget,
                        )),
                  ],
                ),
                Container(
                  color: selectedOutput.color,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          selectedOutput.toggleEnabled();
                        },
                        child: Container(
                          margin: EdgeInsets.only(top: 20, bottom: 20, left: 30, right: 10),
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
                            padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 30),
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
                            (source) => SourceTile(
                              source: source,
                              onLongPress: () {
                                selectedSource = source;
                                setState(() {});
                              },
                            ) as Widget,
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedSource != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                selectedSource = null;
                setState(() {});
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () {
                          selectedSource!.setLevel(0);
                          selectedSource = null;
                          setState(() {});
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 10), // extra ten here between this and the FX buttons
                          width: 200,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            color: Colors.grey,
                          ),
                          child: Text(
                            "Reset to 0.0 dB",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                        ...[1, 2, 3].map(
                        (fx) => GestureDetector(
                          onTap: () {
                            if (selectedSource!.fx == fx) {
                              selectedSource!.fx = 0;
                            } else {
                              selectedSource!.fx = fx;
                            }
                            setState(() {});
                          },
                          child: Container(
                            width: 200,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              color: selectedSource!.fx == fx ? Colors.green : Colors.black,
                            ),
                            child: Stack(
                            alignment: Alignment.center,
                              children: [
                                if (selectedSource!.fx == fx)
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    right: 12,
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                Text(
                                  "FX $fx",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: selectedSource!.fx == fx ? FontWeight.bold : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
        ],
      );
    });
  }
}
