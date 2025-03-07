import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mixer_io.dart';
import 'mixer.dart';
import 'let.dart';

class OutBox extends StatefulWidget {
  final double width;
  final double height;
  final String? icon;
  final double iconScale;
  final bool muted;
  final String name;
  final bool enabled;
  final String? volume;
  final double? rawVolume;
  final Color color;
  final Color color2;
  final Function() onTap;
  final Function(double)? onVolume;

  const OutBox({
    super.key,
    required this.width,
    required this.height,
    this.icon,
    this.iconScale = 1.0,
    required this.name,
    required this.color,
    required this.color2,
    required this.enabled,
    this.muted = false,
    this.volume,
    this.rawVolume,
    required this.onTap,
    this.onVolume,
  });

  @override
  State<OutBox> createState() => _OutBoxState();
}

class _OutBoxState extends State<OutBox> {
  bool dragging = false;
  double dragDelta = 0.0;
  double origVol = 0.0;

  @override
  build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (widget.onVolume == null)
          ? null
          : (details) {
              setState(() {
                dragging = true;
              });
              dragDelta = 0.0;
              origVol = widget.rawVolume ?? 0.0;
            },
      onHorizontalDragEnd: (widget.onVolume == null)
          ? null
          : (details) {
              setState(() {
                dragging = false;
              });
            },
      onHorizontalDragUpdate: (widget.onVolume == null)
          ? null
          : (details) {
              dragDelta += details.primaryDelta!;
              widget.onVolume!(origVol + dragDelta / 40.0);
            },
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.muted ? 0.2 : 1.0,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            // color: !widget.enabled ? Colors.black : widget.color.addLightness(-0.7),
            gradient: widget.enabled
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.addLightness(-0.1),
                      widget.color.addLightness(-0.3),
                      Colors.black,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : null,
            border: Border.all(color: widget.enabled ? widget.color : widget.color.addLightness(-0.3), width: 2),
          ),
          child: Stack(
            children: [
              Center(
                child: (widget.icon != null && !dragging)
                    ? SvgPicture.asset(
                        "icons/${widget.icon!}",
                        height: 36 * widget.iconScale,
                        colorFilter: ColorFilter.mode(
                          widget.color2,
                          BlendMode.srcIn,
                        ),
                      )
                    : Text(
                        widget.volume ?? "",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.color2,
                        ),
                      ),
              ),
              if (widget.rawVolume != null && widget.enabled) ...[
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  height: 5,
                  child: Row(spacing: 1, children: [
                    for (int i = 0; i < 20; i++)
                      Expanded(
                        child: Container(
                            color: (widget.rawVolume! < 0)
                                ? ((19 - i) * -0.5) > widget.rawVolume!
                                    ? Colors.red
                                    : null
                                : ((i) * 0.5) < widget.rawVolume!
                                    ? Colors.green
                                    : null),
                      )
                  ]),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class FxBox extends StatefulWidget {
  final double width;
  final String? icon;
  final double iconScale;
  final String name;
  final bool enabled;
  final String? volume;
  final double rawVolume;
  final Color color;
  final Color color2;
  final Function() onTap;
  final Function(double)? onVolume;

  const FxBox({
    super.key,
    required this.width,
    this.icon,
    this.iconScale = 1.0,
    required this.name,
    required this.color,
    required this.color2,
    required this.enabled,
    this.volume,
    required this.rawVolume,
    required this.onTap,
    this.onVolume,
  });

  @override
  State<FxBox> createState() => _FxBoxState();
}

class _FxBoxState extends State<FxBox> {
  bool dragging = false;
  double dragDelta = 0.0;
  double origVol = 0.0;

  @override
  build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (widget.onVolume == null)
          ? null
          : (details) {
              setState(() {
                dragging = true;
              });
              dragDelta = 0.0;
              origVol = widget.rawVolume;
            },
      onHorizontalDragEnd: (widget.onVolume == null)
          ? null
          : (details) {
              setState(() {
                dragging = false;
              });
            },
      onHorizontalDragUpdate: (widget.onVolume == null)
          ? null
          : (details) {
              dragDelta += details.primaryDelta!;
              widget.onVolume!(origVol + dragDelta / 40.0);
            },
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.width,
        height: widget.width,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: widget.width - 12,
                height: widget.width - 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  //color: widget.color2,
                  gradient: widget.enabled
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.color.addLightness(-0.1),
                            Colors.black,
                          ],
                          stops: [0.0, 1.0],
                        )
                      : null,
                  border: Border.all(color: widget.color, width: 2),
                ),
              ),
            ),
            if (widget.enabled) ...[
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(painter: CircleVolPainter(widget.rawVolume)),
              ),
              if (dragging) ...[
                Center(
                  child: Text(
                    widget.volume ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.color2,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class CircleVolPainter extends CustomPainter {
  final double volume;

  CircleVolPainter(this.volume);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = volume < 0 ? Colors.red : Colors.green
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    const pi = 3.1415926;
    const deg90 = 0.5 * pi;
    const deg360 = 2.0 * pi;

    for (int i = 0; i < 20; i++) {
      if (i * -0.5 > volume) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width - 4,
            height: size.height - 4,
          ),
          deg90 + deg360 * 0.05 * i,
          deg360 * 0.03,
          false,
          paint,
        );
      }
      if (i * 0.5 < volume) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width - 4,
            height: size.height - 4,
          ),
          deg90 + deg360 * -0.05 * i,
          deg360 * 0.03,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CircleVolPainter oldDelegate) {
    return oldDelegate.volume != volume;
  }
}

