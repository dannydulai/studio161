import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mixer_io.dart';
import 'let.dart';

abstract class Box {
    Widget build();
}

class VolBox extends Box {
  String? icon;
  double iconScale;
  String name;
  bool enabled;
  String? volume;
  Color color;
  Function() onTap;
  Function(double)? onVolume;

  VolBox(
    this.icon,
    this.iconScale,
    this.name,
    this.color,
    this.enabled,
    this.volume,
    this.onTap,
    this.onVolume,
  );

  double delta = 0.0;

  @override
  build() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        delta = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        delta += details.primaryDelta!;
        onVolume?.call(details.primaryDelta!);
      },
      onTap: onTap,
      child: Container(
        width: 75,
        height: 42,
        decoration: BoxDecoration(
          color: !enabled ? Colors.black : color,
          border: Border.all(color: color, width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 2,
              left: 4,
              child: Row(
                spacing: 4,
                children: [
                  if (icon != null)
                    SvgPicture.asset(
                      "icons/${icon!}",
                      height: 16 * iconScale,
                      colorFilter: ColorFilter.mode(
                        enabled ? Colors.black : color,
                        BlendMode.srcIn,
                      ),
                    ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.black : color,
                    ),
                  )
                ],
              ),
            ),
            if (volume != null) ...[
              SizedBox(height: 4),
              Positioned(
                bottom: 2,
                right: 4,
                child: Text(
                  volume!,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.black : color,
                  ),
                ),
              ),
            ]

          ],
        ),
      ),
    );
  }
}

class OutBox extends Box {
  String name;
  bool enabled;
  Color color;
  Function() onTap;

  OutBox(
    this.name,
    this.color,
    this.enabled,
    this.onTap,
  );

  @override
  build() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: 65,
        height: 30,
        decoration: BoxDecoration(
          color: !enabled ? Colors.black : color,
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: enabled ? Colors.black : color,
          ),
        ),
      ),
    );
  }
}

class InputRow extends StatelessWidget {
  const InputRow({super.key, required this.input});

  final MixerInput input;

  // Widget buildTileInside() {
  Map<String, MixerInputSource> whichFx(MixerInput input) {
    Map<String, MixerInputSource> ret = {};
    for (final o in mixerFxs) {
      for (final src in o.sources) {
        if (src is MixerInputSource && src.input == input) {
          ret[o.id] = src;
        }
      }
    }
    return ret;
  }

  Map<String, MixerInputSource> whichO(MixerInput input) {
    Map<String, MixerInputSource> ret = {};
    for (final o in mixerOutputs) {
      for (final src in o.sources) {
        if (src is MixerInputSource && src.input == input) {
          ret[o.id] = src;
        }
      }
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    final enFx = whichFx(input);
    final enO = whichO(input);

    final rowicon =    input.icon;
    final iconScale =  input.iconScale ?? 1.0;
    final rowname =    input.name;
    final rowcolor =   input.color;
    final boxes = [
      for (final o in mixerOutputs)
        VolBox(
          o.icon,
          o.iconScale ?? 1.0,
          o.name,
          input.color,
          enO[o.id]!.enabled,
          "${enO[o.id]!.level == -144.0 ? "-∞" : enO[o.id]!.level.toStringAsFixed(1)} dB",
          () {
            enO[o.id]!.toggleEnabled();
          },
          (delta) {
            enO[o.id]!.changeLevel(delta / 20);
          },
        ),
      for (final o in mixerFxs)
        VolBox(null, o.iconScale ?? 1.0, "FX${o.name}", input.color, enFx[o.id]!.enabled,
            "${enFx[o.id]!.level == -144.0 ? "-∞" : enFx[o.id]!.level.toStringAsFixed(1)} dB", () {
          enFx[o.id]!.toggleEnabled();
        }, (delta) {
          enFx[o.id]!.changeLevel(delta / 20);
        })
    ];

    return Row(spacing: 2, children: [
      if (rowicon != null)
        Padding(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: SvgPicture.asset(
                "icons/$rowicon",
                height: 30 * iconScale,
                colorFilter: ColorFilter.mode(
                  rowcolor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      Expanded(
        child: Text(
          rowname,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: rowcolor,
          ),
          textAlign: TextAlign.left,
        ),
      ),
      Row(spacing: 2, children: [for (final o in boxes) o.build()]),
    ]);
  }
}

class OutputRow extends StatelessWidget {
  const OutputRow({super.key, required this.output});

  final MixerOutput output;

  @override
  Widget build(BuildContext context) {
    double pct = (((output.level == -144.0 ? -90.0 : output.level) + 90.0) / 100.0).clamp(0.0, 1.0);

    final rowicon =    output.icon;
    final iconScale =  output.iconScale ?? 1.0;
    final rowname =    output.name;
    final rowcolor =   output.color;

    final boxes = [
      for (final fsrc in output.sources.whereType<MixerFxSource>())
        OutBox(
          "FX${fsrc.name}",
          fsrc.color,
          fsrc.enabled,
          () { fsrc.toggleEnabled(); },
        ),
    ];
    final mute = OutBox(
      output.muted ? "Muted" : "Mute",
      HexColor.fromHex("#ff4040"),
      output.muted,
      () {
        output.toggleMute();
      },
    );

    return Row(spacing: 2, children: [
      if (rowicon != null)
        Padding(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: SvgPicture.asset(
                "icons/$rowicon",
                height: 30 * iconScale,
                colorFilter: ColorFilter.mode(
                  rowcolor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      Expanded(
        child: Text(
          rowname,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: rowcolor,
          ),
          textAlign: TextAlign.left,
        ),
      ),
      Row(spacing: 2, children: [for (final o in boxes) o.build()]),
      SizedBox(width: 4),
      mute.build(),
      SizedBox(width: 4),
      SizedBox(
        width: 280,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            output.changeLevel(by: details.delta.dx / 40.0);
          },
          child: SizedBox(
            height: 30,
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(alignment: Alignment.centerLeft, children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: output.color,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 1,
                  bottom: 1,
                  left: 1,
                  right: 1 + ((constraints.maxWidth - 4) * (1.0 - pct)),
                  child: Container(
                    color: output.color.addLightness(-0.2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    "${output.level == -144.0 ? "-∞" : output.level.toStringAsFixed(1)} dB",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    ]);
  }
}
