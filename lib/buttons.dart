import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mixer_io.dart';
import 'let.dart';

class SourceTile extends StatefulWidget {
  const SourceTile({super.key, required this.source, this.onLongPress});
  final MixerSource source;

  final Function? onLongPress;

  @override
  State<SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  double delta = 0.0;

  Widget buildTileInside() {
    if (widget.source is MixerInputSource) {
      return buildInputTile(widget.source as MixerInputSource);
    } else {
      return buildFxTile(widget.source as MixerFxSource);
    }
  }

  buildFxTile(MixerFxSource fxsrc) {
    return SizedBox(
      height: 50,
      child: Column(children: [
        Row(children: [
          if (fxsrc.icon != null)
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: SvgPicture.asset(
                    "icons/${fxsrc.icon!}",
                    height: 30 * (fxsrc.iconScale ?? 1.0),
                    colorFilter: ColorFilter.mode(
                      fxsrc.enabled ? Colors.black : fxsrc.color,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              fxsrc.name,
              style: TextStyle(
                fontSize: 25,
                color: fxsrc.enabled ? Colors.black : fxsrc.color,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ]),
      ]),
    );
  }

  List<MixerFx> whichFx(MixerInput input) {
    List<MixerFx> ret = [];
    for (final fx in mixerFxs) {
      for (final src in fx.sources) {
        if (src.enabled && src is MixerInputSource && src.input == input) {
          ret.add(fx);
        }
      }
    }
    return ret;
  }

  buildInputTile(MixerInputSource isrc) {
    double pct = (((isrc.level == -144.0 ? -90.0 : isrc.level) + 90.0) / 100.0).clamp(0.0, 1.0);
    final fx = whichFx(isrc.input);

    return SizedBox(
      height: 100,
      child: Column(children: [
        Row(children: [
          if (isrc.icon != null)
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: SvgPicture.asset(
                    "icons/${isrc.icon!}",
                    height: 30 * (isrc.iconScale ?? 1.0),
                    colorFilter: ColorFilter.mode(
                      isrc.enabled ? Colors.black : isrc.color,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              isrc.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isrc.enabled ? Colors.black : isrc.color,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ]),
        Expanded(child: Container()),
        Row(
        crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                "${isrc.level == -144.0 ? "-∞" : isrc.level.toStringAsFixed(1)} dB",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isrc.enabled ? Colors.black : isrc.color,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            if (fx.isNotEmpty) ...[
              Expanded(child: Container()),
              Padding(
                padding: EdgeInsets.only(left: 12, right: 12, bottom: 2),
                child: Row(
                spacing: 4,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: SvgPicture.asset(
                          "icons/fx.svg",
                          height: 26,
                          colorFilter: ColorFilter.mode(
                            isrc.enabled ? Colors.black : isrc.color,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    for (final fx in fx)
                      Text(
                        fx.name,
                        style: TextStyle(
                          fontSize: 22,
                          color: isrc.enabled ? Colors.black : isrc.color,
                        ),
                      ),
                  ]),
              ),
            ],
          ],
        ),
        SizedBox(
          height: 7,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: constraints.maxWidth * pct,
                child: Container(
                  color: isrc.enabled ? isrc.color.addLightness(0.4) : isrc.color.addLightness(-0.3),
                ),
              ),
            ]),
          ),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: widget.source.enabled ? widget.source.color : Colors.black,
          border: Border.all(
            color: widget.source.enabled ? widget.source.color : widget.source.color.addLightness(-0.3),
            width: 2,
          ),
        ),
        child: buildTileInside(),
      ),
      onHorizontalDragStart: (details) {
        delta = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        delta += details.primaryDelta!;
        if (widget.source is MixerInputSource) {
            MixerInputSource isrc = widget.source as MixerInputSource;
            isrc.changeLevel(details.primaryDelta!/20);
        }
      },
      onTap: () {
        widget.source.toggleEnabled();
      },
      onLongPress: () {
        widget.onLongPress?.call();
      },
    );
  }
}
