//  BezierPath.m
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 11/17/13.
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

#import "BezierPath.h"
#import "GraphicsContext.h"

static NSPoint kUninitializedPoint = {1.0e-12, 1.0e-12};

static BOOL FloatsAreEqual(float a, float b) {
  return fabsf(a-b) < 1.0e-3;
}

static BOOL PointsAreEqual(NSPoint a, NSPoint b) {
  if (NSEqualPoints(a, kUninitializedPoint) || NSEqualPoints(b, kUninitializedPoint)) {
    return NSEqualPoints(a, b);
  }
  return FloatsAreEqual(a.x, b.x) && FloatsAreEqual(a.y, b.y);
}


@interface BCommand : NSObject
@property (nonatomic, copy) NSString *verb;
- (NSString *)asSVG;
@end
@interface BCommand1 : BCommand
@property (nonatomic) NSPoint p;
@end
@interface BCommand2 : BCommand
@property (nonatomic) NSPoint p1;
@property (nonatomic) NSPoint p2;
@end
@interface BCommand3 : BCommand
@property (nonatomic) NSPoint p1;
@property (nonatomic) NSPoint p2;
@property (nonatomic) NSPoint p3;
@end
@interface BCommandArc : BCommand
@property (nonatomic) NSPoint p;
@property (nonatomic) float radius;
@property (nonatomic) float startAngle;
@property (nonatomic) float endAngle;
@property (nonatomic) BOOL isClockwise;
@end


@implementation BCommand
- (NSString *)asSVG {
  return [self verb];
}
@end
@implementation BCommand1
- (NSString *)asSVG {
  NSString *verbString = [self verb];
  if ([verbString isEqual:@"moveToPoint:"]) {
    verbString = @"M";
  } else if ([verbString isEqual:@"lineToPoint:"]) {
    verbString = @"L";
  }
  return [NSString stringWithFormat:@"%@%g %g", verbString, _p.x, _p.y];
}
@end
@implementation BCommand2
- (NSString *)asSVG {
  NSString *verbString = [self verb];
  if ([verbString isEqual:@"appendBezierPathWithOvalInRect:"]) {
  float l = _p1.x;
  float r = _p2.x;
  float t = _p1.y;
  float b = _p2.y;
  float w = fabs(l - r);
  float h = fabs(b - t);
  return [NSString stringWithFormat:@"M%g %g A%g %g 180 1,0 %g %g A%g %g 180 1,0 %g %g z",
    l, t+h/2, w/2, h/2, r, t+h/2, w/2, h/2, l, t+h/2];
  }
  return [NSString stringWithFormat:@"%@%g %g  %g %g", verbString, _p1.x, _p1.y,  _p2.x, _p2.y];
}

@end
@implementation BCommand3
- (NSString *)asSVG {
  NSString *verbString = [self verb];
  if ([verbString isEqual:@"curveToPoint:controlPoint1:controlPoint2:"]) {
    return [NSString stringWithFormat:@"C %g %g   %g %g   %g %g", _p2.x, _p2.y,  _p3.x, _p3.y, _p1.x, _p1.y];
  }
  return [NSString stringWithFormat:@"%@ %g %g   %g %g   %g %g", [self verb], _p1.x, _p1.y,  _p2.x, _p2.y,  _p3.x, _p3.y];
}
@end
@implementation BCommandArc
- (NSString *)asSVG {
  float ex = _p.x + _radius * cos(_endAngle * M_PI/180.);
  float ey = _p.y + _radius * sin(_endAngle * M_PI/180.);
  return [NSString stringWithFormat:@"A%g %g 0 0 %d %g %g", _radius, _radius, !_isClockwise, ex, ey];
}
@end


BCommand *Command0(NSString *verb) {
  BCommand *result = [[BCommand alloc] init];
  [result setVerb:verb];
  return result;
}

BCommand *Command1(NSString *verb, NSPoint p) {
  BCommand1 *result = [[BCommand1 alloc] init];
  [result setVerb:verb];
  [result setP:p];
  return result;
}

BCommand *Command2(NSString *verb, NSPoint p1, NSPoint p2) {
  BCommand2 *result = [[BCommand2 alloc] init];
  [result setVerb:verb];
  [result setP1:p1];
  [result setP2:p2];
  return result;
}


