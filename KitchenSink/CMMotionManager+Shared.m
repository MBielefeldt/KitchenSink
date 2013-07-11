//
//  CMMotionManager+Shared.m
//  KitchenSink
//
//  Created by Mads Bielefeldt on 10/07/13.
//  Copyright (c) 2013 GN ReSound A/S. All rights reserved.
//

#import "CMMotionManager+Shared.h"

@implementation CMMotionManager (Shared)

+ (CMMotionManager *)sharedMotionManager
{
    static CMMotionManager *sharedMotionManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMotionManager = [[CMMotionManager alloc] init];
    });
    
    return sharedMotionManager;
}

@end
