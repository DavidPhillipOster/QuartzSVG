//  CircularConstruction1View.m
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

@interface CircularConstruction1View : CutView
@end

@implementation CircularConstruction1View

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
//  [self drawRectangle:frame];
  [self drawCircle:frame];

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

- (void)drawCircle:(CGRect)r {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
//  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  CGPoint center = CGPointMake(x, y+h/2);
  [self drawCircleCenter:center radius:h/2];
}

- (void)drawCircleCenter:(CGPoint)center radius:(CGFloat)radius {
  [self drawNGonCenter:center radius:radius sides:30];
}

- (void)drawNGonCenter:(CGPoint)center radius:(CGFloat)radius sides:(int)sides {
  BPath *p = [BPath bpath];
  int x1 = sides/3;
  int x2 = (2*sides)/3;
  for (int i = 0; i < sides; ++i) {
    CGFloat theta = M_PI*(i/(float)(sides-1));
    CGFloat x = center.x + sin(theta)*radius;
    CGFloat y = center.y + cos(theta)*radius;
    if (i == x1) {
      [p lineToPoint:CGPointMake(x, y)];
      [p lineToPoint:CGPointMake(center.x, y)];
    } else if (i == x1+1) {
      [p stroke];
      [p moveToPoint:CGPointMake(center.x, y)];
      [p lineToPoint:CGPointMake(x, y)];
    } else if (i == x2) {
      [p lineToPoint:CGPointMake(x, y)];
      [p lineToPoint:CGPointMake(center.x, y)];
    } else if (i == x2+1) {
      [p stroke];
      [p moveToPoint:CGPointMake(center.x, y)];
      [p lineToPoint:CGPointMake(x, y)];
    } else if (i) {
      [p lineToPoint:CGPointMake(x, y)];
    } else {
      [p moveToPoint:CGPointMake(x, y)];
    }
  }
  [p stroke];
}

- (void)drawParallelCuts:(CGRect)r {
  CGRect left, right;
  CGRectDivide(r, &left, &right, r.size.width/3, CGRectMinXEdge);
  CGFloat kCutSpacingY = 16;
  CGFloat x = ceilf(right.origin.x - r.size.width/3);
  CGFloat y = ceilf(right.origin.y);
  CGFloat w = floorf(right.size.width)/2;
  CGFloat h = floorf(right.size.height);
  CGPoint center = CGPointMake(x, y+h/2);
  center.x += 50;
  CGFloat radius = (h+50)/2;
  BPath *p = [BPath bpath];
  CGFloat j = y;
  for (;j <= y+h; j += kCutSpacingY) {
    CGFloat theta = acos((j - center.y)/radius);
    CGFloat x = center.x + sin(theta)*radius;
    float lowx = x;
    float highx = x + w/2;
    [p line2P:NSMakePoint(lowx, j) p:NSMakePoint(highx, j)];
  }
}

@end
