//  Arch2View.m
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 2/01/2014
//  Copyright (c) 2014 David Phillip Oster.
//  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

//

#import "CutView.h"
#import <AppKit/AppKit.h>
#import "BezierPath.h"
#import "GraphicsContext.h"
#import "Utils.h"

// Arch2View - In SureCutsAlot, it's difficult to make a primitive that is a roman arch:
// a line, leading to a half circle to a line. Here, the line extensions are equal to the radius.
// in the GUI editor I sure, SureCutsALot, it's easy to resize to get the half circle the correct
// size, and then extend the the lines to get the correct proportions.
@interface Arch2View : CutView
@end

@implementation Arch2View

- (void)drawRect:(NSRect)dirtyRect {
  static CGFloat kAspectRatio = 5.0/8.0;
  CGRect bounds = [self bounds];

  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext openSVG];
  [currentContext setColor:[NSColor blackColor]];
  CGRect frame = NSInsetRect(bounds, bounds.size.width*0.1, bounds.size.height*0.1);
  frame.size.width = frame.size.height = 8*72;
  CGRect portraitFrame = FrameToFit(frame, 1/kAspectRatio);
  CGRect landscapeFrame = FrameToFit(frame, kAspectRatio);
  if (RectArea(frame) - RectArea(portraitFrame) < RectArea(frame) - RectArea(landscapeFrame)) {
    frame = portraitFrame;
  } else {
    frame = landscapeFrame;
  }
  [self drawArch:frame];

  [currentContext closeSVG];
}

- (void)drawArch:(CGRect)r {
  CGFloat h = r.size.height;
  CGFloat x = r.origin.x + r.size.width - h;
  CGFloat y = r.origin.y;
//  CGFloat w = r.size.width;
  CGPoint center = CGPointMake(x, y+h/2);
  [self drawArchCircleCenter:center radius:h/2];
}

- (void)drawArchCircleCenter:(CGPoint)center radius:(CGFloat)radius {
  BPath *p = [BPath bpath];
  [p moveToPoint:CGPointMake(center.x - radius, center.y-radius)];
  [p appendBezierPathWithArcWithCenter:center radius:radius startAngle:-180 endAngle:0 clockwise:YES];
  [p lineToPoint:CGPointMake(center.x + radius, center.y-radius)];
  [p stroke];
}


@end