BCommand *Command3(NSString *verb, NSPoint p1, NSPoint p2, NSPoint p3) {
  BCommand3 *result = [[BCommand3 alloc] init];
  [result setVerb:verb];
  [result setP1:p1];
  [result setP2:p2];
  [result setP3:p3];
  return result;
}


@interface Notch : NSObject
// At end of this method, p1.x should be increased by numSegments*unitLength
- (NSPoint)notch:(BezierPath *)path p1:(NSPoint)p1 t:(NSAffineTransform *)t numSegments:(int)numSegments unitLength:(float)unitLength;
@end
@implementation Notch
- (NSPoint)notch:(BezierPath *)path p1:(NSPoint)p1 t:(NSAffineTransform *)t numSegments:(int)numSegments unitLength:(float)unitLength {
  p1.x += numSegments*unitLength;
  [path lineToPoint:[t transformPoint:p1]];
  return p1;
}
@end

@interface Pinking : Notch
@end
@implementation Pinking
- (NSPoint)notch:(BezierPath *)path p1:(NSPoint)p1 t:(NSAffineTransform *)t numSegments:(int)numSegments unitLength:(float)unitLength {
  int j = -1;
  for (int i = 0; i < numSegments; ++i, p1.x += unitLength) {
    [path lineToPoint:[t transformPoint:NSMakePoint(p1.x, p1.y+(unitLength/2)*j)]];
    if (1 == j) {
      j = -1;
    } else {
      j = 1;
    }
  }
  return p1;
}
@end

@interface Crenellated : Notch
@end
@implementation Crenellated
- (NSPoint)notch:(BezierPath *)path p1:(NSPoint)p1 t:(NSAffineTransform *)t numSegments:(int)numSegments unitLength:(float)unitLength {
  int j = -1;
 [path lineToPoint:[t transformPoint:p1]];
  for (int i = 0; i < numSegments; ++i) {
    [path lineToPoint:[t transformPoint:NSMakePoint(p1.x, p1.y+(unitLength/2)*j)]];
    p1.x += unitLength;
    [path lineToPoint:[t transformPoint:NSMakePoint(p1.x, p1.y+(unitLength/2)*j)]];
    if (1 == j) {
      j = -1;
    } else {
      j = 1;
    }
  }
  return p1;
}
@end

@interface Scalloped : Notch
@end

@implementation Scalloped

- (NSPoint)notch:(BezierPath *)path p1:(NSPoint)p1 t:(NSAffineTransform *)t numSegments:(int)numSegments unitLength:(float)unitLength {
  int j = -1;
  [path lineToPoint:[t transformPoint:p1]];
  for (int i = 0; i < numSegments; ++i) {
    NSPoint pa = [t transformPoint:NSMakePoint(p1.x, p1.y+(unitLength/2)*j)];
    p1.x += unitLength;
    NSPoint pb = [t transformPoint:NSMakePoint(p1.x, p1.y+(unitLength/2)*j)];
    [path curveToPoint:[t transformPoint:p1] controlPoint1:pa controlPoint2:pb];
    if (1 == j) {
      j = -1;
    } else {
      j = 1;
    }
  }
  return p1;
}
@end

@interface BezierPath ()
@property (strong) NSBezierPath *path;
@property bool didShow;
@end

@implementation BezierPath

- (id)init {
  self = [super init];
  if (self) {
    [self setPath:[NSBezierPath bezierPath]];
    [self setCommands:[NSMutableArray array]];
    _didShow = YES;
  }
  return self;
}

- (void)fill {
  [_path fill];
  [_context fillPath:self];
  _didShow = YES;
}

- (void)setLineWidth:(float)width {
  _lineWidth = width;
  [_path setLineWidth:width];
}

- (void)stroke {
  [_path stroke];
  [_context strokePath:self];
 _didShow = YES;
}

- (void)moveToPoint:(NSPoint)p {
  if (_didShow) {
    _currentPoint = kUninitializedPoint;
    _didShow = NO;
  }
  if (!PointsAreEqual(p, _currentPoint)) {
    [_path moveToPoint:p];
    [_commands addObject:Command1(NSStringFromSelector(_cmd), p)];
    _currentPoint = p;
  }
}

- (void)lineToPoint:(NSPoint)p {
  if (!PointsAreEqual(p, _currentPoint)) {
    [_path lineToPoint:p];
    [_commands addObject:Command1(NSStringFromSelector(_cmd), p)];
    _currentPoint = p;
  }
}

