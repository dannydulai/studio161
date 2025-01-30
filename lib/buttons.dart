import 'package:flutter/material.dart';
import 'let.dart';

class ClickDragButton extends StatefulWidget {
  const ClickDragButton({super.key, required this.name, required this.color, required this.level, required this.enabled, this.onTap, this.onDrag, this.onLongPress, this.width, this.height});
  final String name;
  final Color color;
  final double level;

  final bool enabled;
  final double? width;
  final double? height;

  final Function? onTap;
  final Function? onLongPress;
  final Function(double)? onDrag;

  @override
  State<ClickDragButton> createState() => _ClickDragButtonState();
}

class _ClickDragButtonState extends State<ClickDragButton> {
  double delta = 0.0;

  Widget inside(double width) {
    double pct = (((widget.level == -144.0 ? -90.0 : widget.level) + 90.0) / 100.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 2),
            child: Stack(
            fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  right: 4,
                  child: Text(
                    "-",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.enabled ? Colors.black : widget.color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.enabled ? Colors.black : widget.color,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Expanded(child: Container()),
                    Text(
                      "${widget.level == -144.0 ? "-∞" : widget.level.toStringAsFixed(1)} dB",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.enabled ? Colors.black : widget.color,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 7,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: width * pct,
                child: Container(
                  color: widget.enabled ? widget.color.addLightness(0.4) : widget.color.addLightness(-0.3),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: widget.enabled ? widget.color : Colors.black,
          border: Border.all(
            color: widget.enabled ? widget.color : widget.color.addLightness(-0.3),
            width: 2,
          ),
        ),
        height: widget.height ?? 70,
        width: widget.width ?? 210,
        child: inside(widget.width ?? 210),
      ),
      onHorizontalDragStart: (details) {
        delta = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        delta += details.primaryDelta!;
        widget.onDrag?.call(details.primaryDelta!/20);
      },
      onTap: () {
        widget.onTap?.call();
      },
      onLongPress: () {
        widget.onLongPress?.call();
      },
    );
  }
}
