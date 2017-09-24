//
//  MMTencentWeiboShareItem.m
//  LooseLeaf
//
//  Created by Adam Wulf on 8/8/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMTencentWeiboShareItem.h"
#import "MMProgressedImageViewButton.h"
#import "Mixpanel.h"
#import "Constants.h"
#import "NSThread+BlockAdditions.h"
#import "MMReachabilityManager.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "MMPresentationWindow.h"


@implementation MMTencentWeiboShareItem {
    MMProgressedImageViewButton* button;
}

@synthesize delegate;

- (id)init {
    if (self = [super init]) {
        button = [[MMProgressedImageViewButton alloc] initWithFrame:CGRectMake(0, 0, kWidthOfSidebarButton, kWidthOfSidebarButton)];
        [button setImage:[UIImage imageNamed:@"tencentWeibo"]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateButtonGreyscale)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateButtonGreyscale)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];

        [button addTarget:self action:@selector(performShareAction) forControlEvents:UIControlEventTouchUpInside];

        [self updateButtonGreyscale];
    }
    return self;
}

- (MMSidebarButton*)button {
    return button;
}

- (void)performShareAction {
    [delegate mayShare:self];
    // if a popover controller is dismissed, it
    // adds the dismissal to the main queue async
    // so we need to add our next steps /after that/
    // so we need to dispatch async too
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            SLComposeViewController* fbSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTencentWeibo];
            if (fbSheet && [MMReachabilityManager sharedManager].currentReachabilityStatus != NotReachable && [self.delegate urlToShare]) {
                MMPresentationWindow* presentationWindow = [(MMAppDelegate*)[[UIApplication sharedApplication] delegate] presentationWindow];
                UIImage* imgToShare = [UIImage imageWithData:[NSData dataWithContentsOfURL:[self.delegate urlToShare]]];
                [fbSheet addImage:imgToShare];
                fbSheet.completionHandler = ^(SLComposeViewControllerResult result) {
                    NSString* strResult;
                    if (result == SLComposeViewControllerResultCancelled) {
                        strResult = @"Cancelled";
                    } else {
                        strResult = @"Sent";
                    }
                    if (result == SLComposeViewControllerResultDone) {
                        [[[Mixpanel sharedInstance] people] increment:kMPNumberOfSocialExports by:@(1)];
                        [[[Mixpanel sharedInstance] people] increment:kMPNumberOfExports by:@(1)];
                    }
                    [[Mixpanel sharedInstance] track:kMPEventExport properties:@{ kMPEventExportPropDestination: @"TencentWeibo",
                                                                                  kMPEventExportPropResult: strResult }];
                    [presentationWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
                };

                [presentationWindow.rootViewController presentViewController:fbSheet animated:YES completion:nil];

                [delegate didShare:self];
            } else {
                [button animateToPercent:1.0 success:NO completion:nil];
            }
        }
    });
}

- (BOOL)isAtAllPossibleForMimeType:(NSString*)mimeType {
    return [mimeType hasPrefix:@"image"] && [SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo];
}

#pragma mark - Notification

- (void)updateButtonGreyscale {
    if (![self.delegate urlToShare]) {
        button.greyscale = YES;
    } else if ([MMReachabilityManager sharedManager].currentReachabilityStatus == NotReachable) {
        button.greyscale = YES;
    } else if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
        button.greyscale = YES;
    } else {
        button.greyscale = NO;
    }
    [button setNeedsDisplay];

    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
        [[[Mixpanel sharedInstance] people] set:kMPShareStatusTencentWeibo to:kMPShareStatusAvailable];
    } else {
        [[[Mixpanel sharedInstance] people] set:kMPShareStatusTencentWeibo to:kMPShareStatusUnavailable];
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
