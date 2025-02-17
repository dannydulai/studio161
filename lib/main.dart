import 'package:flutter/services.dart'; // For `SystemChrome` and `rootBundle`
import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import "wing_bridge.dart";
import "buttons.dart";
import "let.dart";
import "mixer.dart";
import "mixer_io.dart";

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  prefs = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    // the app should be full screen on android, so
    // disable the top status bar and bottom navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  } else {
    await windowManager.waitUntilReadyToShow();
    await windowManager.setMinimumSize(Size(960, 600));
    if (prefs.getDouble("windowX") != null && prefs.getDouble("windowY") != null) {
        // print("setting position to ${prefs.getDouble("windowX")!},${prefs.getDouble("windowY")!}");
        await windowManager.setPosition(Offset(prefs.getDouble("windowX")!, prefs.getDouble("windowY")!));
    }
    if (prefs.getDouble("windowW") != null && prefs.getDouble("windowH") != null) {
      // print("setting size to ${prefs.getDouble("windowW")!}x${prefs.getDouble("windowH")!}");
      await windowManager.setSize(Size(prefs.getDouble("windowW")!, prefs.getDouble("windowH")!));
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Mixer mixer = Mixer();

  final config = jsonDecode(await rootBundle.loadString('config.json'));

  (config["fx"] as JList).map((fx) => MixerFx.fromJson(fx)).forEach((fx) {
    mixer.fxs.add(fx);
  });
  (config["inputs"] as JList).map((input) => MixerInput.fromJson(input)).forEach((input) {
    mixer.inputs.add(input);
  });
  (config["outputs"] as JList).map((output) => MixerOutput.fromJson(output)).forEach((output) {
    mixer.outputs.add(output);
    for (final fx in mixer.fxs) {
      output.sources.add(MixerFxSource(
        fx: fx,
        output: output,
        wingPropSend: WingConsole.nameToId("/${fx.bus}/${output.outputSof}/on"),
      ));
    }
    for (final input in mixer.inputs) {
      output.sources.add(MixerInputSource(
        output: output,
        input: input,
        wingPropSend: WingConsole.nameToId("/ch/${input.channel}/${output.outputSof}/on"),
        wingPropLevel: WingConsole.nameToId("/ch/${input.channel}/${output.outputSof}/lvl"),
      ));
    }
  });
  for (final fx in mixer.fxs) {
    for (final input in mixer.inputs) {
      fx.sources.add(MixerInputSource(
        output: fx,
        input: input,
        wingPropSend: WingConsole.nameToId("/ch/${input.channel}/${fx.outputSof}/on"),
        wingPropLevel: WingConsole.nameToId("/ch/${input.channel}/${fx.outputSof}/lvl"),
      ));
    }
  }

  mixer.connect();

  runApp(ChangeNotifierProvider.value(
    value: mixer,
    child: MyApp(mixer: mixer),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.mixer});

  final Mixer mixer;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    if (!Platform.isAndroid) {
      windowManager.addListener(this);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (!Platform.isAndroid) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowResized() async {
    final bounds = await windowManager.getBounds();
    // print("resized to ${bounds.width}x${bounds.height}@${bounds.left},${bounds.top}");
    prefs.setDouble("windowW", bounds.width);
    prefs.setDouble("windowH", bounds.height);
  }

  @override
  void onWindowMoved() async {
    final bounds = await windowManager.getBounds();
    // print("moved to ${bounds.width}x${bounds.height}@${bounds.left},${bounds.top}");
    prefs.setDouble("windowX", bounds.left);
    prefs.setDouble("windowY", bounds.top);
  }


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Studio161",
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Container(
          color: Colors.black,
          // width: 960,
          // height: 600,
          child: MainBar(mixer: widget.mixer),
        ),
      ),
    );
  }
}

class MainBar extends StatefulWidget {
  const MainBar({super.key, required this.mixer});

  final Mixer mixer;

  @override
  State<MainBar> createState() => _MainBarState();
}

class _MainBarState extends State<MainBar> {
  int level = 0;
  late MixerOutput selectedTab;
  MixerInputSource? selectedSource;

  @override
  void initState() {
    selectedTab = widget.mixer.outputs.first;
    super.initState();
  }

  buildOutputTab(Mixer mixer, MixerOutput output) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (output.id == selectedTab.id) {
            selectedTab.toggleMute(mixer);
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

  buildNotConnected(Mixer mixer) {
    return GestureDetector(
      onTap: () {
        mixer.connect();
      },
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mixer.connecting ? "Connecting..." : "Disconnected",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              if (mixer.connecting)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              if (!mixer.connecting)
                FilledButton(
                  onPressed: () {
                    mixer.connect();
                  },
                  child: Text(
                    "Connect",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Mixer>(
        builder: (context, mixer, child) {
        return !mixer.connected ? buildNotConnected(mixer) : Stack(
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
                            for (final output in mixer.outputs) OutputRow(output: output, mixer: mixer),
                          ]),
                          SizedBox(height: 20),
                          Column(children: [for (final input in mixer.inputs) InputRow(input: input, mixer: mixer)]),
                          SizedBox(height: 20),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                              FilledButton(
                                  onPressed: () {
                                      mixer.terminate();
                                  },
                                  child: Text(
                                      "Break connection",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                      ),
                                  ),
                              ),
                              FilledButton(
                                  onPressed: () {
                                      mixer.disconnect();
                                  },
                                  child: Text(
                                      "Disconnect",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                      ),
                                  ),
                              ),
                              ]),
                            ]),
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
                                selectedSource!.setLevel(mixer, 0);
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
                            ...mixer.fxs.map(
                              (fx) => GestureDetector(
                                onTap: () {
                                  fx.toggleEnabled(mixer, selectedSource!.input);
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
            );
        }
    );
  }
}
