//
//  MMAppDelegate.m
//  Loose Leaf
//
//  Created by Adam Wulf on 6/7/12.
//  Copyright (c) 2012 Milestone Made, LLC. All rights reserved.
//

#import "MMAppDelegate.h"

#import "MMLooseLeafViewController.h"
#import "MMTouchDotView.h"
#import <Crashlytics/Crashlytics.h>
#import "NSString+UUID.h"
#import "SSKeychain.h"
#import "Mixpanel.h"


@implementation MMAppDelegate{
    CFAbsoluteTime sessionStartStamp;
    NSTimer* durationTimer;
    CFAbsoluteTime resignedActiveAtStamp;
}

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"launching");
    [Crashlytics startWithAPIKey:@"9e59cb6d909c971a2db30c84cb9be7f37273a7af"];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    [[Mixpanel sharedInstance] identify:[MMAppDelegate userID]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[MMLooseLeafViewController alloc] init];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
//    [self.window.layer setSpeed:.5f];
    MMTouchDotView* blueDots = [[MMTouchDotView alloc] initWithFrame:self.window.bounds];
    [self.window addSubview:blueDots];

    // fire timer each minute
    [self setupTimer];
    
    return YES;
}

//-(void) asdfasdf:(id)foo{
//    @throw [NSException exceptionWithName:@"foobar" reason:@"uh oh" userInfo:nil];
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"WILL RESIGN ACTIVE");
    [self.viewController willResignActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    resignedActiveAtStamp = CFAbsoluteTimeGetCurrent();
    [self logActiveAppDuration];
    [durationTimer invalidate];
    durationTimer = nil;
    NSLog(@"DID ENTER BACKGROUND");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"WILL ENTER FOREGROUND");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self setupTimer];
    if((CFAbsoluteTimeGetCurrent() - resignedActiveAtStamp) / 60.0 > 5){
        // they resigned active over 5 minutes ago, treat this
        // as a new launch
        //
        // this'll also trigger when the app first launches, as resignedActiveStamp == 0
        [[[Mixpanel sharedInstance] people] increment:kMPNumberOfLaunches by:@(1)];
        [[Mixpanel sharedInstance] track:kMPEventLaunch];
    };
    NSLog(@"DID BECOME ACTIVE");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self logActiveAppDuration];
    [durationTimer invalidate];
    durationTimer = nil;
    NSLog(@"WILL TERMINATE");
}

-(void) logActiveAppDuration{
    [[[Mixpanel sharedInstance] people] increment:kMPDurationAppOpen by:@((CFAbsoluteTimeGetCurrent() - sessionStartStamp) / 60.0)];
}



-(void) setupTimer{
    sessionStartStamp = CFAbsoluteTimeGetCurrent();
    // track every five minutes that the app is open
    durationTimer = [NSTimer scheduledTimerWithTimeInterval:60 * 5
                                                     target:self
                                                   selector:@selector(durationTimerDidFire:)
                                                   userInfo:nil
                                                    repeats:YES];

}

-(void) durationTimerDidFire:(NSTimer*)timer{
    [self logActiveAppDuration];
    sessionStartStamp = CFAbsoluteTimeGetCurrent();
}




+(NSString*) userID{
    NSString *uuid = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:@"userID"];
    if(!uuid){
        uuid = [NSString createStringUUID];
        [SSKeychain setPassword:uuid forService:[[NSBundle mainBundle] bundleIdentifier] account:@"userID"];
    }
    return uuid;
}


@end
