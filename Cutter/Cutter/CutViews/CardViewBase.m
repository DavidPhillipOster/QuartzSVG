//  CutView.m
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 11/16/13.
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


@interface CardViewBase : CutView
@end

@implementation CardViewBase

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
  [self drawParallelCuts:frame];
  [self drawRectangle:frame];
//  [self draw4Star:frame radius:frame.size.width/4.];
//  [self drawDentedRect:frame radius:frame.size.width/4.];
//  [self pinkingFrame:frame];
//  [self drawRadialSymmetry:frame];
//  [self drawFrame:frame radius:frame.size.width/4.];
  [currentContext closeSVG];
}

- (void)drawRectangle:(CGRect)r {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *p = [currentContext bezierPath];
  [p moveToPoint:NSMakePoint(x, y)];
  [p lineToPoint:NSMakePoint(x+w, y)];
  [p lineToPoint:NSMakePoint(x+w, y+h)];
  [p lineToPoint:NSMakePoint(x, y+h)];
  [p lineToPoint:NSMakePoint(x, y)];
  [p stroke];
}

- (void)drawParallelCuts:(CGRect)r {
  CGRect left, right;
  CGRectDivide(r, &left, &right, r.size.width/3, CGRectMinXEdge);
  CGFloat kCutSpacingY = 8;
  CGFloat kCutSpacingX = 1.25*kCutSpacingY*r.size.height/r.size.width;
  CGFloat x = ceilf(right.origin.x - r.size.width/3);
  CGFloat y = ceilf(right.origin.y);
  CGFloat w = floorf(right.size.width);
  CGFloat h = floorf(right.size.height);
  BPath *p = [BPath bpath];
  CGFloat j = y;
  for (;j < y+h/3; j += kCutSpacingY, w += kCutSpacingX) {
    [p line2P:NSMakePoint(x, j) p:NSMakePoint(x+w, j)];
  }
  for (;j < y+2*h/3; j += kCutSpacingY, x += kCutSpacingX) {
    [p line2P:NSMakePoint(x, j) p:NSMakePoint(x+w, j)];
  }
  for (;j < y+h; j += kCutSpacingY, w -= kCutSpacingX, x += kCutSpacingX) {
    [p line2P:NSMakePoint(x, j) p:NSMakePoint(x+w, j)];
  }
}

@end
