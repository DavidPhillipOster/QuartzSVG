//  GraphicsMath.h
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

#import <Foundation/Foundation.h>

@class PolyLine;

CGFloat AngleInRadians(CGPoint first, CGPoint center, CGPoint third);

// Input is an array of line segments. output is a list of vertices
// Compares an every segment in an array to every other segment, and returns a list of all places the segments intersect
// (excluding endpoints)
PolyLine *ComputeIntersections(NSArray* inputlines);

// Input is an array of Polylines. Output is an araay of polylines. If in the input, any polyline starts where another ends,
// both are placed in the output by a new polyline that is the merger of the two.
NSArray *PolylinesJoiningEndpoints(NSArray *polylines);

typedef struct LineSegmentStruct {
  CGPoint start;
  CGPoint end;
} LineSegmentStruct;

// A line segment
@interface LineSegment  : NSObject<NSCopying>
@property(nonatomic) LineSegmentStruct ls;

// slope. Undefined for vertical lines.
@property(nonatomic, readonly) CGFloat m;

// intercept of the Y axis.
@property(nonatomic, readonly) CGFloat b;

- (instancetype)initWithStart:(CGPoint)start end:(CGPoint)end;

- (BOOL)containsPt:(CGPoint)p;

- (BOOL)intersects:(LineSegment *)b at:(CGPoint *)outP;

// has an intersection that isn't an endpoint.
- (BOOL)intersectsMiddle:(LineSegment *)b at:(CGPoint *)outP;

- (BOOL)hasCommonEndPoint:(LineSegment *)other;

- (void)shortenStartBy:(CGFloat)amount;

- (void)shortenEndBy:(CGFloat)amount;

// Given a lineSegment, carve it up returning a pointset with a list of points such that the distance
// between adjacent points is amount. Put any remainder into the last segment.
// (Therefore if the length is less than twice the amount, you'll just get a polyline with two points.)
- (PolyLine *)polyLineOfSegmentsLength:(CGFloat)amount;

- (void)draw;

@end


// A PolyLine. Can also be used to represent an array of vertices.
// A Polygon triangle would have three vertices. A polyline has 4 since we explicitly lineTo at the end.
@interface PolyLine : NSObject<NSCopying>
@property(nonatomic) int count;
@property(nonatomic, unsafe_unretained) CGPoint *pts;

- (void)addPt:(CGPoint)p;

// Don't add the point if the disance between it and the previous point is less than threshold.
- (void)addPt:(CGPoint)p ifFurtherThan:(CGFloat)threshold;

- (void)insertPt:(CGPoint)p atIndex:(NSUInteger)index;

- (void)addSegmentStart:(CGPoint)pStart end:(CGPoint)pEnd;

- (NSArray<LineSegment *> *)asLineSegments;

- (void)draw;

- (void)applyAffineTransform:(CGAffineTransform)t;

- (void)plot; // as individual verticies

- (void)plotDotSize:(CGFloat)dotSize;

// see polyLinesBySplitAt:margin:
- (NSArray *)polyLinesBySplitAt:(CGPoint)p;

// Given a point that intersects the poly line, including at an endpoint, return two new
// polylines, severed at the point. If the input isn't an intersection, just return nil;
// shrink the line segments adjacent to the interection point by half margin, so the resulting
// pair have a margin gap between the pieces.
// if the input point is the first or last, return an array length 1.
- (NSArray *)polyLinesBySplitAt:(CGPoint)p margin:(CGFloat)margin;

// similar to above, but if a polyline is split twice, you get 3 pieces.
// intersections - treated as an array of points.
- (NSArray *)polyLinesBySplitIntersections:(PolyLine *)intersections margin:(CGFloat)margin;

// For each line segment, replace it by a quadrilateral that is "wider" than the line segment
// by 'amount'. returns the new array of polylines. Analogous to setPenSize.
- (NSArray *)pictureFrame:(CGFloat)amount;

// if there are extra vertices that aren't needed because they are on the same line as their
// neighbors, remove them.
- (instancetype)removeRedundant;

// For each line segment, replace it by a rectangle that is "wider" than the line segment
// by 'amount'. Then zigzag from top to bottom. Doesn't do anything special for acute angles.
// interval is distance between adjacent points on each line.
- (instancetype)simpleSatinStitch:(CGFloat)width interval:(CGFloat)interval;

// For each line segment, replace it by a quadrilateral that is "wider" than the line segment
// by 'amount'. Then zigzag from top to bottom. Correctly handle acute angles.
// interval is distance between adjacent points on each line.
- (instancetype)satinStitch:(CGFloat)width interval:(CGFloat)interval;

// For each line segment, replace it by a quadrilateral that is "wider" than the line segment
// by 'amount', then merge the quadrilaterals. Analogous to setPenSize.
- (instancetype)widen:(CGFloat)amount;

// Like widen, but 'miter' the ends of the polylines by endcapAngle. Used for DavidStar to give the
// 60° endcaps. endcapAngle is in radians
- (instancetype)widen:(CGFloat)amount endcapAngle:(CGFloat)endcapAngle;
@end
