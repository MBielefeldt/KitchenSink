//
//  KitchenSinkViewController.m
//  KitchenSink
//
//  Created by Mads Bielefeldt on 07/07/13.
//  Copyright (c) 2013 GN ReSound A/S. All rights reserved.
//

#import "KitchenSinkViewController.h"
#import "AskerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CMMotionManager+Shared.h"

@interface KitchenSinkViewController ()  <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *kitchenSink;
@property (weak, nonatomic) NSTimer *drainTimer; // weak because system keeps a strong pointer to the timer
@property (weak, nonatomic) UIActionSheet *sinkControlActionSheet;
@property (strong, nonatomic) UIPopoverController *imagePickerPopover;

@end

@implementation KitchenSinkViewController

- (IBAction)addFoodPhoto:(UIBarButtonItem *)sender
{
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum sender:sender];
}

- (IBAction)takeFoodPhoto:(UIBarButtonItem *)sender
{
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera sender:sender];
}

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType sender:(UIBarButtonItem *)sender
{
    if (!self.imagePickerPopover && [UIImagePickerController isSourceTypeAvailable:sourceType]) {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
        if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            
            imagePickerController.sourceType = sourceType;
            imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
            imagePickerController.allowsEditing = YES;
            imagePickerController.delegate = self;
            
            if ((sourceType != UIImagePickerControllerSourceTypeCamera) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
                // present popover controller containing image picker controller
                self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
                self.imagePickerPopover.delegate = self;
                [self.imagePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            else {
                // present image picker controller
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
        }
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.imagePickerPopover = nil;
}

#define MAX_IMAGE_WIDTH 200

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        
        CGRect frame = imageView.frame;
        if (frame.size.width > MAX_IMAGE_WIDTH) {
            frame.size.height = (frame.size.height / frame.size.width) * MAX_IMAGE_WIDTH;
            frame.size.width = MAX_IMAGE_WIDTH;
        }
        imageView.frame = frame;
        
        [self setRandomLocationForView:imageView];
        [self.kitchenSink addSubview:imageView];
    }
 
    if (self.imagePickerPopover) {
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#define SINK_CONTROL_TITLE       NSLocalizedString(@"Sink Controls", @"Control sink action sheet header")
#define SINK_CONTROL_START_DRAIN NSLocalizedString(@"Start Drain", @"Control sink action sheet start drain item")
#define SINK_CONTROL_STOP_DRAIN  NSLocalizedString(@"Stop Drain", @"Control sink action sheet stop drain item")
#define SINK_CONTROL_CANCEL      NSLocalizedString(@"Cancel", @"Control sink action sheet cancel item")
#define SINK_CONTROL_EMPTY       NSLocalizedString(@"Empty Sink", @"Control sink action sheet empty drain item")

- (IBAction)controlSink:(UIBarButtonItem *)sender
{
    if (!self.sinkControlActionSheet) {
        NSString *drainButton = (self.drainTimer ? SINK_CONTROL_STOP_DRAIN : SINK_CONTROL_START_DRAIN);
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:SINK_CONTROL_TITLE
                                                                 delegate:self
                                                        cancelButtonTitle:SINK_CONTROL_CANCEL
                                                   destructiveButtonTitle:SINK_CONTROL_EMPTY
                                                         otherButtonTitles:drainButton, nil];
        [actionSheet showFromBarButtonItem:sender animated:YES];
        self.sinkControlActionSheet = actionSheet; // assigned here to make sure view keeps a strong pointer to the action sheet before assigning it to the weak property
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self.kitchenSink.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:SINK_CONTROL_START_DRAIN]) {
        [self startDrainTimer];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:SINK_CONTROL_STOP_DRAIN]) {
        [self stopDrainTimer];
    }
}

#define DISH_CLEANING_INTERVAL 2.0

- (void)cleanDish
{
    if (self.kitchenSink.window) {
        [self addFood:nil];
        [self performSelector:@selector(cleanDish) withObject:nil afterDelay:DISH_CLEANING_INTERVAL];
    }
}

#define DRAIN_DURATION 3.0
#define DRAIN_DELAY 1.0

- (void)startDrainTimer
{
    self.drainTimer = [NSTimer scheduledTimerWithTimeInterval:DRAIN_DURATION/3 target:self selector:@selector(drain:) userInfo:nil repeats:YES];
}

- (void)drain:(NSTimer *)timer
{
    [self drain];
}

- (void)stopDrainTimer
{
    [self.drainTimer invalidate];
    self.drainTimer = nil; // not really needed as this is a weak pointer, but good practice anyway...
}

