//  HarvardView.m
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

// TODO: I did the central 'galaxy' and a star function, still need master to do the global layout

#import "CutView.h"
#import <AppKit/AppKit.h>
#import "BezierPath.h"
#import "GraphicsContext.h"
#import "Utils.h"

@interface HarvardView : CutView
@end

@implementation HarvardView

- (void)drawRect:(NSRect)dirtyRect {
  static CGFloat kAspectRatio = 4.0/6.0;
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
  frame.size.height = frame.size.width = MIN(frame.size.height, frame.size.width);
  [self drawStar:frame];
//  [self drawRectangle:frame];
//  [self nestedEllipses:frame];

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

- (void)drawStar:(CGRect)r {
  [self drawStar:r numPoints:6];
}

- (void)drawStar:(CGRect)r numPoints:(int)numPoints {
  float radius = r.size.width/2;
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext saveGraphicsState];
  NSAffineTransform *t = [NSAffineTransform transform];
  [t translateXBy:(r.origin.x+r.size.width/2) yBy:(r.origin.y+r.size.height/2)];
  [currentContext concat:t];
  NSMutableArray *endPoints = [NSMutableArray array];
  // Draw spine, collect endpoints. (center is zero)
  for (int i = 0; i < numPoints; ++i) {
    BezierPath *p = [currentContext bezierPath];
    [p moveToPoint:CGPointZero];
    t = [NSAffineTransform transform];
    [t rotateByRadians:i*(360.0/numPoints)*(2*M_PI/360.)];
    NSPoint p1 = CGPointMake(radius, 0);
    NSPoint pTransformed = [t transformPoint:p1];
    [endPoints addObject:[NSValue valueWithPoint:pTransformed]];
    [p lineToPoint:pTransformed];
    [p stroke];
  }
  for (int i = 0; i < numPoints; ++i) {
    int startIndex = i - 1;
    if (startIndex < 0) {
      startIndex += numPoints;
    }
    NSPoint pArmStart = [endPoints[startIndex] pointValue];
    NSPoint pArmEnd = [endPoints[i] pointValue];
    for (int j = 1; j < 11; ++j) {
      float ratio = j / 12.0;
      float inverseRatio = (11 - j) / 12.0;
      BPath *p = [BPath bpath];
      [p moveToPoint:CGPointMake(pArmStart.x*ratio, pArmStart.y*ratio)];
      [p lineToPoint:CGPointMake(pArmEnd.x*inverseRatio, pArmEnd.y*inverseRatio)];
      [p stroke];
    }
  }
  [currentContext restoreGraphicsState];
}

- (void)nestedEllipses:(CGRect)r {
  static float kAngleNumDivisions = 2048;
  static int kNumEllipses = 40;
  static float kShrinkFactor = 1.0/120.0;
  GraphicsContext *currentContext = [GraphicsContext currentContext];

  NSAffineTransform *t = [NSAffineTransform transform];
  [t translateXBy:(r.origin.x+r.size.width/2) yBy:(r.origin.y+r.size.height/2)];
  [t rotateByRadians:-30.0*(2*M_PI/360.)];
  [t translateXBy:-(r.origin.x+r.size.width/2) yBy:-(r.origin.y+r.size.height/2)];
  [currentContext concat:t];

  float theta = 2*M_PI/kAngleNumDivisions;
  for (int i = 0; i < kNumEllipses; ++i) {
    BezierPath *p = [currentContext bezierPath];
    [currentContext saveGraphicsState];
    r = CGRectInset(r, r.size.width*kShrinkFactor, r.size.height*kShrinkFactor);
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:(r.origin.x+r.size.width/2) yBy:(r.origin.y+r.size.height/2)];
    [t rotateByRadians:theta*i];
    [t translateXBy:-(r.origin.x+r.size.width/2) yBy:-(r.origin.y+r.size.height/2)];
    [currentContext concat:t];
    [p appendBezierPathWithOvalInRect:r];
    [p stroke];
  }
  [currentContext restoreGraphicsState];
}


@end
