//  GraphicContext.m
//
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

#import "GraphicsContext.h"
#import "BezierPath.h"

@interface NSColor (GraphicsContext)
- (NSString *)asRGBString;
@end
@implementation NSColor (GraphicsContext)
- (NSString *)asRGBString {
  if ([[NSColorSpace deviceGrayColorSpace] isEqual:[self colorSpace]] ||
    [[NSColorSpace genericGrayColorSpace] isEqual:[self colorSpace]]) {
    int gray = (int)([self whiteComponent]*255.);
    return [NSString stringWithFormat:@"rgb(%d,%d,%d)", gray, gray, gray];
  } else if([[NSColorSpace deviceRGBColorSpace] isEqual:[self colorSpace]] ||
    [[NSColorSpace genericRGBColorSpace] isEqual:[self colorSpace]]) {
    return [NSString stringWithFormat:@"rgb(%d,%d,%d)",
      (int)([self redComponent]*255.),
      (int)([self greenComponent]*255.),
      (int)([self blueComponent]*255.)];
  } else {
    return @"rgb(0, 0, 0)";
  }
  
}

@end

@interface NSAffineTransform (GraphicsContext)
- (NSString *)asString;
- (NSString *)asSVG;
@end
@implementation NSAffineTransform (GraphicsContext)
- (NSString *)asString {
  NSAffineTransformStruct s = [self transformStruct];
  return [NSString stringWithFormat:@"%g %g 0\n%g %g 0\n%g %g 1", s.m11, s.m12, s.m21, s.m22, s.tX, s.tY];
}

- (NSString *)asSVG {
  if ([self isEqual:[NSAffineTransform transform]]) {
    return nil;
  }
  NSAffineTransformStruct s = [self transformStruct];
  return [NSString stringWithFormat:@"transform=\"matrix(%g,%g,%g,%g,%g,%g)\"", s.m11, s.m12, s.m21, s.m22, s.tX, s.tY];
}

@end


static GraphicsContext *sGraphicContext;

@interface GraphicsContext()
@property (strong) NSGraphicsContext *context;
// I tried keeping a separate stack of transforms, but it didn't appear to work, so I went back
// to extracting the current transform from the NSGraphicsContext's CGContextRef
// How do you query the context for the current color?
// Until I find out, I'll keep track of the current color here.
@property (strong) NSMutableArray *colorStack;
@end

@implementation GraphicsContext

+ (GraphicsContext *)currentContext {
  NSGraphicsContext *actualContect = [NSGraphicsContext currentContext];
  if ([sGraphicContext context] != actualContect) {
    sGraphicContext = [[self alloc] initWithContext:actualContect];
  }
  return sGraphicContext;
}

- (BezierPath *)bezierPath {
  BezierPath *path = [[BezierPath alloc] init];
  [path setContext:self];
  return path;
}


- (id)initWithContext:(NSGraphicsContext *)context {
  self = [super init];
  if (self) {
    [self setContext:context];
    [self setColorStack:[NSMutableArray array]];
    [_colorStack addObject:[NSColor whiteColor]];
  }
  return self;
}


- (void)setColor:(NSColor *)color {
  [color set];
  [_colorStack replaceObjectAtIndex:[_colorStack count] - 1 withObject:color];
}

- (void)setTransform:(NSAffineTransform *)transform {
  [transform set];
}


- (void)concat:(NSAffineTransform *)transform {
  [transform concat];
}

- (void)saveGraphicsState {
  [_context saveGraphicsState];
  [_colorStack addObject:[[_colorStack lastObject] copy]];
}

- (void)restoreGraphicsState {
  [_context restoreGraphicsState];
  [_colorStack removeLastObject];
}

- (void)fillPath:(BezierPath *)path {
  // use the commands of the path and the lastObject of the transformStack and colorStacks to write the SVG
  NSString *rgb = [[_colorStack lastObject] asRGBString];
  NSMutableArray *attributes = [NSMutableArray array];
  NSString *style = [NSString stringWithFormat:@"style=\"fill:%@;stroke:none;\"", rgb];
  [attributes addObject:style];
  NSString *transform = [[self currentTransform] asSVG];
  if ([transform length]) {
    [attributes addObject:transform];
  }
  [self outLog:[path asSVGWithAttributes:[attributes componentsJoinedByString:@" "]]];
}

- (void)strokePath:(BezierPath *)path {
  // use the commands of the path and the lastObject of the transformStack and colorStacks to write the SVG
  NSString *rgb = [[_colorStack lastObject] asRGBString];
  NSMutableArray *attributes = [NSMutableArray array];
  NSString *style = [NSString stringWithFormat:@"style=\"fill:none;stroke:%@;\"", rgb];
  [attributes addObject:style];
  NSString *transform = [[self currentTransform] asSVG];
  if ([transform length]) {
    [attributes addObject:transform];
  }
  [self outLog:[path asSVGWithAttributes:[attributes componentsJoinedByString:@" "]]];
}

- (NSAffineTransform *)currentTransform {
  NSAffineTransform *result = [[NSAffineTransform alloc] init];
  CGContextRef c = (CGContextRef)[_context graphicsPort];
  CGAffineTransform t = CGContextGetCTM(c);
  [result setTransformStruct:*(NSAffineTransformStruct *)&t];
  return result;
}

- (void)openSVG {
  [self outLog:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!DOCTYPE svg PUBLIC "
  "\"-//W3C//DTD SVG 20010904//EN\" \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n"
  "<svg version=\"1.0\" xmlns=\"http://www.w3.org/2000/svg\" "
  "xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" "
  "width=\"1152px\" height=\"1152px\" xml:space=\"preserve\">\n"];
}

- (void)closeSVG {
  [self outLog:@"</svg>\n"];
}

- (void)openGroupNamed:(NSString *)name {
  if ([name length]) {
    [self outLog:[NSString stringWithFormat:@"<g id=\"%@\">\n", name]];
  } else {
    [self outLog:@"<g>\n"];
  }
}

- (void)closeGroup {
  [self outLog:@"</g>\n"];
}


- (void)outLog:(NSString *)s {
  printf("%s", [s UTF8String]);
}


@end
