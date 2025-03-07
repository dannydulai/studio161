import 'package:flutter/services.dart'; // For `SystemChrome` and `rootBundle`
import "dart:convert";
import "dart:io";
import "dart:math";
import "dart:ui" show FlutterView;
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

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    // ignore: avoid_print
    print("physicalSize: ${view.physicalSize}, devicePixelRatio: ${view.devicePixelRatio}");


  prefs = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    // the app should be full screen on android, so
    // disable the top status bar and bottom navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  } else {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow();
    await windowManager.setMinimumSize(Size(600, 960));
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
    child: ReassembleListener(onReassemble: () {
        mixer.disconnect();
        Future.delayed(Duration(milliseconds: 300), () { mixer.connect(); });
    }, child: MyApp(mixer: mixer)),
  ));
}

class ReassembleListener extends StatefulWidget {
  const ReassembleListener({super.key, required this.onReassemble, required this.child});

  final VoidCallback onReassemble;
  final Widget child;

  @override
  State<ReassembleListener> createState() => _ReassembleListenerState();
}

class _ReassembleListenerState extends State<ReassembleListener> {
  @override
  void reassemble() {
      super.reassemble();
      widget.onReassemble();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
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
              Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4, left: 8),
                child: SvgPicture.asset(
                  "icons/${output.icon}",
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
                      child: Column(children: [
                        // Column(children: [
                        //   for (final output in mixer.outputs) OutputRow(output: output, mixer: mixer),
                        // ]),
                        // SizedBox(height: 20),
                        Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 20,
                          children: [
                            SizedBox(
                              width: 200,
                            ),
                            Expanded(
                              child: OutputTopRow(mixer: mixer),
                            ),
                            SizedBox(
                              width: 200,
                              child: Row(
                                spacing: 5,
                                children: ["FX 1", "FX 2", "FX 3", "FX 4"]
                                    .map(
                                      (x) => Expanded(
                                          child: Text(x,
                                              style: TextStyle(fontSize: 12, color: Colors.white),
                                              textAlign: TextAlign.center)),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Column(
                            spacing: 5,
                            children: [for (final input in mixer.inputs) InputRow(input: input, mixer: mixer)]),
                        SizedBox(height: 5),
                        Column(
                            spacing: 5,
                            children: [for (final input in mixer.fxs) InputRow(input: input, mixer: mixer)]),
                        SizedBox(height: 40),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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

class OutputTopRow extends StatefulWidget {
  const OutputTopRow({
    super.key,
    required this.mixer,
  });

  final Mixer mixer;

  @override
  State<OutputTopRow> createState() => _OutputTopRowState();
}

class _OutputTopRowState extends State<OutputTopRow> {
  double dragDelta = 0.0;
  double origVol = 0.0;

  // we go 21 becaause its a <= and the last value is the max dB, so you can't
  // really get to the last one when scanning, and that means there are 20
  // "slots" to drop a volume bar into
  late List<double> dbVals = List.generate(21, (index) => 0.0, growable: false);

  // This is complicated, so let's define the math clearly:
  //
  // Step 1. Normalizing dB scale (0–1):
  //
  //      val = (db−dbmin) / (dbmax-dbmin)
  //
  // So:
  //    
  //      -60 dB →  0/70 = 0.0
  //        0 dB → 60/70 of the way through the dB, so 6/7
  //      +10 dB → 70/70 = 1.0
  //
  //
  // Step 2. We want to map this normalized value (x) into a nonlinear slider position (sliderPos) between 0 and maxSlider.
  //
  // We use an exponential curve:
  //
  //      sliderPos = 19 * x^γ
  //
  // We know at 0 dB (x=6/7) the sliderPos should be 14 (desired0dBPosition):
  // 
  //      14 = 19 ⋅ (6/7)^γ
  //
  // Solve for γ:
  //
  //      (6/7)^γ = 14/maxSlider
  //
  // Taking logs to solve for gamma:
  //
  //      γ = log(14/maxSlider) / log(6/7)
  //
  // Now gamma is a constant that we can use to convert between the two scales.
  //
  //      x = pow(sliderPos / maxSlider, 1 / gamma)
  //      db = x * (dbmax - dbmin) + dbmin
  //
  // but we have a problem, which is that 0.0 dB does not land on an integer index, so we need to scale the whole thing by a factor to make it work.
  //
  //      desired0dBPosition = 14
  //      current0dBPosition = sliderMax * pow((-dbmin) / (dbmax - dbmin), gamma)
  //      scaleFactor = desired0dBPosition / current0dBPosition
  //
  // and then same as before, but we apply the scalefactor to the slider position:
  //
  //      scaledPos = sliderPos / scaleFactor
  //      x = pow(scaledPos / sliderMax, 1 / gamma)
  //      db = x * (dbmax - dbmin) + dbmin
  //
  double splToDb(int spl) {
    final maxSlider = dbVals.length - 1.0;
    final slider = spl.clamp(0.0, maxSlider);
    final min = -60.0;
    final max = 10.0;
    final desired0dBPosition = 14;

    if (slider == 0) return -144.0; // 0 slider is -infinity dB

    final gamma = log(desired0dBPosition / maxSlider) / log(- min / (max - min));

    final current0dBPosition = maxSlider * pow(-min / (max - min), gamma);
    final scaleFactor = desired0dBPosition / current0dBPosition;

    final scaledPos = slider / scaleFactor; // reverse scaling here
    final x = pow(scaledPos / maxSlider, 1.0 / gamma);
    final val = x * (max - min) + min;

    return (val * 10.0).round() / 10.0; // round to 1 decimal place
  }

  int dbToSpl(double db) {
    db = (db * 10.0).round() / 10.0; // round to 1 decimal place
    for (int i = 0; i < dbVals.length; i++) {
     // print("$db <= ${dbVals[i]} / $i");
      if (db <= dbVals[i]) return i;
    }
    return dbVals.length-1;
  }

  @override
  void initState() {
    super.initState();
    dbVals = List.generate(21, (index) => splToDb(index));
    // print(dbVals);
  }


  @override
  Widget build(BuildContext context) {
    // List<double> testValues = [-80.0, -60.0, -40.0, -20.0, -10.0, 0.0, 5.0, 10.0];
    // for (double db in testValues) {
    //   final index = dbToSpl(db);
    //   print("dB value: ${db.toStringAsFixed(1)} maps to index: $index");
    // }
    //
    // for (int index = 0; index < dbVals.length; index++) {
    //   final db = splToDb(index);
    //   print("Index: $index maps to dB value: ${db.toStringAsFixed(1)}");
    // }

    return Row(
      spacing: 5,
      children: [
        for (final o in widget.mixer.outputs)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                o.toggleMute(widget.mixer);
              },
              onHorizontalDragStart: (details) {
                dragDelta = 0.0;
                origVol = o.level;
              },
              onHorizontalDragUpdate: (details) {
                dragDelta += details.primaryDelta!;

                final v = dbToSpl(origVol) + (dragDelta / 40.0);
                // print("dbToSpl(origVol): ${dbToSpl(origVol)}");
                // print("dragDelta / 60.0: ${dragDelta / 40.0}");
                // print("v: $v");
                // print("v.round(): ${v.round()}");
                // print("splToDb(v): ${splToDb(v.round())}");
                o.setLevel(widget.mixer, splToDb(v.round()));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 5,
                children: [
                  Text(
                    o.name.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    spacing: 1,
                    children: [
                      for (int i = 0; i < dbToSpl(o.level); i++)
                        if (i < 13)
                          Expanded(child: Container(height: 12, color: Colors.green))
                        else if (i == 13)
                          Expanded(child: Container(height: 12, color: Colors.white))
                        else
                          Expanded(child: Container(height: 12, color: Colors.red)),
                      for (int i = dbToSpl(o.level); i < 20; i++)
                        if (i == 13)
                        Expanded(child: Container(height: 12, color: Colors.white30))
                        else
                        Expanded(child: Container(height: 12, color: Colors.white12)),
                    ],
                  ),
                  if (o.muted)
                    Container(
                      height: 16,
                      decoration:
                          BoxDecoration(color: HexColor.fromHex("#ff4040"), borderRadius: BorderRadius.circular(2)),
                      child: Center(
                        child: Text(
                          "MUTED" /* " ${o.leveljtoStringAsFixed(1)}dB [${dbToSpl(o.level)}]" */,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