// class JustBox extends StatelessWidget {
//   final String name;
//   final bool enabled;
//   final Color color;
//   final Function() onTap;
//
//   const JustBox({
//     super.key,
//     required this.name,
//     required this.color,
//     required this.enabled,
//     required this.onTap,
//   });
//
//   @override
//   build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: onTap,
//       child: Container(
//         alignment: Alignment.center,
//         width: 60,
//         height: 30,
//         decoration: BoxDecoration(
//           color: !enabled ? Colors.black : color,
//           border: Border.all(color: color, width: 1),
//         ),
//         child: Text(
//           name,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: enabled ? Colors.black : color,
//           ),
//         ),
//       ),
//     );
//   }
// }

class InputRow extends StatelessWidget {
  const InputRow({super.key, required this.input, required this.mixer});

  final Mixer mixer;
  final MixerBase input;

  // Widget buildTileInside() {
  Map<String, MixerInputSource> whichFx(MixerInput input) {
    Map<String, MixerInputSource> ret = {};
    for (final o in mixer.fxs) {
      for (final src in o.sources) {
        if (src is MixerInputSource && src.input == input) {
          ret[o.id] = src;
        }
      }
    }
    return ret;
  }

  Map<String, MixerSource> whichO(MixerBase input) {
    Map<String, MixerSource> ret = {};
    for (final o in mixer.outputs) {
      for (final src in o.sources) {
        if (src is MixerInputSource && src.input == input) {
          ret[o.id] = src;
        } else if (src is MixerFxSource && src.fx == input) {
          ret[o.id] = src;
        }
      }
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    final rowicon =    input.icon;
    final iconScale =  input.iconScale ?? 1.0;
    final rowname =    input.name;
    final rowcolor =   input.color;

    final enO = whichO(input);
    final List<Widget> outs = [
      for (final o in mixer.outputs)
        Expanded(
          child: OutBox(
            width: 120,
            height: 70,
            icon: o.icon,
            iconScale: o.iconScale ?? 1.0,
            name: o.name,
            color: rowcolor,
            color2: o.color,
            enabled: enO[o.id]!.enabled,
            muted: o.muted,
            volume: (enO[o.id] is MixerInputSource)
                ? (enO[o.id] as MixerInputSource).level == -144.0 ? "-∞" : (enO[o.id] as MixerInputSource).level.toStringAsFixed(1)
                : null,
            rawVolume: (enO[o.id] is MixerInputSource)
                ? (enO[o.id] as MixerInputSource).level
                : null,
            onTap: () {
              enO[o.id]!.toggleEnabled(mixer);
            },
            onVolume: !enO[o.id]!.enabled || input is! MixerInput ? null : (vol) {
              if (enO[o.id] is MixerInputSource) {
                (enO[o.id] as MixerInputSource).setLevel(mixer, vol);
              }
            },
          ),
        ),
    ];

    late List<Widget> fxs;
    if (input is MixerInput) {
      final enFx = whichFx(input as MixerInput);
      fxs = [
        for (final o in mixer.fxs)
          FxBox(
            width: 50,
            name: "FX${o.name}",
            color: rowcolor,
            color2: enFx[o.id]!.output.color,
            enabled: enFx[o.id]!.enabled,
            volume: enFx[o.id]!.level == -144.0 ? "-∞" : enFx[o.id]!.level.toStringAsFixed(1),
            rawVolume: enFx[o.id]!.level,
            onTap: () {
              enFx[o.id]!.toggleEnabled(mixer);
            },
            onVolume: enFx[o.id]!.enabled ? (vol) {
              enFx[o.id]!.setLevel(mixer, vol);
            } : null,
          )
        ];
    } else {
        fxs = [ ];
    }

    return Row(spacing: 20, children: [
      SizedBox(
        width: 200,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: SvgPicture.asset(
                    "icons/$rowicon",
                    height: 40 * iconScale,
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
                  fontSize: input is MixerInput ? 20 : 25,
                  fontWeight: FontWeight.bold,
                  color: rowcolor,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(spacing: 5, children: outs),
      ),
      SizedBox(
        width: 200,
        child: Row(
          spacing: 0,
          children: fxs,
        ),
      ),
    ]);
  }
}
