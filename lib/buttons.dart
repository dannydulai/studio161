import "dart:io";
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'let.dart';
import 'main.dart';

class SourceTile extends StatefulWidget {
  const SourceTile({super.key, required this.source, required this.onLongPress});
  final MixerOutputSource source;

  final double width = 220;
  final double height = 110;

  final Function onLongPress;

  @override
  State<SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  double delta = 0.0;

  Widget inside(double width) {
    double pct = (((widget.source.level == -144.0 ? -90.0 : widget.source.level) + 90.0) / 100.0).clamp(0.0, 1.0);

    return Column(children: [
      Row(children: [
        if (widget.source.input.icon != null)
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
            child: SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: SvgPicture.file(
                  File(widget.source.input.icon!),
                  height: 30 * (widget.source.input.iconScale ?? 1.0),
                  colorFilter: ColorFilter.mode(
                    widget.source.enabled ? Colors.black : widget.source.input.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: Text(
            widget.source.input.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: widget.source.enabled ? Colors.black : widget.source.input.color,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ]),
      Expanded(child: Container()),
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              "${widget.source.level == -144.0 ? "-∞" : widget.source.level.toStringAsFixed(1)} dB",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.source.enabled ? Colors.black : widget.source.input.color,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          if (widget.source.fx != 0)
            Expanded(
                child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                    "FX ${widget.source.fx}",
                    style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: widget.source.enabled ? Colors.black : widget.source.input.color,
                    ),
                    textAlign: TextAlign.right,
                ),
                ),
            ),
        ],
      ),
      SizedBox(
        height: 7,
        child: Stack(children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: width * pct,
            child: Container(
              color: widget.source.enabled
                  ? widget.source.input.color.addLightness(0.4)
                  : widget.source.input.color.addLightness(-0.3),
            ),
          ),
        ]),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: widget.source.enabled ? widget.source.input.color : Colors.black,
          border: Border.all(
            color: widget.source.enabled ? widget.source.input.color : widget.source.input.color.addLightness(-0.3),
            width: 2,
          ),
        ),
        height: widget.height,
        width: widget.width,
        child: inside(widget.width),
      ),
      onHorizontalDragStart: (details) {
        delta = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        delta += details.primaryDelta!;
        widget.source.changeLevel(details.primaryDelta!/20);
      },
      onTap: () {
        widget.source.toggleEnabled();
      },
      onLongPress: () {
        widget.onLongPress();
      },
    );
  }
}
