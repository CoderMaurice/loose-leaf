//
//  MMTutorialManager.m
//  LooseLeaf
//
//  Created by Adam Wulf on 3/21/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import "MMTutorialManager.h"
#import "MMStopWatch.h"
#import "Mixpanel.h"
#import "Constants.h"
#import "MMAppDelegate.h"


@implementation MMTutorialManager {
    MMStopWatch* stopwatch;
    BOOL hasFinishedTutorial;
    CGFloat timeSpentInTutorial;
    NSInteger currentTutorialStep;
    NSOperationQueue* subscriptionOpQueue;
}

@synthesize hasFinishedTutorial;

#pragma mark - Singleton

static MMTutorialManager* _instance = nil;

- (id)init {
    if (_instance)
        return _instance;
    if ((self = [super init])) {
        //#ifdef DEBUG
        //        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMPHasFinishedTutorial];
        //
        //        for (NSDictionary* tutorial in [[[self appIntroTutorialSteps] arrayByAddingObjectsFromArray:[self allTutorialStepsEver]] arrayByAddingObjectsFromArray:[self shareTutorialSteps]]) {
        //            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[kCurrentTutorialStep stringByAppendingString:[tutorial objectForKey:@"id"]]];
        //        }
        //
        //        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHasIgnoredNewsletter];
        //        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHasSignedUpForNewsletter];
        //        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPendingEmailToSubscribe];
        //
        //        [[NSUserDefaults standardUserDefaults] synchronize];
        //
        //#endif

        hasFinishedTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:kMPHasFinishedTutorial];
        timeSpentInTutorial = [[NSUserDefaults standardUserDefaults] floatForKey:kMPDurationWatchingTutorial];
        currentTutorialStep = [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentTutorialStep];
        stopwatch = [[MMStopWatch alloc] initWithDuration:timeSpentInTutorial];
        subscriptionOpQueue = [[NSOperationQueue alloc] init];
        subscriptionOpQueue.maxConcurrentOperationCount = 1;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

+ (MMTutorialManager*)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[MMTutorialManager alloc] init];
    });
    return _instance;
}

#pragma mark - Public API

- (BOOL)hasCompletedStep:(NSString*)stepID {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[kCurrentTutorialStep stringByAppendingString:stepID]];
}

- (void)didCompleteStep:(NSString*)stepID {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[kCurrentTutorialStep stringByAppendingString:stepID]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTutorialStepCompleteNotification object:stepID];
}

- (NSInteger)numberOfPendingTutorials:(NSArray*)possiblyPendingTutorials {
    __block NSInteger numCompleted = 0;

    [possiblyPendingTutorials enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        numCompleted += [self hasCompletedStep:[obj objectForKey:@"id"]] ? 1 : 0;
    }];

    return [possiblyPendingTutorials count] - numCompleted;
}

- (NSArray*)allTutorialStepsEver {
    return [[[self appIntroTutorialSteps] arrayByAddingObjectsFromArray:[self listViewTutorialSteps]] arrayByAddingObjectsFromArray:[self shareTutorialSteps]];
}

- (NSArray*)appIntroTutorialSteps {
    return [@[
        @{
            @"id": @"app-welcome",
            @"title": @"",
            @"video": @"new-user-intro.png",
            @"hide-buttons": @(YES)
        }
    ] arrayByAddingObjectsFromArray:[self appHelpButtonTutorialSteps]];
}

- (NSArray*)appHelpButtonTutorialSteps {
    return @[
        @{
            @"id": @"app-intro-pen",
            @"title": NSLocalizedString(@"Draw and Erase", @"Draw and Erase"),
            @"video": @"draw-tools.mp4"
        },
        @{
            @"id": @"app-intro-pinch",
            @"title": NSLocalizedString(@"Pinch to See Your Pages", @"Pinch to See Your Pages"),
            @"video": @"pinch-to-list.mp4"
        },
        @{
            @"id": @"app-intro-import-scissor",
            @"title": NSLocalizedString(@"Import and Crop Your Photos", @"Import and Crop Your Photos"),
            @"video": @"import-and-scissor.mov"
        },
        @{
            @"id": @"app-intro-scrap-sidebar",
            @"title": NSLocalizedString(@"Move Scraps Between Pages", @"Move Scraps Between Pages"),
            @"video": @"scrap-to-sidebar.mov"
        },
        @{
            @"id": @"app-intro-scrap-reorder",
            @"title": NSLocalizedString(@"Shake a Scrap to Reorder", @"Shake a Scrap to Reorder"),
            @"video": @"shake-to-reorder.mov"
        },
        @{
            @"id": @"app-intro-mirror",
            @"title": NSLocalizedString(@"Mirror Your Drawing", @"Mirror Your Drawing"),
            @"video": @"new-user-7-mirror.mp4"
        },
        @{
            @"id": @"app-intro-export",
            @"title": NSLocalizedString(@"Export Your Pages", @"Export Your Pages"),
            @"video": @"export-to-facebook.mov"
        }
    ];
}

