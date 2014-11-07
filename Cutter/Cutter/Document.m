//
//  Document.m
//  Cutter
//
//  Created by David Phillip Oster, DavidPhillipOster+Cutter@gmail.com on 3/1/14.
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

#import "Document.h"
#import <objc/runtime.h>

@interface Document()
@property NSMutableArray *model;
@end

@implementation Document

- (NSString *)windowNibName {
  // Override returning the nib file name of the document
  // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
  return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [super windowControllerDidLoadNib:aController];

  unsigned int count;
  Class *cclasses = objc_copyClassList(&count);

  NSMutableArray *aModel = [NSMutableArray array];
  for (int i = 0; i < count; ++i) {
    Class cclass = cclasses[i];
    Class supercclass = class_getSuperclass(cclass);
    for (;supercclass;supercclass = class_getSuperclass(supercclass)) {
      NSString *superName = NSStringFromClass(supercclass);
      if ([superName isEqual:@"CutView"]) {
        [aModel addObject:NSStringFromClass(cclass)];
        break;
      } else if ([superName isEqual:@"NSObject"] || [superName isEqual:@"NSProxy"]) {
        break;
      }
    }
  }
  free(cclasses);
  [aModel sortUsingSelector:@selector(caseInsensitiveCompare:)];
  _model = aModel;

  [self selectIndex:0];
}

+ (BOOL)autosavesInPlace {
  return YES;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
  return NO;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
  // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
  // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
  NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
  @throw exception;
  return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [_model count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return _model[row];
}

- (void)selectIndex:(NSUInteger)index {
  [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  if ([[_contentHolder subviews] count]) {
    NSView *view = [[_contentHolder subviews] lastObject];
    [view removeFromSuperview];
  }
  if ([[_tableView selectedRowIndexes] count]) {
    NSUInteger index = [[_tableView selectedRowIndexes] firstIndex];
    NSString *classNameString = _model[index];
    Class viewClass = NSClassFromString(classNameString);
    if (viewClass) {
      NSRect bounds = [_contentHolder bounds];
      NSView *view = [[viewClass alloc] initWithFrame:bounds];
      [view setAutoresizingMask:0x3F];
      [_contentHolder addSubview:view];
    }
  }
}




@end
