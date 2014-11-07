//  CutViewBase.m
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

typedef void(^BezierPathFunc)(BezierPath *);

@interface CutViewBase : CutView
@end

@implementation CutViewBase

- (void)drawRect:(NSRect)dirtyRect {
  NSRect bounds = [self bounds];
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext openSVG];
  [currentContext setColor:[NSColor blackColor]];
  NSRect frame = NSInsetRect(bounds, bounds.size.width*0.1, bounds.size.height*0.1);
  frame.size.width = frame.size.height = MIN(frame.size.width, frame.size.height);
//  [self drawRectangle:frame];
//  [self draw4Star:frame radius:frame.size.width/4.];
  [self drawDentedRect:frame radius:frame.size.width/4.];
//  [self pinkingFrame:frame];
//  [self drawRadialSymmetry:frame];
//  [self drawFrame:frame radius:frame.size.width/4.];
  [currentContext closeSVG];
}

// Draw 4 symmetric edges.
- (void)drawSymmetryRectangle:(NSRect)r {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  NSPoint center = CGPointMake(x + w/2, y + h/2);
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  NSMutableArray *edge = [NSMutableArray array];
  [edge addObject:[NSValue valueWithPoint:NSMakePoint(x, y)]];
  [edge addObject:[NSValue valueWithPoint:NSMakePoint(x+w, y)]];
  static const int kNumSides = 4;
  for (int i = 0; i < kNumSides; ++i) {
    NSUInteger count = [edge count];

    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:center.x yBy:center.y];
    float theta = 2*M_PI/(float)kNumSides;
    [t rotateByRadians:theta*i];
    [t translateXBy:-center.x yBy:-center.y];

    for (NSUInteger j = 0; j < count; ++j) {
      NSPoint p = [(NSValue *)edge[j] pointValue];
      p = [t transformPoint:p];
      if (0 == j) {
        [path moveToPoint:p];
      } else {
        [path lineToPoint:p];
      }
    }
    [path stroke];
  }
}

- (void)drawRectangle:(NSRect)r {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  [self draw4Symmetry:^(BezierPath *p){
        [p moveToPoint:NSMakePoint(x, y)];
        [p lineToPoint:NSMakePoint(x+w, y)];
      }
               center:CGPointMake(x + w/2, y + h/2)];
}

- (void)draw4Star:(NSRect)r radius:(CGFloat)radius {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  [self draw4Symmetry:^(BezierPath *p){
        [p moveToPoint:NSMakePoint(x, y)];
        [p lineToPoint:NSMakePoint(x+w/2, y+radius)];
        [p lineToPoint:NSMakePoint(x+w, y)];
      }
               center:CGPointMake(x + w/2, y + h/2)];
}

// todo: the location of the 'shoulders' of the inset triangle are not functions of the radius.
// they could be, to force tight angle triangle cuts.
- (void)drawDentedRect:(NSRect)r radius:(CGFloat)radius {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  [self draw4Symmetry:^(BezierPath *p){
        [p moveToPoint:NSMakePoint(x, y)];
        [p lineToPoint:NSMakePoint(x+w/4, y)];
        [p styledLineToPoint:NSMakePoint(x+w/2, y+radius)];
        [p styledLineToPoint:NSMakePoint(x+3*w/4, y)];
        [p lineToPoint:NSMakePoint(x+w, y)];
      }
               center:CGPointMake(x + w/2, y + h/2)];
}

