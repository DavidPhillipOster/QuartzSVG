//  GraphicsMath.m
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 2/7/2016
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
//

#import "GraphicsMath.h"

#import "BezierPath.h"

static const float kTiny = 1.0e-6;

// floating equals.
BOOL feq(CGFloat a, CGFloat b) {
  return fabs(a - b) < kTiny;
}

CGFloat AngleInRadians1(CGPoint first, CGPoint center) {
  first.x -= center.x;
  first.y -= center.y;
  return atan2(first.y, first.x);
}

CGFloat AngleInRadians(CGPoint first, CGPoint center, CGPoint third) {
  CGFloat angle1 = AngleInRadians1(first, center);
  CGFloat angle2 = AngleInRadians1(third, center);
  return angle1 - angle2;
}

PolyLine *ComputeIntersections(NSArray* inputlines) {
  PolyLine *result = [[PolyLine alloc] init];
  int count = (int)[inputlines count];
  for (int i = 0; i < count-1; ++i) {
    LineSegment *a = inputlines[i];
    for (int j = i+1;j < count; ++j) {
      LineSegment *b = inputlines[j];
      CGPoint c;
      if (![a hasCommonEndPoint:b] && [a intersects:b at:&c]) {
        [result addPt:c];
      }
    }
  }
  return result;
}

NSArray *PolylinesJoiningEndpoints(NSArray *polylines) {
  NSMutableArray *result = [polylines mutableCopy];
  for (int s = (int)[result count] - 1;0 <= s; --s) {
    for (int e = (int)[result count] - 1; 0 <= e; --e) {
      if (s != e && s < result.count && e < result.count) {
        PolyLine *sp = result[s];
        PolyLine *ep = result[e];
        if (sp.count && ep.count && CGPointEqualToPoint(sp.pts[0], ep.pts[ep.count - 1])) {
          PolyLine *p = [ep copy];
          for (int i = 1;i < sp.count; ++i) {
            [p addPt:sp.pts[i]];
          }
          [result replaceObjectAtIndex:e withObject:p];
          [result removeObjectAtIndex:s];
        }
      }
    }
  }
  return result;
}


@implementation LineSegment

