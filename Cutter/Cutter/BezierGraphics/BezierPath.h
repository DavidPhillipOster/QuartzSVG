//  BezierPath.h
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 2/01/2014
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

#import <Foundation/Foundation.h>

@class GraphicsContext;

// Wrap an NSBezierPath - mirror commands back to the GraphicsContext, so it can write them
@interface BezierPath : NSObject
@property (weak) GraphicsContext *context;
@property (strong) NSMutableArray *commands;
@property NSPoint currentPoint; // for subclasses
@property (nonatomic) float lineWidth;

- (void)fill;

- (void)stroke;

- (void)setLineWidth:(float)width;

- (void)moveToPoint:(NSPoint)p;

- (void)lineToPoint:(NSPoint)p;

- (void)pinkingLineToPoint:(NSPoint)p;

- (void)styledLineToPoint:(NSPoint)p;

- (void)crenellatedLineToPoint:(NSPoint)p;
- (void)scallopedLineToPoint:(NSPoint)p;

- (void)appendBezierPathWithOvalInRect:(NSRect)rect;

- (void)appendBezierPathWithArcWithCenter:(NSPoint)center
                                   radius:(CGFloat)radius
                               startAngle:(CGFloat)startAngle
                                 endAngle:(CGFloat)endAngle
                                clockwise:(BOOL)clockwise;


- (void)curveToPoint:(NSPoint)endPoint
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2;

- (void)closePath;

// Note: the stroke history is cleared after you call this.
- (NSString *)asSVGWithAttributes:(NSString *)attributes;

@end


@interface BPath : BezierPath
@property BOOL isForward;
+ (instancetype)bpath;
- (void)line2P:(CGPoint)a p:(CGPoint)b;
@end
