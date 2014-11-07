//  Teardrop.m
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


// For the teardrop Christmas ornaments, I'm not happy with how the autotrace of the pdf turned out.
// This works, but the angle at which it transitions from line to arc was determined by trian and error. Better would have been to do the math to compute the tangent points.
@interface Teardrop : CutView
@end

@implementation Teardrop

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
  [self drawTeardrop:frame];

  [currentContext closeSVG];
}

- (void)drawTeardrop:(CGRect)r {
  CGFloat h = r.size.height;
  CGFloat x = r.origin.x + r.size.width - h;
  CGFloat y = r.origin.y;
//  CGFloat w = r.size.width;
  CGPoint center = CGPointMake(x, y+h/2);
  [self drawTeardropCircleCenter:center radius:h/4];
  [self drawCircleCenter:center radius:(h/4)*0.8];
}

- (void)drawTeardropCircleCenter:(CGPoint)center radius:(CGFloat)radius {
  BPath *p = [BPath bpath];
  static float offsetTheta = -30;
  [p moveToPoint:CGPointMake(center.x, center.y-(radius*4./2.))];
  [p appendBezierPathWithArcWithCenter:center radius:radius startAngle:-(180+offsetTheta) endAngle:(0+offsetTheta) clockwise:YES];
  [p lineToPoint:CGPointMake(center.x, center.y-(radius*4./2.))];
  [p stroke];
}

- (void)drawCircleCenter:(CGPoint)center radius:(CGFloat)radius {
  BPath *p = [BPath bpath];
  CGRect r = CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2);
  [p appendBezierPathWithOvalInRect:r];
  [p stroke];
}


@end
