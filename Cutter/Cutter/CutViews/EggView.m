//  EggView.m
//  EggArt
//
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

@interface EggView : CutView
@end

@implementation EggView

- (void)drawRect:(NSRect)dirtyRect {
  NSRect bounds = [self bounds];
  NSRect frame = NSInsetRect(bounds, bounds.size.width/3, bounds.size.height/3);
  frame.origin.x = 0;
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  for (int i = 0; i < 3; i++) {
    [currentContext saveGraphicsState];
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:i*bounds.size.width/3 yBy:bounds.size.height/3];
    [currentContext concat:t];
    [self drawRadialSymmetry:frame];
    [currentContext restoreGraphicsState];
  }
}

- (void)drawRadialSymmetry:(NSRect)bounds {
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext saveGraphicsState];
  NSAffineTransform *t = [NSAffineTransform transform];
  [t translateXBy:bounds.size.width/2 yBy:bounds.size.height/2];
  [currentContext concat:t];
  // any integer, 2 .. n works here
  [self drawWedges:19 radius:bounds.size.width/2];
  [currentContext restoreGraphicsState];
}

// Draww count wedges, that fill a circle.
-(void)drawWedges:(int)count radius:(float)radius {
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext setColor:[NSColor blackColor]];
  for (int i = 0; i < count; ++i) {
    [currentContext saveGraphicsState];
    NSAffineTransform *t = [NSAffineTransform transform];
    float theta = 2*M_PI/(float)count;
    [t rotateByRadians:theta*i];
    [currentContext concat:t];
    [self drawWedgeTheta:theta radius:radius];
    [currentContext restoreGraphicsState];
  }
}


- (void)drawWedgeTheta:(float)theta radius:(float)radius {
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  // draw a line along the edge of the wedge
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  [path moveToPoint:NSMakePoint(0, 3)];

  [path curveToPoint:NSMakePoint(radius * sin(theta), radius * cos(theta))
        controlPoint1:NSMakePoint(radius * sin(theta/2), radius * cos(theta/2))
        controlPoint2:NSMakePoint(radius * sin(theta/2), radius * cos(theta/2))];
  [path curveToPoint:NSMakePoint(0, 3)
        controlPoint1:NSMakePoint(radius * sin(theta*3.0/2), radius * cos(theta*3.0/2))
        controlPoint2:NSMakePoint(radius * sin(theta*3.0/2), radius * cos(theta*3.0/2))];
  [path stroke];

  path = [currentContext bezierPath];
  [path moveToPoint:NSMakePoint(0, 3)];
  [path lineToPoint:NSMakePoint(0, radius)];
  [path stroke];

  // draw two inverted Vs in the wedge.
  for (int j = 1 ; j <= 2 ;++j) {
    path =[currentContext bezierPath];
    [path setLineWidth:1];
    float base = radius * j * 2.0/8.0;
    float tip = radius * j * 3.0/8.0;
    [path moveToPoint:NSMakePoint(0, base)];
    [path lineToPoint:NSMakePoint(tip * sin(theta/2.), tip * cos(theta/2.))];
    [path lineToPoint:NSMakePoint(base * sin(theta), base * cos(theta))];
    [path stroke];
  }
}


@end
