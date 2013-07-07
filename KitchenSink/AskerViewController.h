//
//  AskerViewController.h
//  KitchenSink
//
//  Created by Mads Bielefeldt on 07/07/13.
//  Copyright (c) 2013 GN ReSound A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AskerViewController : UIViewController

@property (nonatomic, strong) NSString *question;
@property (nonatomic, readonly) NSString *answer;

@end