- (void)drawFrame:(NSRect)r radius:(CGFloat)radius {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  NSPoint center = CGPointMake(x + w/2, y + h/2);
  NSRect innerR = NSZeroRect;
  innerR.origin = center;
  innerR = NSInsetRect(innerR, radius, radius);
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  [currentContext openGroupNamed:@"center"];
  [currentContext setColor:[NSColor redColor]];
  [path moveToPoint:innerR.origin];
  [path styledLineToPoint:center];
  [path stroke];
  [path moveToPoint:center];
  [path styledLineToPoint:NSMakePoint(innerR.origin.x+innerR.size.width, innerR.origin.y+innerR.size.height)];
  [path stroke];
  [path moveToPoint:NSMakePoint(innerR.origin.x, innerR.origin.y+innerR.size.height)];
  [path styledLineToPoint:center];
  [path stroke];
  [path moveToPoint:center];
  [path styledLineToPoint:NSMakePoint(innerR.origin.x+innerR.size.width, innerR.origin.y)];
  [path stroke];
  [currentContext closeGroup];
  [currentContext openGroupNamed:@"frame"];
  [currentContext setColor:[NSColor blackColor]];
  [self drawDentedRect:r radius:radius];
  [currentContext closeGroup];
}

// Draw 4 symmetric edges.
- (void)draw4Symmetry:(BezierPathFunc)func center:(NSPoint)center {
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  static const int kNumSides = 4;
  for (int i = 0; i < kNumSides; ++i) {
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:center.x yBy:center.y];
    float theta = 2.*M_PI/(float)kNumSides;
    [t rotateByRadians:theta*i];
    [t translateXBy:-center.x yBy:-center.y];
    [currentContext saveGraphicsState];
    [currentContext concat:t];
    func(path);
    [path stroke];
    [currentContext restoreGraphicsState];
  }
}


- (void)drawSimpleRectangle:(NSRect)r {
  CGFloat x = r.origin.x;
  CGFloat y = r.origin.y;
  CGFloat w = r.size.width;
  CGFloat h = r.size.height;
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  [path moveToPoint:NSMakePoint(x, y)];
  [path lineToPoint:NSMakePoint(x+w, y)];
  [path lineToPoint:NSMakePoint(x+w, y+h)];
  [path lineToPoint:NSMakePoint(x, y+h)];
  [path lineToPoint:NSMakePoint(x, y)];
  [path stroke];
}

// Draw a 4 pointed star inside rect, with radius =radius of the inner 4 points.
- (void)drawSimple4Star:(NSRect)rect radius:(CGFloat)radius {
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat w = rect.size.width;
  CGFloat h = rect.size.height;
  NSPoint center = CGPointMake(x + w/2, y + h/2);
  NSPoint u = CGPointMake(center.x, center.y - radius);
  NSPoint r = CGPointMake(center.x + radius, center.y);
  NSPoint d = CGPointMake(center.x, center.y + radius);
  NSPoint l = CGPointMake(center.x - radius, center.y);

  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  [path moveToPoint:NSMakePoint(x, y)];
  [path lineToPoint:u];
  [path lineToPoint:NSMakePoint(x+w, y)];
  [path lineToPoint:r];
  [path lineToPoint:NSMakePoint(x+w, y+h)];
  [path lineToPoint:d];
  [path lineToPoint:NSMakePoint(x, y+h)];
  [path lineToPoint:l];
  [path lineToPoint:NSMakePoint(x, y)];
  [path stroke];
}


- (void)drawRadialSymmetry:(NSRect)bounds {
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext saveGraphicsState];
  NSAffineTransform *t = [NSAffineTransform transform];
  [t translateXBy:bounds.size.width/2 yBy:bounds.size.height/2];
  [currentContext concat:t];
  // any integer, 2 .. n works here
  [self drawWedges:9 radius:bounds.size.width/2];
  [currentContext restoreGraphicsState];
}

// Draw |count| wedges, that fill a circle.
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


- (void)pinkingFrame:(NSRect)r {
  GraphicsContext *currentContext = [GraphicsContext currentContext];
  BezierPath *path = [currentContext bezierPath];
  [path setLineWidth:1];
  [path moveToPoint:NSMakePoint(r.origin.x, r.origin.y)];
  [path styledLineToPoint:NSMakePoint(r.origin.x+r.size.width, r.origin.y)];
  [path stroke];
}

@end
