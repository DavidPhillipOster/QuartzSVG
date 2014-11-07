QuartzSVG
=========

A Mac program that draws with Quartz to the screen, while writing an equivalent SVG file to the console.

To use:
Subclass from CutView. 

In your subclass, add a drawRect.

Draw, using the wrapper for CGGraphicContext defined by BezierPath.h and GraphicsContext.h

At runtime, the app finds all the subclasses and shows them in a sorted list.

When run from Xcode, Xcode's log window shows the SVG commands.

I use this program to generate SVG for importing into InkScape to drawing with a watercolorbot or eggbot,
or cutting with SureCutsALot and a USB paper cutter.

Apache license
