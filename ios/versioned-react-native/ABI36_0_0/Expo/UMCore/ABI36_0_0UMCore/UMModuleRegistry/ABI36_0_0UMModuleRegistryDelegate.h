// Copyright © 2018 650 Industries. All rights reserved.

#import <Foundation/Foundation.h>

#import <ABI36_0_0UMCore/ABI36_0_0UMInternalModule.h>

@protocol ABI36_0_0UMModuleRegistryDelegate <NSObject>

- (id<ABI36_0_0UMInternalModule>)pickInternalModuleImplementingInterface:(Protocol *)interface fromAmongModules:(NSArray<id<ABI36_0_0UMInternalModule>> *)internalModules;

@end
