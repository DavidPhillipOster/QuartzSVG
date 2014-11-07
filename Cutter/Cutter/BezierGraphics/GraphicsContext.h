//  GraphicContext.h - wrap a NSGraphicContext
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

#import <AppKit/AppKit.h>

@class BezierPath;

@interface GraphicsContext : NSObject
+ (GraphicsContext *)currentContext;
- (void)setColor:(NSColor *)color;
- (void)setTransform:(NSAffineTransform *)transform;
- (void)concat:(NSAffineTransform *)transform;

- (void)saveGraphicsState;
- (void)restoreGraphicsState;

- (BezierPath *)bezierPath;

- (void)openSVG;
- (void)closeSVG;

- (void)openGroupNamed:(NSString *)name;
- (void)closeGroup;


// callbacks from the path:
- (void)fillPath:(BezierPath *)path;
- (void)strokePath:(BezierPath *)path;
@end
