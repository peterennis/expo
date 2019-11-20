// Copyright 2015-present 650 Industries. All rights reserved.

#import <ABI36_0_0React/ABI36_0_0RCTEventEmitter.h>

@interface ABI36_0_0EXAppState : ABI36_0_0RCTEventEmitter

/**
 *  Kernel manages the state of each bridge and passes it here. 
 */
- (void)setState:(NSString *)state;

@property (nonatomic, strong, readonly) NSString *lastKnownState;

@end