- (instancetype)initWithStart:(CGPoint)start end:(CGPoint)end {
  self = [super init];
  if (self) {
    LineSegmentStruct ls;
    ls.start = start;
    ls.end = end;
    self.ls = ls;
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  LineSegment *result = [[[self class] allocWithZone:zone] init];
  result.ls = self.ls;
  return result;
}

- (BOOL)isVertical {
  return feq(self.ls.start.x, self.ls.end.x);
}

// y = m*x + b : solve for m.
// Undefined for vertical lines.
- (CGFloat)m {
  return (self.ls.start.y - self.ls.end.y)/(self.ls.start.x - self.ls.end.x);
}

// y = m*x + b : solve for b.
- (CGFloat)b {
  return [self bFromM:self.m];
}

// y - m*x = b
- (CGFloat)bFromM:(CGFloat)m {
  return self.ls.start.y - self.ls.start.x*m;
}


- (NSString *)description {
  return [NSString stringWithFormat:@"LineSegment{%g,%g %g,%g}", _ls.start.x, _ls.start.y, _ls.end.x, _ls.end.y];
}

- (BOOL)hasCommonEndPoint:(LineSegment *)other {
  return CGPointEqualToPoint(self.ls.start, other.ls.start) || CGPointEqualToPoint(self.ls.start, other.ls.end) ||
    CGPointEqualToPoint(self.ls.end, other.ls.start) || CGPointEqualToPoint(self.ls.end, other.ls.end);
}

// true for any intersection.
- (BOOL)intersectsLine:(LineSegment *)other at:(CGPoint *)outP {
  BOOL doesIntersect = NO;
  if([self isVertical] && [other isVertical]) {
    if (feq(self.ls.start.x, other.ls.end.x)) {
      outP->x = self.ls.start.x;
      outP->y = (self.ls.start.y + self.ls.end.y + other.ls.start.y + other.ls.end.y)/4;
      return YES;
    }
    return NO;  // Both are vertical. Treat them as non-intersecting.
  } else if ([self isVertical]) {
    CGFloat x = self.ls.start.x;
    CGFloat y = other.m*x + other.b;
    *outP = CGPointMake(x, y);
    doesIntersect = YES;
  } else if([other isVertical]) {
    CGFloat x = other.ls.start.x;
    CGFloat y = self.m*x + self.b;
    *outP = CGPointMake(x, y);
    doesIntersect = YES;
  } else {
    CGFloat m1 = self.m;
    CGFloat m2 = other.m;
    CGFloat b1 = self.b;
    CGFloat b2 = other.b;
    // collinear. If they have a common endpoint, prefer that. Otherwise, Just average all the xs and ys.
    if (m1 == m2 && b1 == b2) {
      if (CGPointEqualToPoint(self.ls.end, other.ls.start) || CGPointEqualToPoint(self.ls.end, other.ls.end)) {
        *outP = self.ls.end;
      } else if (CGPointEqualToPoint(self.ls.start, other.ls.end) || CGPointEqualToPoint(self.ls.start, other.ls.start)) {
        *outP = self.ls.start;
      } else {
        outP->x = (self.ls.start.x + self.ls.end.x + other.ls.start.x + other.ls.end.x)/4;
        outP->y = (self.ls.start.y + self.ls.end.y + other.ls.start.y + other.ls.end.y)/4;
      }
      doesIntersect = YES;
    } else {
      CGFloat x = (b2-b1)/(m1-m2);
      
      // This gives the intersection point of the two lines. It might still be outside either segment.
      // The 'or' is because we don't know what direction the segment goes: is start left of end or vice versa?
      CGFloat y = m1*x + b1;
      *outP = CGPointMake(x, y);
      doesIntersect = YES;
    }
  }
  return doesIntersect;
}

// Only true if intersection is within the segments.
- (BOOL)intersects:(LineSegment *)other at:(CGPoint *)outP {
  // Is there an x, y, such that y=m1*x+b1 y=m2*x+b2
  // m1*x+b1=m2*x+b2
  // 0=m2*x - m1*x +b2-b1
  // 0=(m2-m1)*x +b2-b1
  // (m1-m2)*x = +b2-b1
  // x = (b2-b1)/(m1-m2)
  
  
  // y = mx + b
  // y - mx = b
  BOOL doesIntersect = NO;
  if([self isVertical] && [other isVertical]) {
    return NO;  // Both are vertical. Treat them as non-intersecting.
  } else if ([self isVertical]) {
    CGFloat x = self.ls.start.x;
    CGFloat loOtherX = MIN(other.ls.start.x, other.ls.end.x);
    CGFloat hiOtherX = MAX(other.ls.start.x, other.ls.end.x);
    if (loOtherX <= x && x <= hiOtherX) {
      CGFloat y = other.m*x + other.b;
      CGFloat loSelfY = MIN(self.ls.start.y, self.ls.end.y);
      CGFloat hiSelfY = MAX(self.ls.start.y, self.ls.end.y);
      if (loSelfY <= y && y <= hiSelfY) {
        *outP = CGPointMake(x, y);
        doesIntersect = YES;
      }
    }
  } else if([other isVertical]) {
    CGFloat x = other.ls.start.x;
    CGFloat loSelfX = MIN(self.ls.start.x, self.ls.end.x);
    CGFloat hiSelfX = MAX(self.ls.start.x, self.ls.end.x);
    if (loSelfX <= x && x <= hiSelfX) {
      CGFloat y = self.m*x + self.b;
      CGFloat loOtherY = MIN(other.ls.start.y, other.ls.end.y);
      CGFloat hiOtherY = MAX(other.ls.start.y, other.ls.end.y);
      if (loOtherY <= y && y <= hiOtherY) {
        *outP = CGPointMake(x, y);
        doesIntersect = YES;
      }
    }
  } else {
    CGFloat m1 = self.m;
    CGFloat m2 = other.m;
    if (m1 != m2) {
      CGFloat b1 = self.b;
      CGFloat b2 = other.b;
      CGFloat x = (b2-b1)/(m1-m2);
      
      // This gives the intersection point of the two lines. It might still be outside either segment.
      // So this 'if' checks that the intersection is actually within both segments.
      // The 'or' is because we don't know what direction the segment goes: is start left of end or vice versa?
      CGFloat loSelfX = MIN(self.ls.start.x, self.ls.end.x);
      CGFloat hiSelfX = MAX(self.ls.start.x, self.ls.end.x);

      CGFloat loOtherX = MIN(other.ls.start.x, other.ls.end.x);
      CGFloat hiOtherX = MAX(other.ls.start.x, other.ls.end.x);

      if (loSelfX <= x && x <= hiSelfX && loOtherX <= x && x <= hiOtherX) {
        CGFloat y = m1*x + b1;
        *outP = CGPointMake(x, y);
        doesIntersect = YES;
      }
    }
  }
  return doesIntersect;
}

- (BOOL)intersectsMiddle:(LineSegment *)b at:(CGPoint *)outP {
  return ![self hasCommonEndPoint:b] && [self intersects:b at:outP];
}

- (BOOL)containsPt:(CGPoint)p {
  if ([self isVertical]) {
    return feq(p.x, self.ls.start.x)&&
      ((self.ls.start.y < p.y && p.y < self.ls.end.y) || (self.ls.end.y < p.y && p.y < self.ls.start.y));
  }
  return feq(p.y, (self.m * p.x + self.b)) &&
    ((self.ls.start.x < p.x && p.x < self.ls.end.x) || (self.ls.end.x < p.x && p.x < self.ls.start.x));
}

- (void)shortenStartBy:(CGFloat)amount {
  CGFloat dx = _ls.start.x - _ls.end.x;
  CGFloat dy = _ls.start.y - _ls.end.y;
  CGFloat length = sqrt(dx*dx + dy*dy);
  if (amount < length) {
    length -= amount;
    CGFloat theta = atan2(dy, dx);
    CGFloat x = length*cos(theta) + _ls.end.x;
    CGFloat y = length*sin(theta) + _ls.end.y;
    _ls.start.x = x;
    _ls.start.y = y;
  }
}

// Basically the same as shortenStartBy, but we're going from the other end.
- (void)shortenEndBy:(CGFloat)amount {
  CGFloat dx = _ls.end.x - _ls.start.x;
  CGFloat dy = _ls.end.y - _ls.start.y;
  CGFloat length = sqrt(dx*dx + dy*dy);
  if (amount < length) {
    length -= amount;
    CGFloat theta = atan2(dy, dx);
    CGFloat x = length*cos(theta) + _ls.start.x;
    CGFloat y = length*sin(theta) + _ls.start.y;
    _ls.end.x = x;
    _ls.end.y = y;
  }
}

// Basically a generalization of shortenStartBy
- (PolyLine *)polyLineOfSegmentsLength:(CGFloat)amount {
  CGFloat dx = _ls.end.x - _ls.start.x;
  CGFloat dy = _ls.end.y - _ls.start.y;
  CGFloat length = sqrt(dx*dx + dy*dy);
  PolyLine *result = [[PolyLine alloc] init];
  CGFloat theta = atan2(dy, dx);
  CGFloat cosTheta = cos(theta);
  CGFloat sinTheta = sin(theta);
  for (CGFloat c = 0; c+amount < length; c += amount) {
    [result addPt:CGPointMake(c*cosTheta + _ls.start.x, c*sinTheta + _ls.start.y)];
  }
  [result addPt:_ls.end];
  return result;
}

- (PolyLine *)satinStitchHorizontalLower:(LineSegment *)lower interval:(CGFloat)interval {
  PolyLine *result = [[PolyLine alloc] init];
  NSAssert(feq(self.ls.start.y, self.ls.end.y) && feq(lower.ls.start.y, lower.ls.end.y),
      @"satinStitchHorizontalLower - not horizontal");
  NSAssert(self.ls.start.x < self.ls.end.x, @"satinStitchHorizontalLower - not indcreasing in X.");
  CGFloat minX;
  CGFloat maxX;
  BOOL  isUpper = NO;
  LineSegment *starts = nil;
  LineSegment *ends = nil;
  if (self.ls.start.x < self.ls.end.x) {
    minX = MIN(self.ls.start.x, lower.ls.start.x);
    maxX = MAX(self.ls.end.x, lower.ls.end.x);
    for (CGFloat x = minX; x < maxX; x += interval, isUpper = ! isUpper) {
      if (isUpper) {
        if (x < self.ls.start.x) {
          // x is before upper. we want the point x, mx+b on the linesegment of starts.
          if (nil == starts) {
            starts = [[LineSegment alloc] initWithStart:self.ls.start end:lower.ls.start];
          }
          [result addPt:CGPointMake(x, x*starts.m + starts.b) ifFurtherThan:interval];
        } else if (self.ls.end.x < x) {
          // x is after upper. we want the point x, mx+b on the linesegment of end.
          if (nil == ends) {
            ends = [[LineSegment alloc] initWithStart:self.ls.end end:lower.ls.end];
          }
          [result addPt:CGPointMake(x, x*ends.m + ends.b) ifFurtherThan:interval];
        } else {
          [result addPt:CGPointMake(x, self.ls.start.y) ifFurtherThan:interval];
        }
      } else {
        if (x < lower.ls.start.x) {
          // x is before lower. we want the point x, mx+b on the linesegment of starts.
          if (nil == starts) {
            starts = [[LineSegment alloc] initWithStart:self.ls.start end:lower.ls.start];
          }
          [result addPt:CGPointMake(x, x*starts.m + starts.b) ifFurtherThan:interval];
        } else if (lower.ls.end.x < x) {
          // x is after lower. we want the point x, mx+b on the linesegment of ends.
          if (nil == ends) {
             ends = [[LineSegment alloc] initWithStart:self.ls.end end:lower.ls.end];
          }
          [result addPt:CGPointMake(x, x*ends.m + ends.b) ifFurtherThan:interval];
        } else {
          [result addPt:CGPointMake(x, lower.ls.start.y) ifFurtherThan:interval];
        }
      }
    }
  } else {
    // Note: none of this is tested yet, since this method is so far only called from satinStitchUpper
    // whch transforms any segment into increasing X.
    minX = MIN(self.ls.end.x, lower.ls.end.x);
    maxX = MAX(self.ls.start.x, lower.ls.start.x);
    for (CGFloat x = minX;maxX < minX; x -= interval, isUpper = ! isUpper) {
      if (isUpper) {
        if (x < self.ls.end.x) {
          // x is before upper. we want the point x, mx+b on the linesegment of ends.
          if (nil == ends) {
             ends = [[LineSegment alloc] initWithStart:self.ls.end end:lower.ls.end];
          }
          [result addPt:CGPointMake(x, x*ends.m + ends.b) ifFurtherThan:interval];
        } else if (self.ls.start.x < x) {
          // x is after upper. we want the point x, mx+b on the linesegment of starts.
          if (nil == starts) {
            starts = [[LineSegment alloc] initWithStart:self.ls.start end:lower.ls.start];
          }
          [result addPt:CGPointMake(x, x*starts.m + starts.b) ifFurtherThan:interval];
       } else {
          [result addPt:CGPointMake(x, self.ls.start.y) ifFurtherThan:interval];
        }
      } else {
        if (x < lower.ls.end.x) {
          // x is before lower.  we want the point x, mx+b on the linesegment of ends.
          if (nil == ends) {
             ends = [[LineSegment alloc] initWithStart:self.ls.end end:lower.ls.end];
          }
          [result addPt:CGPointMake(x, x*ends.m + ends.b) ifFurtherThan:interval];
       } else if (lower.ls.start.x < x) {
          // x is after lower. we want the point x, mx+b on the linesegment of starts.
          if (nil == starts) {
            starts = [[LineSegment alloc] initWithStart:self.ls.start end:lower.ls.start];
          }
          [result addPt:CGPointMake(x, x*starts.m + starts.b) ifFurtherThan:interval];
        } else {
          [result addPt:CGPointMake(x, lower.ls.start.y) ifFurtherThan:interval];
        }
      }
    }
  }

  return result;
}

// satin stitch one segment. self is centerline defines axis.
- (PolyLine *)satinStitchUpper:(LineSegment *)upper lower:(LineSegment *)lower interval:(CGFloat)interval {
  CGFloat dx = _ls.end.x - _ls.start.x;
  CGFloat dy = _ls.end.y - _ls.start.y;
  CGFloat theta = atan2(dy, dx);
  CGPoint origin = self.ls.start;
  CGAffineTransform t = CGAffineTransformMakeTranslation(-origin.x, -origin.y);
  t = CGAffineTransformRotate(t, -theta);
  [self applyAffineTransform:t];
  [upper applyAffineTransform:t];
  [lower applyAffineTransform:t];
  PolyLine *result = [upper satinStitchHorizontalLower:lower interval:interval];
  CGAffineTransform inverseT = CGAffineTransformMakeRotation(theta);
  inverseT = CGAffineTransformTranslate(inverseT, origin.x, origin.y);
  [result applyAffineTransform:inverseT];
  return result;
}

- (void)applyAffineTransform:(CGAffineTransform)t {
  _ls.start = CGPointApplyAffineTransform(_ls.start, t);
  _ls.end = CGPointApplyAffineTransform(_ls.end, t);
}

- (void)draw {
  BPath *path = [BPath bpath];
  [path moveToPoint:self.ls.start];
  [path lineToPoint:self.ls.end];
  [path stroke];
}

@end

@implementation PolyLine

- (instancetype)init {
  self = [super init];
  if (self) {
    _pts = malloc(0);
  }
  return self;
}

- (void)dealloc {
  free(_pts);
}

- (instancetype)copyWithZone:(NSZone *)zone {
  PolyLine *result = [[[self class] allocWithZone:zone] init];
  result->_count = _count;
  result->_pts = (CGPoint *)realloc(result->_pts, _count*sizeof(CGPoint));
  memcpy(result->_pts, _pts, _count*sizeof(CGPoint));
  return result;
}

- (NSString *)description {
  NSMutableArray *a = [NSMutableArray array];
  for (int i = 0; i < _count;++i) {
    CGPoint p = _pts[i];
    NSString *s = [NSString stringWithFormat:@"%g,%g", p.x, p.y];
    [a addObject:s];
  }
  return [NSString stringWithFormat:@"PolyLine{%@}", [a componentsJoinedByString:@" "]];
}

- (void)addPt:(CGPoint)p {
  _count += 1;
  _pts = (CGPoint *)realloc(_pts, _count*sizeof(CGPoint));
  _pts[_count-1] = p;
}

- (void)addPt:(CGPoint)p ifFurtherThan:(CGFloat)threshold {
  if (_count) {
    CGPoint p0 = self.pts[_count - 1];
    CGFloat dx = p0.x - p.x;
    CGFloat dy = p0.y - p.y;
    if (threshold*threshold < (dx*dx + dy*dy)) {
      [self addPt:p];
    }
  } else {
    [self addPt:p];
  }
}

- (void)insertPt:(CGPoint)p atIndex:(NSUInteger)index {
  _count += 1;
  _pts = (CGPoint *)realloc(_pts, _count*sizeof(CGPoint));
  memmove(&_pts[index+1], &_pts[index], ((_count-1)-index) * sizeof(CGPoint));
  _pts[index] = p;
}

- (CGPoint)lastPt {
  return _pts[_count-1];
}

// TODO: optimize addPtsFromPolyLine
- (void)addPtsFromPolyLine:(PolyLine *)poly {
  for (int i = 0;i < poly.count; ++i) {
    [self addPt:poly.pts[i]];
  }
}

// TODO: optimize addPtsFromPolyLine:ifFurtherThan:
- (void)addPtsFromPolyLine:(PolyLine *)poly ifFurtherThan:(CGFloat)threshold {
  for (int i = 0;i < poly.count; ++i) {
    [self addPt:poly.pts[i] ifFurtherThan:threshold];
  }
}

- (void)addSegmentStart:(CGPoint)pStart end:(CGPoint)pEnd {
  if (0 == _count || ! CGPointEqualToPoint([self lastPt], pStart)) {
    [self addPt:pStart];
  }
  [self addPt:pEnd];
}

- (NSArray<LineSegment *> *)asLineSegments {
  NSMutableArray *result = [NSMutableArray array];
  for (int i = 1; i < _count;++i) {
    LineSegment *segment = [[LineSegment alloc] initWithStart:_pts[i-1] end:_pts[i]];
    [result addObject:segment];
  }
  return result;
}

- (void)applyAffineTransform:(CGAffineTransform)t {
  for (int i = 0; i < _count;++i) {
    _pts[i] = CGPointApplyAffineTransform(_pts[i], t);
  }
}

- (void)draw {
  if (2 <= _count) {
    BPath *path = [BPath bpath];
    CGPoint p = _pts[0];
    [path moveToPoint:p];
    for (int i = 1; i < _count; ++i) {
      p = _pts[i];
      [path lineToPoint:p];
    }
    [path stroke];
  }
}

- (void)plot {
  [self plotDotSize:15];
}

- (void)plotDotSize:(CGFloat)dotSize {
  for (int i = 0; i < _count; ++i) {
    CGPoint p = _pts[i];
    BPath *path = [BPath bpath];
    CGFloat kRadius = dotSize;
    CGRect r = CGRectMake(p.x-kRadius/2, p.y-kRadius/2, kRadius, kRadius);
    [path appendBezierPathWithOvalInRect:r];
    [path stroke];
  }
}

- (NSArray *)polyLinesBySplitAt:(CGPoint)p {
  return [self polyLinesBySplitAt:p margin:0];
}

- (void)shortenStartBy:(CGFloat)amount {
  LineSegment *segment = [[LineSegment alloc] initWithStart:_pts[0] end:_pts[1]];
  [segment shortenStartBy:amount];
  _pts[0] = segment.ls.start;
}

- (void)shortenEndBy:(CGFloat)amount {
  NSUInteger last = _count - 1;
  LineSegment *segment = [[LineSegment alloc] initWithStart:_pts[last - 1] end:_pts[last]];
  [segment shortenEndBy:amount];
  _pts[last] = segment.ls.end;
}

- (NSArray *)polyLinesBySplitAt:(CGPoint)p margin:(CGFloat)margin {
  NSMutableArray *result = nil;
  if (2 <= _count) {
    NSUInteger last = _count - 1;
    if (CGPointEqualToPoint(_pts[0], p)) {  // p is the start
      PolyLine *pl = [self copy];
      [pl shortenStartBy:margin/2];
       // For a closed polyline, the first and last points can be the same.
      if (CGPointEqualToPoint(_pts[last], p)) { // p is also the end
        [pl shortenEndBy:margin/2];
      }
      result = [NSMutableArray arrayWithObject:pl];
    } else if (CGPointEqualToPoint(_pts[last], p)) {  // p is the end
      PolyLine *pl = [self copy];
      [pl shortenEndBy:margin/2];
      result = [NSMutableArray arrayWithObject:pl];
    } else {
      for (int i = 1; i < last; ++i) {
        if (CGPointEqualToPoint(_pts[i], p)) {  // p is a vertex, but not start or end.
          PolyLine *pl = [[PolyLine alloc] init];
          for (int j = 0; j <= i; ++j) {
            [pl addPt:_pts[j]];
          }
          [pl shortenEndBy:margin/2];
          result = [NSMutableArray arrayWithObject:pl];
          PolyLine *pl2 = [[PolyLine alloc] init];
          for (int j = i; j < _count; ++j) {
            [pl2 addPt:_pts[j]];
          }
          [pl2 shortenStartBy:margin/2];
          [result addObject:pl2];
        }
      }
      // We know the point isn't any of our vertices.
      // for each segment, does it intersect?
      if (nil == result) {
        for (int i = 0; i < last; ++i) {
          LineSegment *segment = [[LineSegment alloc] init];
          LineSegmentStruct ls;
          ls.start = _pts[i];
          ls.end = _pts[i+1];
          segment.ls = ls;
          if ([segment containsPt:p]) {
            PolyLine *pl = [[PolyLine alloc] init];
            for (int j = 0; j <= i; ++j) {
              [pl addPt:_pts[j]];
            }
            [pl addPt:p];
            [pl shortenEndBy:margin/2];
            result = [NSMutableArray arrayWithObject:pl];
            PolyLine *pl2 = [[PolyLine alloc] init];
            [pl2 addPt:p];
            for (int j = i+1; j < _count; ++j) {
              [pl2 addPt:_pts[j]];
            }
            [pl2 shortenStartBy:margin/2];
            [result addObject:pl2];
          }
        }
      }
    }
  }
  return result;
}

// Hexagram.m - showed that I had to re-examine the result of the split to handle polylines
// that intersect themselves.
- (NSArray *)polyLinesBySplitIntersections:(PolyLine *)intersections margin:(CGFloat)margin {
  NSMutableArray *result = [NSMutableArray array];
  [result addObject:[self copy]];
  for (int i = 0; i <  [intersections count]; ++i) {
    CGPoint c = intersections.pts[i];
    for (int j = (int)[result count] - 1;0 <= j; --j) {
      PolyLine *p = result[j];
      NSArray *parts = [p polyLinesBySplitAt:c margin:margin];
      if ([parts count]) {
        [result replaceObjectsInRange:NSMakeRange(j, 1) withObjectsFromArray:parts];
        j += ([parts count] - 1); // This was the fix.
      }
    }
  }
  return result;
}

- (instancetype)removeRedundant {
  PolyLine *result = [[PolyLine alloc] init];
  [result addPt:_pts[0]];
  LineSegment *prev = [[LineSegment alloc] initWithStart:_pts[0] end:_pts[1]];
  LineSegment *nex = [[LineSegment alloc] init];
  for (int i = 0; i < _count - 1; ++i) {
    LineSegmentStruct ls;
    ls.start = _pts[i];
    ls.end = _pts[i+1];
    nex.ls = ls;
    // if it is not the case that they are both vertical or both have the same m and b,
    if ( ! (([prev isVertical] && [nex isVertical]) || (feq(prev.m, nex.m) && feq(prev.b, nex.b)))) {
      [result addPt:_pts[i]];
    }
    LineSegment *t;
    t = prev;
    prev = nex;
    nex = t;
  }
  [result addPt:_pts[_count - 1]];
  return result;
}


- (CGPoint)pointOffset:(CGFloat)amount fromPtAtIndex:(int)i endcapAngle:(CGFloat)endcapAngle {
  CGPoint p0 = _pts[i];
  if (i == 0) {
    CGPoint p1 = _pts[i+1];
    CGFloat angle = AngleInRadians1(p0, p1) + M_PI/2 + endcapAngle;
    CGPoint p;
    p.x = p0.x + cos(angle)*amount;
    p.y = p0.y + sin(angle)*amount;
    return p;
  } else if (i == (_count - 1)) {
    CGPoint pMinus1 = _pts[i-1];
    CGFloat angle = AngleInRadians1(pMinus1, p0) + M_PI/2 + endcapAngle;
    CGPoint p;
    p.x = p0.x + cos(angle)*amount;
    p.y = p0.y + sin(angle)*amount;
    return p;
  } else {
    CGPoint pMinus1 = _pts[i-1];
    CGFloat angleA = AngleInRadians1(pMinus1, p0) + M_PI/2;
    CGPoint pa;
    pa.x = pMinus1.x + cos(angleA)*amount;
    pa.y = pMinus1.y + sin(angleA)*amount;
    CGPoint pb;
    pb.x = p0.x + cos(angleA)*amount;
    pb.y = p0.y + sin(angleA)*amount;

	LineSegment *la = [[LineSegment alloc] initWithStart:pa end:pb];
    
    CGPoint p1 = _pts[i+1];
    CGFloat angle = AngleInRadians1(p0, p1) + M_PI/2;
    CGPoint pc;
    pc.x = p0.x + cos(angle)*amount;
    pc.y = p0.y + sin(angle)*amount;
    CGPoint pd;
    pd.x = p1.x + cos(angle)*amount;
    pd.y = p1.y + sin(angle)*amount;

	LineSegment *lb = [[LineSegment alloc] initWithStart:pc end:pd];

    CGPoint p;
    if( ! [la intersectsLine:lb at:&p]) {
      NSLog(@"-[%@ %@] : %@ %@ don't intersect", [self class], NSStringFromSelector(_cmd), la, lb);
    }
    return p;
  }
}

- (NSArray *)pictureFrame:(CGFloat)amount {
  NSMutableArray *result = [NSMutableArray array];
  CGFloat endcapAngle = 0;
  amount /= 2;
  PolyLine *upper = [[PolyLine alloc] init];
  for (int i = 0; i <  _count; ++i) {
    [upper addPt:[self pointOffset:amount fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  PolyLine *lower = [[PolyLine alloc] init];
  for (int i = 0; i <  _count; ++i) {
    [lower addPt:[self pointOffset:-amount fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  // -1 since we look at a point and the next one.
  for (int i = 0; i <  _count-1; ++i) {
    PolyLine *p = [[PolyLine alloc] init];
    [p addPt:upper.pts[i]];
    [p addPt:upper.pts[i+1]];
    [p addPt:lower.pts[i+1]];
    [p addPt:lower.pts[i]];
    [p addPt:upper.pts[i]];
    [result addObject:p];
 }
  return result;
}

- (instancetype)simpleSatinStitch1:(CGFloat)width interval:(CGFloat)interval  {
  PolyLine *result = [[PolyLine alloc] init];
  CGFloat endcapAngle = 0;
  width /= 2;
  PolyLine *upper = [[PolyLine alloc] init];
  for (int i = 0; i <  _count; ++i) {
    [upper addPt:[self pointOffset:width fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  PolyLine *lower = [[PolyLine alloc] init];
  for (int i = 0; i <  _count; ++i) {
    [lower addPt:[self pointOffset:-width fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  LineSegment *upperLine = [[LineSegment alloc] init];
  LineSegmentStruct upperLS;
  LineSegment *lowerLine = [[LineSegment alloc] init];
  LineSegmentStruct lowerLS;
  for (int i = 0; i < _count-1; ++i) {
    upperLS.start = upper.pts[i];
    upperLS.end = upper.pts[i+1];
    upperLine.ls = upperLS;

    lowerLS.start = lower.pts[i];
    lowerLS.end = lower.pts[i+1];
    lowerLine.ls = lowerLS;
    
    PolyLine *upperPieces = [upperLine polyLineOfSegmentsLength:interval];
    PolyLine *lowerPieces = [lowerLine polyLineOfSegmentsLength:interval];
   int maxCount = MAX(upperPieces.count, lowerPieces.count);
    for (int j = 0;j < maxCount; ++j) {
      if (j < upperPieces.count) {
        [result addPt:upperPieces.pts[j]];
      }
      if (j < lowerPieces.count) {
        [result addPt:lowerPieces.pts[j]];
      }
    }
  }
  return result;
}

- (instancetype)simpleSatinStitch:(CGFloat)width interval:(CGFloat)interval {
  return [[self removeRedundant] simpleSatinStitch1:width interval:interval];
}

- (instancetype)satinStitch1:(CGFloat)width interval:(CGFloat)interval  {
  PolyLine *result = [[PolyLine alloc] init];
  CGFloat endcapAngle = 0;
  interval /= 2;
  width /= 2;
  PolyLine *upper = [[PolyLine alloc] init];
  for (int i = 0; i <  _count; ++i) {
    [upper addPt:[self pointOffset:width fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  PolyLine *lower = [[PolyLine alloc] init];
  for (int i = 0; i <  _count; ++i) {
    [lower addPt:[self pointOffset:-width fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  // -1 since we look at a point and the next one.
  for (int i = 0; i <  _count-1; ++i) {
    LineSegment *axisLine = [[LineSegment alloc] initWithStart:self.pts[i] end:self.pts[i+1]];
    LineSegment *upperLine = [[LineSegment alloc] initWithStart:upper.pts[i] end:upper.pts[i+1]];
    LineSegment *lowerLine = [[LineSegment alloc] initWithStart:lower.pts[i] end:lower.pts[i+1]];
    PolyLine *p = [axisLine satinStitchUpper:upperLine lower:lowerLine interval:interval];
    [result addPtsFromPolyLine:p ifFurtherThan:interval];
 }
  return result;
}

- (instancetype)satinStitch:(CGFloat)width interval:(CGFloat)interval {
  return [[self removeRedundant] satinStitch1:width interval:interval];
}

// For each line segment, replace it by a trapezoid that is "wider" than the line segment
// by amount. Analogous to setPenSize.

// For each vertex, increasing, create the 'south' vertex, then decreasing, create the 'north' vertex.
// for each pair of vertices, go out the appropriate distance to get two vertices on the 'border' line.
// polyline. appropriate distance: solve the trig.
- (instancetype)widen1:(CGFloat)amount endcapAngle:(CGFloat)endcapAngle {
  PolyLine *result = [[PolyLine alloc] init];
  amount /= 2;
  for (int i = 0; i <  _count; ++i) {
    [result addPt:[self pointOffset:amount fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  for (int i = _count-1; 0 <= i; --i) {
    [result addPt:[self pointOffset:-amount fromPtAtIndex:i endcapAngle:endcapAngle]];
  }
  [result addPt:result.pts[0]];
  return result;
}

- (instancetype)widen:(CGFloat)amount endcapAngle:(CGFloat)endcapAngle {
  return [[self removeRedundant] widen1:amount endcapAngle:endcapAngle];
}
- (instancetype)widen:(CGFloat)amount {
  return [self widen:amount endcapAngle:0];
}

@end
