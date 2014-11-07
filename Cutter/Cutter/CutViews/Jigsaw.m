//  Jigsaw.m
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

@interface BPath(Jigsaw)
- (void)verticalNotchToPoint:(NSPoint)p style:(unsigned char) style;
- (void)horizontalNotchToPoint:(NSPoint)p style:(unsigned char) style;
@end
@implementation BPath(Jigsaw)
- (void)verticalNotchToPoint:(NSPoint)p style:(unsigned char) style {
  [self notchToPoint:p style:style >> 2];
}

- (void)horizontalNotchToPoint:(NSPoint)p style:(unsigned char) style {
  [self notchToPoint:p style:style];
}

- (void)notchToPoint:(NSPoint)p style:(unsigned char) style {
  switch (style & 3) {
  case 0:
    [self notchLineToPoint:p up:NO];
    break;
  case 1:
    [self notchLineToPoint:p up:YES];
    break;
  case 2:
    [self crenellatedLineToPoint:p];
    break;
  case 3:
    [self pinkingLineToPoint:p];
    break;
  }
}

- (void)notchLineToPoint:(NSPoint)p up:(BOOL)isUp {
  CGPoint p1 = [self currentPoint];
  CGFloat dx = p.x - p1.x;
  CGFloat dy = p.y - p1.y;
  CGFloat length = sqrtf(dx*dx + dy*dy);
  NSAffineTransform *t = [NSAffineTransform transform];
  [t translateXBy:p1.x yBy:p1.y];
  [t rotateByRadians:atan2f(dy, dx)];
  p1 = CGPointZero;
  p1.x += length/3;
  [self lineToPoint:[t transformPoint:p1]];
  CGPoint p2 = p1;
  p2.x += length/6;
  if (isUp) {
    p2.y += length/6;
  } else {
    p2.y -= length/6;
  }
  [self lineToPoint:[t transformPoint:p2]];
  p1.x += length/3;
  [self lineToPoint:[t transformPoint:p1]];
  p1.x += length/3;
  [self lineToPoint:[t transformPoint:p1]];
}

@end

@interface Jigsaw : CutView
@end

@implementation Jigsaw

- (void)drawRect:(NSRect)dirtyRect {
  CGRect bounds = [self bounds];

  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext openSVG];
  [currentContext setColor:[NSColor blackColor]];
  CGRect frame = NSInsetRect(bounds, bounds.size.width*0.1, bounds.size.height*0.1);
   [self drawJigsaw:frame];
  [currentContext closeSVG];
}

- (void)drawJigsaw:(CGRect)frame {
  static int const kEdgeSize = 100;
  int xEdgeMax = 1+MAX(1, (int)(frame.size.width / kEdgeSize));
  int yEdgeMax = 1+MAX(1, (int)(frame.size.height / kEdgeSize));
  unsigned char **edges;
  edges = (unsigned char **)calloc(yEdgeMax, sizeof(unsigned char *));
  for (int j = 0; j < yEdgeMax; ++j) {
    edges[j] = (unsigned char *)calloc(xEdgeMax, sizeof(unsigned char));
  }
  for (int j = 0; j < yEdgeMax; ++j) {
    for (int i = 0; i < xEdgeMax; ++i) {
      edges[j][i] = j^i;
    }
  }
  for (int j = 0; j < yEdgeMax; ++j) {
    for (int i = 0; i < xEdgeMax; ++i) {
      BPath *path = [BPath bpath];
      [path moveToPoint:CGPointMake(i*kEdgeSize+frame.origin.x, (j+1)*kEdgeSize+frame.origin.y)];
      if (0 != i && i < xEdgeMax-1) {
        [path verticalNotchToPoint:CGPointMake(i*kEdgeSize+frame.origin.x, j*kEdgeSize+frame.origin.y) style:edges[j][i]];
      } else {
        [path lineToPoint:CGPointMake(i*kEdgeSize+frame.origin.x, j*kEdgeSize+frame.origin.y)];
      }
      if (i < xEdgeMax-1) {
        if (0 == j) {
          [path lineToPoint:CGPointMake((i+1)*kEdgeSize+frame.origin.x, j*kEdgeSize+frame.origin.y)];
        } else {
          [path horizontalNotchToPoint:CGPointMake((i+1)*kEdgeSize+frame.origin.x, j*kEdgeSize+frame.origin.y)  style:edges[j][i]];
        }
      }
      [path stroke];
    }
  }
  BPath *path = [BPath bpath];
  [path moveToPoint:CGPointMake(frame.origin.x, yEdgeMax*kEdgeSize+frame.origin.y)];
  [path lineToPoint:CGPointMake((xEdgeMax-1)*kEdgeSize+frame.origin.x, yEdgeMax*kEdgeSize+frame.origin.y)];
  [path stroke];
  for (int j = 0; j < yEdgeMax; ++j) {
    free(edges[j]);
  }
  free(edges);
}


@end
