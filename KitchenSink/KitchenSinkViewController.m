//
//  KitchenSinkViewController.m
//  KitchenSink
//
//  Created by Mads Bielefeldt on 07/07/13.
//  Copyright (c) 2013 GN ReSound A/S. All rights reserved.
//

#import "KitchenSinkViewController.h"
#import "AskerViewController.h"

@interface KitchenSinkViewController ()

@end

@implementation KitchenSinkViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Ask"]) {
        AskerViewController *askerVC = segue.destinationViewController;
        askerVC.question = @"What food do you want in the sink?";
    }
}

- (IBAction)cancelAsking:(UIStoryboardSegue *)segue
{
}

- (IBAction)doneAsking:(UIStoryboardSegue *)segue
{
    AskerViewController *askerVC = segue.sourceViewController;
    NSLog(@"%@", askerVC.answer);
}

@end
