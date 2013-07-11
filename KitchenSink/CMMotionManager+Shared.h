//
//  CMMotionManager+Shared.h
//  KitchenSink
//
//  Created by Mads Bielefeldt on 10/07/13.
//  Copyright (c) 2013 GN ReSound A/S. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

@interface CMMotionManager (Shared)

+ (CMMotionManager *)sharedMotionManager;

@end
