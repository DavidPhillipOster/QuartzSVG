//
//  Utils.m
//  Cutter
//
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 3/2/14.
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

#import "Utils.h"

// y=0 is at the bottom of the canvas!

float RectArea(CGRect r) {
  return r.size.width*r.size.height;
}

CGRect FrameToFit(CGRect r, CGFloat aspectRatio) {
  if (r.size.width*aspectRatio < r.size.height) {
    r.size.height = r.size.width*aspectRatio;
  } else {
    r.size.width = r.size.height/aspectRatio;
  }
  return r;
}