- (NSArray*)stackViewTutorialSteps {
    return @[
        @{
            @"id": @"collapse-stack",
            @"title": NSLocalizedString(@"Move Between Pages", @"Move Between Pages"),
            @"video": @"collapse-stack.mp4"
        },
        @{
            @"id": @"reorder-stack",
            @"title": NSLocalizedString(@"Organize Your pages", @"Organize Your pages"),
            @"video": @"reorder-stack.mp4"
        },
        @{
            @"id": @"delete-stack",
            @"title": NSLocalizedString(@"Delete Your Notes", @"Delete Your Notes"),
            @"video": @"delete-stack.mp4"
        },
        @{
            @"id": @"export-stack",
            @"title": NSLocalizedString(@"Export Your Notes", @"Export Your Notes"),
            @"video": @"export-stack.mp4"
        },
        @{
            @"id": @"import-stack",
            @"title": NSLocalizedString(@"Import Full PDFs", @"Import Full PDFs"),
            @"video": @"import-stack.mp4"
        }
    ];
}

- (NSArray*)listViewTutorialSteps {
    return @[
        @{
            @"id": @"list-view-reorder-pages",
            @"title": NSLocalizedString(@"Organize Your Pages", @"Organize Your Pages"),
            @"video": @"list-view-reorder-pages.mov"
        },
        @{
            @"id": @"page-sidebar",
            @"title": NSLocalizedString(@"Organize Your Pages", @"Organize Your Pages"),
            @"video": @"page-sidebar.mp4"
        },
        @{
            @"id": @"list-view-delete-page",
            @"title": NSLocalizedString(@"Delete a Page", @"Delete a Page"),
            @"video": @"list-view-delete-page.mov"
        },
        @{
            @"id": @"list-view-clone-page",
            @"title": NSLocalizedString(@"Duplicate a Page", @"Duplicate a Page"),
            @"video": @"list-view-clone-page.mp4"
        }
    ];
}

- (NSArray*)shareTutorialSteps {
    return @[
        @{
            @"id": @"share-social",
            @"title": NSLocalizedString(@"Share to Your Social Networks", @"Share to Your Social Networks"),
            @"video": @"share-tutorials-social.png"
        },
        @{
            @"id": @"share-contact",
            @"title": NSLocalizedString(@"Share Your Pages with Your Contacts", @"Share Your Pages with Your Contacts"),
            @"video": @"share-tutorials-contacts.png"
        },
        @{
            @"id": @"share-export",
            @"title": NSLocalizedString(@"Export Your Pages to Anywhere", @"Export Your Pages to Anywhere"),
            @"video": @"share-tutorials-export.png"
        }
    ];
}

- (BOOL)isWatchingTutorial {
    return [stopwatch isRunning];
}

- (void)startWatchingTutorials:(NSArray*)tutorialList {
    [stopwatch start];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTutorialStartedNotification object:self userInfo:@{ @"tutorialList": tutorialList }];
}

- (void)pauseWatchingTutorial {
    timeSpentInTutorial = [stopwatch stop];
    [[[Mixpanel sharedInstance] people] set:kMPDurationWatchingTutorial to:@(timeSpentInTutorial)];
    [[NSUserDefaults standardUserDefaults] setFloat:timeSpentInTutorial forKey:kMPDurationWatchingTutorial];
    [[Mixpanel sharedInstance] flush];
}

- (void)finishWatchingTutorial {
    [self pauseWatchingTutorial];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMPHasFinishedTutorial];
    [[[Mixpanel sharedInstance] people] set:kMPHasFinishedTutorial to:@(YES)];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTutorialClosedNotification object:self];
    hasFinishedTutorial = YES;
    [[Mixpanel sharedInstance] flush];
}


#pragma mark - Newsletter


- (BOOL)hasSignedUpForNewsletter {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kHasSignedUpForNewsletter] ||
        [[NSUserDefaults standardUserDefaults] boolForKey:kHasIgnoredNewsletter];
}


- (void)optOutOfNewsletter {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasIgnoredNewsletter];
    [[Mixpanel sharedInstance] track:kMPNewsletterResponse properties:@{ kMPNewsletterResponseSubscribed: @(NO) }];
    [[[Mixpanel sharedInstance] people] set:kMPNewsletterStatus to:@"Opt Out"];
    [[Mixpanel sharedInstance] flush];
}

- (void)signUpForNewsletter:(NSString*)email {
    [[Mixpanel sharedInstance] track:kMPNewsletterResponse properties:@{ kMPNewsletterResponseSubscribed: @(YES) }];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSignedUpForNewsletter];
    [[[Mixpanel sharedInstance] people] set:kMPNewsletterStatus to:@"Subscribed"];
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:kPendingEmailToSubscribe];
    [MMAppDelegate setEmail:email];
    [[[Mixpanel sharedInstance] people] set:kMPEmailAddressField to:email];
    [[Mixpanel sharedInstance] flush];
}


#pragma mark - Notifications

- (void)didEnterBackground {
    [self pauseWatchingTutorial];
}

#pragma mark - Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
