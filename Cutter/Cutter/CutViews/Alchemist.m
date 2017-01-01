//  Alchemist.m
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 12/01/2016
//  Copyright (c) 2016 David Phillip Oster.
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
#import "GraphicsMath.h"
#import "GraphicsContext.h"
#import "Utils.h"

static int floatcompare(const void *a, const void *b) {
  CGFloat *af = (CGFloat *)a;
  CGFloat *bf = (CGFloat *)b;
  if (*af < *bf) {
    return -1;
  } else if (*bf < *af) {
    return 1;
  } else {
    return 0;
  }
}

CGRect CGCircleMake(CGPoint p, CGFloat radius) {
  CGRect r = CGRectMake(p.x, p.y, 0, 0);
  return CGRectInset(r, -radius, -radius);
}

void CGRectToCircle(CGRect r, CGPoint *outCenter, CGFloat *outRadius) {
  CGFloat radius = r.size.width/2;
  *outRadius = radius;
  *outCenter = CGPointMake(r.origin.x + radius, r.origin.y + radius);
}

// Given two circles that are known to intersect, write the two intersection points to outIntersections[0] and outIntersections[1]
static void IntersectCircleWithCircle(CGRect circleA, CGRect circleB, CGPoint *outIntersections) {
  CGPoint centerA;
  CGFloat radiusA;
  CGRectToCircle(circleA, &centerA, &radiusA);
  CGPoint centerB;
  CGFloat radiusB;
  CGRectToCircle(circleB, &centerB, &radiusB);
  CGFloat dx = centerA.x - centerB.x;
  CGFloat dy = centerA.y - centerB.y;
  CGFloat d = sqrt(dx*dx + dy*dy); // Distance between centers.
  if (radiusA + radiusB < d ||
    d < MAX(radiusA, radiusB)) {
    // Circles don't intersect.
    outIntersections[0] = CGPointMake(1.0e-11, 1.0e-11);
    outIntersections[1] = CGPointMake(1.0e-11, 1.0e-11);
  } else {
    // 'a' is the length of the line along radiusA to line made by connecting the intersection points.
    CGFloat a = (radiusA*radiusA - radiusB*radiusB + d*d ) / (2*d);
    CGFloat h = sqrt(radiusA*radiusA - a*a);
    //P2 = P0 + a ( P1 - P0 ) / d
    CGPoint p2 = centerA;
    p2.x += a * (centerB.x - centerA.x) /d;
    p2.y += a * (centerB.y - centerA.y) /d;
    outIntersections[0] = CGPointMake(p2.x + h*( centerB.y - centerA.y ) / d,
      p2.y - h*( centerB.x - centerA.x ) / d);
    outIntersections[1] = CGPointMake(p2.x - h*( centerB.y - centerA.y ) / d,
      p2.y + h*( centerB.x - centerA.x ) / d);
  }
}

// Given a big circles and array of circles that intersect it, write all the intersection points to outIntersections
static void IntersectCircleWithCircles(CGRect circleA, CGRect *circles, NSUInteger count, CGPoint *outIntersections) {
  for (NSUInteger i = 0; i < count; ++i) {
    IntersectCircleWithCircle(circleA, circles[i], &outIntersections[i*2]);
  }
}

// Given a circle and a start angle pt, add the arc, in increasing angle order, to the path.
static void AddArcToPathOnCircle(BPath *p, CGRect circleA, CGFloat angleA, CGFloat angleB) {
  CGPoint center;
  CGFloat radius;
  CGRectToCircle(circleA, &center, &radius);
  float sx = center.x + radius * cos(angleA * M_PI/180.);
  float sy = center.y + radius * sin(angleA * M_PI/180.);
  [p moveToPoint:CGPointMake(sx, sy)];
  [p appendBezierPathWithArcWithCenter:center radius:radius startAngle:angleA endAngle:angleB clockwise:NO];
}

static void IntersectionToAngle(CGRect circleA, CGPoint p, CGFloat *outAngle) {
  CGPoint center;
  CGFloat radius;
  CGRectToCircle(circleA, &center, &radius);
  *outAngle = atan2(p.y - center.y, p.x - center.x) * 180/M_PI;
}


static void IntersectionsToAngles(CGRect circleA, CGPoint *intersections, NSUInteger count,  CGFloat *outAngles) {
  for (NSUInteger i = 0; i < count; ++i) {
    IntersectionToAngle(circleA, intersections[i], &outAngles[i]);
  }
}



// Alchemist - Inspired by FullMetal Alchemist.
@interface Alchemist : CutView
@end

@implementation Alchemist

