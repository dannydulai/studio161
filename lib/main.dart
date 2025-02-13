import 'package:flutter/services.dart'; // For `SystemChrome` and `rootBundle`
import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:flutter_svg/flutter_svg.dart';

import "wing_bridge.dart";
import "mixer_state.dart";
import "buttons.dart";
import "let.dart";
import "mixer_io.dart";

late WingConsole gConsole;
late MixerState gMixerState;
late Map<String, dynamic> config;

typedef JList = List<dynamic>;
typedef JMap = Map<String, dynamic>;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  //
  // // Dimensions in physical pixels (px)
  // Size size = view.physicalSize;
  // double width = size.width;
  // double height = size.height;
  //
  // print("Width: $width, Height: $height");
  // // Dimensions in logical pixels (dp)
  // Size lsize = view.physicalSize / view.devicePixelRatio;
  // double lwidth = lsize.width;
  // double lheight = lsize.height;
  //
  // print("LWidth: $lwidth, LHeight: $lheight");

  //  print("current dir: ${Directory.current.path}");

  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  var consoles = WingDiscover.scan();
  for (final element in consoles) {
    // ignore: avoid_print
    print("${element.name} @ ${element.ip} [${element.model}/${element.serial}/${element.firmware}]");
  }

  gConsole = WingConsole.connect(consoles[0].ip);
  gMixerState = MixerState(gConsole);

  config = jsonDecode(await rootBundle.loadString('config.json'));

  (config["fx"] as JList).map((fx) => MixerFx.fromJson(fx)).forEach((fx) {
    mixerFxs.add(fx);
  });
  (config["inputs"] as JList).map((input) => MixerInput.fromJson(input)).forEach((input) {
    mixerInputs.add(input);
  });
  (config["outputs"] as JList).map((output) => MixerOutput.fromJson(output)).forEach((output) {
    mixerOutputs.add(output);
    for (final fx in mixerFxs) {
      output.sources.add(MixerFxSource(
        fx: fx,
        output: output,
        wingPropSend: WingConsole.nameToId("/${fx.bus}/${output.outputSof}/on"),
      ));
    }
    for (final input in mixerInputs) {
      output.sources.add(MixerInputSource(
        output: output,
        input: input,
        wingPropSend: WingConsole.nameToId("/ch/${input.channel}/${output.outputSof}/on"),
        wingPropLevel: WingConsole.nameToId("/ch/${input.channel}/${output.outputSof}/lvl"),
      ));
    }
  });
  for (final fx in mixerFxs) {
    for (final input in mixerInputs) {
      fx.sources.add(MixerInputSource(
        output: fx,
        input: input,
        wingPropSend: WingConsole.nameToId("/ch/${input.channel}/${fx.outputSof}/on"),
        wingPropLevel: WingConsole.nameToId("/ch/${input.channel}/${fx.outputSof}/lvl"),
      ));
    }
  }

  for (final output in mixerOutputs) {
    output.requestData();
  }

  gMixerState.read();
  runApp(ChangeNotifierProvider.value(
    value: gMixerState,
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
        // width: 960,
        // height: 600,
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
  late MixerOutput selectedTab;
  MixerInputSource? selectedSource;

  @override
  void initState() {
    selectedTab = mixerOutputs.first;
    super.initState();
  }

  buildOutputTab(MixerOutput output) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (output.id == selectedTab.id) {
            selectedTab.toggleMute();
          } else {
            selectedTab = output;
            setState(() {});
          }
        },
        child: Container(
          margin: EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: output.id == selectedTab.id ? output.color : Colors.black,
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
                  child: SvgPicture.asset(
                    "icons/${output.icon!}",
                    height: 25 * (output.iconScale ?? 1.0),
                    colorFilter: ColorFilter.mode(
                      output.id == selectedTab.id ? Colors.black : output.color,
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
                      color: output.id == selectedTab.id ? Colors.black : output.color,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              if (output.muted)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HexColor.fromHex("#ff4040"),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerState>(
        builder: (context, mixerState, child) => Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Column(children: [
                            for (final output in mixerOutputs) OutputRow(output: output),
                          ]),
                          SizedBox(height: 20),
                          Column(children: [for (final input in mixerInputs) InputRow(input: input)]),
                        ],
                      ),
                    ),
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
                            ...mixerFxs.map(
                              (fx) => GestureDetector(
                                onTap: () {
                                  fx.toggleEnabled(selectedSource!.input);
                                  setState(() {});
                                },
                                child: Container(
                                  width: 150,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    color: fx.isEnabled(selectedSource!.input) ? Colors.green : Colors.black,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (fx.isEnabled(selectedSource!.input))
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
                                        "FX ${fx.name}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: fx.isEnabled(selectedSource!.input) ? FontWeight.bold : null,
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
            )
    );
  }
}