- (void)drain
{
    for (UIView *view in self.kitchenSink.subviews) {
        CGAffineTransform transform = view.transform;
        if (CGAffineTransformIsIdentity(transform)) {
            [UIView animateWithDuration:DRAIN_DURATION/3 delay:DRAIN_DELAY options:UIViewAnimationOptionCurveLinear animations:^{
                view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.7, 0.7), 2*M_PI/3 * 1);
            } completion:^(BOOL finished){
                if (finished) [UIView animateWithDuration:DRAIN_DURATION/3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.4, 0.4), 2*M_PI/3 * 2);
                } completion:^(BOOL finished){
                    if (finished) [UIView animateWithDuration:DRAIN_DURATION/3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                        view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.1, 0.1), 2*M_PI/3 * 3);
                    } completion:^(BOOL finished){
                        if (finished) {
                            [view removeFromSuperview];
                        }
                    }];
                }];
            }];
        }
    }
}

#define DRIFT_HZ 10
#define DRIFT_RATE 100/DRIFT_HZ

- (void)startDrift
{
    CMMotionManager *motionManager = [CMMotionManager sharedMotionManager];
    
    if ([motionManager isAccelerometerAvailable]) {
        [motionManager setAccelerometerUpdateInterval:1/DRIFT_HZ];
        
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *data, NSError *error) {
            for (UIView *view in self.kitchenSink.subviews) {
                CGPoint center = view.center;
                center.x += data.acceleration.x * DRIFT_RATE;
                center.y -= data.acceleration.y * DRIFT_RATE;
                view.center = center;
                
                if ((!CGRectContainsRect(self.kitchenSink.bounds, view.frame)) && (!CGRectIntersectsRect(self.kitchenSink.bounds, view.frame))) {
                    [view removeFromSuperview];
                }
            }
        }];
    }
}

- (void)stopDrift
{
    [[CMMotionManager sharedMotionManager] stopAccelerometerUpdates];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startDrainTimer];
    [self cleanDish];
    [self startDrift];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopDrainTimer];
    [self stopDrift];
}

#define MOVE_DURATION 3.0

- (IBAction)tap:(UITapGestureRecognizer *)sender
{
    CGPoint tapLocation = [sender locationInView:self.kitchenSink];
    
    for (UIView *view in self.kitchenSink.subviews) {
        if (CGRectContainsPoint(view.frame, tapLocation)) {
            [UIView animateWithDuration:MOVE_DURATION delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setRandomLocationForView:view];
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.99, 0.99);
            } completion:^(BOOL finished){
                view.transform = CGAffineTransformIdentity;
            }];
        }
    }
}

#define BLUE_FOOD   NSLocalizedString(@"Jello", @"Blue food item")
#define GREEN_FOOD  NSLocalizedString(@"Broccoli", @"Green food item")
#define ORANGE_FOOD NSLocalizedString(@"Carrot", @"Orange food item")
#define RED_FOOD    NSLocalizedString(@"Pepper", @"Red food item")
#define PURPLE_FOOD NSLocalizedString(@"Eggplant", @"Purple food item")
#define BROWN_FOOD  NSLocalizedString(@"Potato Peels", @"Brown food item")

- (void)addFood:(NSString *)food
{
    UILabel *foodLabel = [[UILabel alloc] init];

    static NSDictionary *foods = nil;
    
    if (!foods) {
        foods = @{BLUE_FOOD     : [UIColor blueColor],
                  GREEN_FOOD    : [UIColor greenColor],
                  ORANGE_FOOD   : [UIColor orangeColor],
                  RED_FOOD      : [UIColor redColor],
                  PURPLE_FOOD   : [UIColor purpleColor],
                  BROWN_FOOD    : [UIColor brownColor]};
    }
    
    if (food == nil) {
        food = [[foods allKeys] objectAtIndex:(arc4random() % [foods count])];
        foodLabel.textColor = [foods objectForKey:food];
    }
    
    foodLabel.text = food;
    foodLabel.font = [UIFont systemFontOfSize:46];
    foodLabel.backgroundColor = [UIColor clearColor];
    [foodLabel sizeToFit];
    [self setRandomLocationForView:foodLabel];
    [self.kitchenSink addSubview:foodLabel];
}

- (void)setRandomLocationForView:(UIView *)view
{
    CGRect sinkBounds = CGRectInset(self.kitchenSink.bounds, view.frame.size.width / 2, view.frame.size.height / 2);
    CGFloat x = arc4random() % (int)sinkBounds.size.width + view.frame.size.width / 2;
    CGFloat y = arc4random() % (int)sinkBounds.size.height + view.frame.size.height / 2;
    view.center = CGPointMake(x, y);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Ask"]) {
        AskerViewController *askerVC = segue.destinationViewController;
        askerVC.question = NSLocalizedString(@"What food do you want in the sink?", @"Question posed when adding food");
    }
}

- (IBAction)cancelAsking:(UIStoryboardSegue *)segue
{
}

- (IBAction)doneAsking:(UIStoryboardSegue *)segue
{
    AskerViewController *askerVC = segue.sourceViewController;
    [self addFood:askerVC.answer];
}

@end