// transform to motion in the positive X direction.
- (void)shears:(NSPoint)p unitLength:(NSUInteger)unitLength notch:(Notch *)notch {
  CGPoint p1 = _currentPoint;
  CGFloat dx = p.x - p1.x;
  CGFloat dy = p.y - p1.y;
  CGFloat length = sqrtf(dx*dx + dy*dy);
  CGFloat numSegments = floorf(length/unitLength);
  if (numSegments <= 4) {
     [self lineToPoint:p];
  } else {
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:p1.x yBy:p1.y];
    [t rotateByRadians:atan2f(dy, dx)];
    p1 = CGPointZero;
    CGFloat extra = (length - (numSegments * unitLength))/2;
    p1.x += extra+unitLength;
    [self lineToPoint:[t transformPoint:p1]];
    p1.x += unitLength;
    numSegments -= 3;
    p1 = [notch notch:self p1:p1 t:t numSegments:numSegments unitLength:unitLength];
    [self lineToPoint:[t transformPoint:p1]];
    p1.x += unitLength+extra;
    [self lineToPoint:[t transformPoint:p1]];
  }
}

- (void)pinkingLineToPoint:(NSPoint)p {
  static CGFloat kBumpSize = 8;
  [self shears:p unitLength:kBumpSize notch:[[Pinking alloc] init]];
}

- (void)crenellatedLineToPoint:(NSPoint)p {
  static CGFloat kBumpSize = 8;
  [self shears:p unitLength:kBumpSize notch:[[Crenellated alloc] init]];
}

- (void)scallopedLineToPoint:(NSPoint)p {
  static CGFloat kBumpSize = 8;
  [self shears:p unitLength:kBumpSize notch:[[Scalloped alloc] init]];
}

- (void)styledLineToPoint:(NSPoint)p {
  [self scallopedLineToPoint:p];
}

- (void)appendBezierPathWithOvalInRect:(NSRect)r {
  [_path appendBezierPathWithOvalInRect:r];
  [_commands addObject:Command2(NSStringFromSelector(_cmd), r.origin,
    NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height))];
}

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center
                                   radius:(CGFloat)radius
                               startAngle:(CGFloat)startAngle
                                 endAngle:(CGFloat)endAngle
                                clockwise:(BOOL)clockwise {
  float sx = center.x + radius * cos(startAngle * M_PI/180.);
  float sy = center.y + radius * sin(startAngle * M_PI/180.);
  [self lineToPoint:CGPointMake(sx, sy)];
  [_path appendBezierPathWithArcWithCenter:center
                                    radius:radius
                                startAngle:startAngle
                                  endAngle:endAngle
                                 clockwise:clockwise];
  BCommandArc *c = [[BCommandArc alloc] init];
  c.p = center;
  c.radius = radius;
  c.startAngle = startAngle;
  c.endAngle = endAngle;
  c.isClockwise = clockwise;
  [_commands addObject:c];
}


- (void)curveToPoint:(NSPoint)endPoint
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2 {
  if (!PointsAreEqual(endPoint, _currentPoint)) {
    [_path curveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [_commands addObject:Command3(NSStringFromSelector(_cmd), endPoint, controlPoint1, controlPoint2)];
    _currentPoint = endPoint;
  }
}

- (void)closePath {
  [_path closePath];
  [_commands addObject:Command0(@"z")];
}

- (NSString *)asSVGWithAttributes:(NSString *)attributes {
  NSMutableArray *a = [NSMutableArray array];
  NSString *attributesPart = @"";
  if ([attributes length]) {
    attributesPart = [NSString stringWithFormat:@" %@", attributes];
  }
  for (BCommand *command in _commands) {
    [a addObject:[command asSVG]];
  }
  [_commands removeAllObjects];
  NSString *d = [a componentsJoinedByString:@" "];
  return [NSString stringWithFormat:@"<path%@ d=\"%@\"/>\n", attributesPart, d];
}


@end

@implementation BPath
+ (instancetype)bpath {
  BPath *result = [[self alloc] init];
  [result setContext:[GraphicsContext currentContext]];
  return result;
}

- (void)line2P:(CGPoint)a p:(CGPoint)b {
  if (!_isForward) {
    CGPoint t = a;
    a = b;
    b = t;
  }
  _isForward = !_isForward;
  [self moveToPoint:a];
  [self lineToPoint:b];
  [self stroke];
}

@end