- (void)drawRect:(NSRect)dirtyRect {
  static CGFloat kAspectRatio = 1;
  CGRect bounds = [self bounds];

  GraphicsContext *currentContext = [GraphicsContext currentContext];
  [currentContext openSVG];
  [currentContext setColor:[NSColor blackColor]];
  CGRect frame = NSInsetRect(bounds, bounds.size.width*0.1, bounds.size.height*0.1);
  CGRect portraitFrame = FrameToFit(frame, 1/kAspectRatio);
  CGRect landscapeFrame = FrameToFit(frame, kAspectRatio);
  if (RectArea(frame) - RectArea(portraitFrame) < RectArea(frame) - RectArea(landscapeFrame)) {
    frame = portraitFrame;
  } else {
    frame = landscapeFrame;
  }
  [self drawAlchemist:frame];

  [currentContext closeSVG];
}

- (void)drawAlchemist:(CGRect)r {
  CGFloat h = MIN(r.size.height, r.size.width);
  CGFloat x = r.origin.x + h/2;
  CGFloat y = r.origin.y + h/2;
  CGPoint center = CGPointMake(x, y);
  [self drawArchCircleCenter:center radius:h/2];
}

- (void)drawArchCircleCenter:(CGPoint)center radius:(CGFloat)radius {
  BPath *p = [BPath bpath];
  CGRect r1, r2, r3;
  r3 = r2 = r1 = CGRectMake(center.x, center.y, 0, 0);
  r1 = CGRectInset(r1, -radius, -radius);
  r2 = CGRectInset(r2, -radius*0.8, -radius*0.8);
  r3 = CGRectInset(r3, -radius*0.2, -radius*0.2);
  [p appendBezierPathWithOvalInRect:r1];
  [p appendBezierPathWithOvalInRect:r3];
  [p stroke];
  // Hexagon
  CGPoint *v = [self computeMajorVertices:r1 numPoints:6];
  CGPoint *vInner = [self computeMajorVertices:r3 numPoints:6];
  p = [BPath bpath];
  [p moveToPoint:v[0]];
  for (int i = 1; i < 6; ++i) {
    [p lineToPoint:v[i]];
  }
  [p closePath];
  [p stroke];
  // triangle
  CGFloat smallRadius = radius*0.125;
  // Intersect with inner six lines, split, shorten
  NSMutableArray *triangleLines = [NSMutableArray array];
  [triangleLines addObject:[[LineSegment alloc] initWithStart:v[2] end:v[0]]];
  [triangleLines addObject:[[LineSegment alloc] initWithStart:v[2] end:v[4]]];
  [triangleLines addObject:[[LineSegment alloc] initWithStart:v[4] end:v[0]]];
  NSMutableArray *radialLines = [NSMutableArray array];
  for (int i = 0; i < 6; ++i) {
    [radialLines addObject:[[LineSegment alloc] initWithStart:v[i] end:vInner[i]]];
  }
  for (LineSegment *ls in triangleLines) {
    for (LineSegment *radialLine in radialLines) {
      CGPoint c;
      if ([ls intersectsMiddle:radialLine at:&c]) {
        LineSegment *ls1 = [[LineSegment alloc] initWithStart:ls.ls.start end:c];
        LineSegment *ls2 = [[LineSegment alloc] initWithStart:c end:ls.ls.end];
        [ls1 shortenEndBy:smallRadius];
        [ls2 shortenStartBy:smallRadius];
        [ls1 draw];
        [ls2 draw];
        break;
      }
    }
  }
  CGRect rSmall;
  // conecting lines
  for (int i = 0; i < 6; ++i) {
    if (0 == i) {
      CGFloat kRadius = 0.06;
      CGFloat kOffset = 0.25;
      CGPoint p1 = [self interpolateStart:v[i] end:vInner[i] fraction:kOffset-kRadius];
      CGPoint p2 = [self interpolateStart:v[i] end:vInner[i] fraction:kOffset];
      CGPoint p3 = [self interpolateStart:v[i] end:vInner[i] fraction:kOffset+kRadius];
      CGPoint p4 = [self interpolateStart:v[i] end:center fraction:0.4];
      CGPoint p5 = [self interpolateStart:v[i] end:center fraction:0.5];
      p = [BPath bpath];
      [p moveToPoint:v[i]];
      [p lineToPoint:p1];
      [p stroke];
      p = [BPath bpath];
      [p moveToPoint:p3];
      [p lineToPoint:p4];
      [p moveToPoint:p5];
      [p lineToPoint:vInner[i]];
      [p stroke];
      p = [BPath bpath];
      rSmall = CGRectInset(CGRectMake(p2.x, p2.y, 0, 0), p2.y-p1.y, p2.y-p1.y);
      [p appendBezierPathWithOvalInRect:rSmall];
      [p stroke];
    } else if (i & 1) {
      LineSegment *ls = radialLines[i];
      // Intersect with triangle, split, shorten, draw circle.
      CGPoint c;
      BOOL didDraw = NO;
      for (LineSegment *t in triangleLines) {
        if ([ls intersectsMiddle:t at:&c]) {
          LineSegment *ls1 = [[LineSegment alloc] initWithStart:v[i] end:c];
          [ls1 shortenEndBy:smallRadius];
          [ls1 draw];
          CGRect rMid = CGRectInset(CGRectMake(c.x, c.y, 0, 0), -smallRadius, -smallRadius);
          p = [BPath bpath];
          [p appendBezierPathWithOvalInRect:rMid];
          [p stroke];
          LineSegment *ls2 = [[LineSegment alloc] initWithStart:c end:vInner[i]];
          [ls2 shortenStartBy:smallRadius];
          [ls2 draw];
          didDraw = YES;
          break;
        }
      }
      if (!didDraw) {
        [ls draw];
      }
    } else {
      CGPoint p4 = [self interpolateStart:v[i] end:center fraction:0.4];
      CGPoint p5 = [self interpolateStart:v[i] end:center fraction:0.5];
      LineSegment *ls = radialLines[i];
      LineSegment *l1 = [[LineSegment alloc] initWithStart:ls.ls.start end:p4];
      [l1 draw];
      LineSegment *l2 = [[LineSegment alloc] initWithStart:p5 end:ls.ls.end];
      [l2 draw];
    }
  }

  // Double arcs at the even verticies of the hexagon,
  p = [BPath bpath];
  [p moveToPoint:[self interpolateStart:v[0] end:v[5] fraction:0.4]];
  [p appendBezierPathWithArcWithCenter:v[0] radius:radius*0.4 startAngle:-30 endAngle:-150 clockwise:YES];
  [p moveToPoint:[self interpolateStart:v[0] end:v[5] fraction:0.5]];
  [p appendBezierPathWithArcWithCenter:v[0] radius:radius*0.5 startAngle:-30 endAngle:-150 clockwise:YES];
  [p stroke];

  p = [BPath bpath];
  [p moveToPoint:[self interpolateStart:v[2] end:v[1] fraction:0.4]];
  [p appendBezierPathWithArcWithCenter:v[2] radius:radius*0.4 startAngle:90 endAngle:-30 clockwise:YES];
  [p moveToPoint:[self interpolateStart:v[2] end:v[1] fraction:0.5]];
  [p appendBezierPathWithArcWithCenter:v[2] radius:radius*0.5 startAngle:90 endAngle:-30 clockwise:YES];
  [p stroke];

  p = [BPath bpath];
  [p moveToPoint:[self interpolateStart:v[4] end:v[3] fraction:0.4]];
  [p appendBezierPathWithArcWithCenter:v[4] radius:radius*0.4 startAngle:210 endAngle:90 clockwise:YES];
  [p moveToPoint:[self interpolateStart:v[4] end:v[3] fraction:0.5]];
  [p appendBezierPathWithArcWithCenter:v[4] radius:radius*0.5 startAngle:210 endAngle:90 clockwise:YES];
  [p stroke];

  p = [BPath bpath];
// Replaced [p appendBezierPathWithOvalInRect:r2] by a series of arcs.
  CGRect circles[7];
  circles[0] = CGCircleMake(v[0], radius*0.4);
  circles[1] = CGCircleMake(v[0], radius*0.5);
  circles[2] = CGCircleMake(v[2], radius*0.4);
  circles[3] = CGCircleMake(v[2], radius*0.5);
  circles[4] = CGCircleMake(v[4], radius*0.4);
  circles[5] = CGCircleMake(v[4], radius*0.5);
  circles[6] = rSmall;
  CGPoint intersections[14];
  IntersectCircleWithCircles(r2, circles, 7, intersections);
  CGFloat angles[15];
  IntersectionsToAngles(r2, intersections, 14,  angles);
  qsort(angles, 14, sizeof(CGFloat), floatcompare);
  angles[14] = angles[0];
  for (int i = 1; i < 14; i += 2) {
    AddArcToPathOnCircle(p, r2, angles[i], angles[i+1]);
  }
  [p stroke];

  // TODO: 'alchemical' symbols in the innner circles around the outside.
  // ♀♂⎈⋇⁜
}



- (CGPoint)interpolateStart:(CGPoint)start end:(CGPoint)end fraction:(CGFloat)frac {
  CGPoint result;
  result.x = start.x*(1-frac) + end.x*(frac);
  result.y = start.y*(1-frac) + end.y*(frac);
  return result;
}


- (CGPoint *)computeMajorVertices:(CGRect)r numPoints:(int)numPoints {
  float radius = r.size.width/2;
  CGPoint center;
  center.x = r.origin.x + radius;
  center.y = r.origin.y + radius;
  CGPoint *majorVertices = (CGPoint *)malloc(sizeof(CGPoint) * numPoints);
  NSAffineTransform *t;
  for (int i = 0; i < numPoints; ++i) {
    t = [NSAffineTransform transform];
    [t translateXBy:center.x yBy:center.y];
    [t rotateByRadians:i*(360.0/numPoints)*(2*M_PI/360.)];
    CGPoint p = CGPointMake(0, radius);
    CGPoint pTransformed = [t transformPoint:p];
    majorVertices[i] = pTransformed;
  }
  return majorVertices;
}

@end
