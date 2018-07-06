//
//  MMUndoablePaperView.m
//  LooseLeaf
//
//  Created by Adam Wulf on 7/2/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMUndoablePaperView.h"
#import "MMEditablePaperViewSubclass.h"
#import "MMUndoRedoBlockItem.h"
#import "MMEditablePaperView+UndoRedo.h"
#import "MMUndoRedoStrokeItem.h"
#import "MMUndoRedoAddScrapItem.h"
#import "MMUndoRedoRemoveScrapItem.h"
#import "MMUndoRedoBezeledScrapItem.h"
#import "MMUndoRedoGroupItem.h"
#import "MMUndoRedoMoveScrapItem.h"
#import "MMUndoRedoAddScrapFromBezelItem.h"
#import "MMScrapsInBezelContainerView.h"
#import "MMImmutableScrapsOnPaperState.h"
#import "MMTrashManager.h"
#import "MMStatTracker.h"
#import <ClippingBezier/ClippingBezier.h>
#import <PerformanceBezier/PerformanceBezier.h>


@implementation MMUndoablePaperView {
    NSString* undoStatePath;
}

@synthesize undoRedoManager;
@synthesize undoStatePath;

- (void)moveAssetsFrom:(id<MMPaperViewDelegate>)previousDelegate {
    [super moveAssetsFrom:previousDelegate];
    undoStatePath = nil;
}

- (NSUndoManager*)undoManager {
    @throw [NSException exceptionWithName:@"MMUnknownUndoManager" reason:@"undoManager property is disabled" userInfo:nil];
}

- (id)initWithFrame:(CGRect)frame andUUID:(NSString*)_uuid {
    if (self = [super initWithFrame:frame andUUID:_uuid]) {
        // Initialization code
        undoRedoManager = [[MMPageUndoRedoManager alloc] initForDelegatePage:self];
    }
    return self;
}

#pragma mark - MMScrapsOnPaperStateDelegate / MMScrapCollectionStateDelegate

- (void)didLoadAllScrapsFor:(MMScrapCollectionState*)scrapState {
    [super didLoadAllScrapsFor:scrapState];

    dispatch_block_t block = ^{
        @autoreleasepool {
            [undoRedoManager loadFrom:[self undoStatePath]];
        }
    };

    dispatch_async([self serialBackgroundQueue], block);
}

- (void)didUnloadAllScrapsFor:(MMScrapsOnPaperState*)scrapState {
    [super didUnloadAllScrapsFor:scrapState];
}

- (MMScrapsInBezelContainerView*)bezelContainerView {
    return self.delegate.bezelContainerView;
}

#pragma mark - Saving and Loading

- (void)saveToDiskHelper:(void (^)(BOOL))onComplete {
    // track if our back ground page has saved
    dispatch_semaphore_t sema1 = dispatch_semaphore_create(0);
    __block BOOL hadEditsToSave;
    [super saveToDiskHelper:^(BOOL _hadEditsToSave) {
        // save all our ink/strokes/thumbs/etc to disk
        hadEditsToSave = _hadEditsToSave;
        dispatch_semaphore_signal(sema1);
    }];

    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    if (undoRedoManager.isLoaded) {
        // only bother saving our undo/redo state
        // if its loaded
        // track if all of our scraps have saved
        dispatch_async([self serialBackgroundQueue], ^(void) {
            @autoreleasepool {
                // also write undostack to disk
                if (undoRedoManager.isLoaded) {
                    [undoRedoManager saveTo:[self undoStatePath]];
                }
            }
            dispatch_semaphore_signal(sema2);
        });
    } else {
        dispatch_semaphore_signal(sema2);
    }
    dispatch_async([self serialBackgroundQueue], ^(void) {
        @autoreleasepool {
            dispatch_semaphore_wait(sema1, DISPATCH_TIME_FOREVER);
            dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);

            if (onComplete)
                onComplete(hadEditsToSave);
        }
    });
}

- (void)unloadState {
    [super unloadState];
    [undoRedoManager unloadState];
}

#pragma mark - Undo / Redo of JotViews

- (void)undo {
    [super undo];
    [self debugPrintUndoStatus];
}

- (void)redo {
    [super redo];
    [self debugPrintUndoStatus];
}

#pragma mark - Methods That Trigger Undo

- (void)addUndoItemForScrap:(MMScrapView*)scrap thatMovedFrom:(NSDictionary*)startProperties to:(NSDictionary*)endProperties {
    [self.undoRedoManager addUndoItem:[MMUndoRedoMoveScrapItem itemForPage:self andScrapUUID:scrap.uuid from:startProperties to:endProperties]];
}

- (void)addUndoItemForRemovedScrap:(MMScrapView*)scrap withProperties:(NSDictionary*)scrapProperties {
    [self.undoRedoManager addUndoItem:[MMUndoRedoRemoveScrapItem itemForPage:self andScrapUUID:scrap.uuid andProperties:scrapProperties]];
}

- (void)addUndoItemForBezeledScrap:(MMScrapView*)scrap withProperties:(NSDictionary*)scrapProperties {
    [self.undoRedoManager addUndoItem:[MMUndoRedoBezeledScrapItem itemForPage:self andScrapUUID:scrap.uuid andProperties:scrapProperties]];
}

- (void)addUndoItemForAddedScrap:(MMScrapView*)scrap {
    [self.undoRedoManager addUndoItem:[MMUndoRedoAddScrapItem itemForPage:self andScrapUUID:scrap.uuid andProperties:[scrap propertiesDictionary]]];
}

- (void)addUndoItemForMostRecentAddedScrapFromBezelFromScrap:(MMScrapView*)scrapFromBezel {
    MMScrapView* scrap = nil;
    if (scrapFromBezel.state.scrapsOnPaperState != self.scrapsOnPaperState) {
        // scrap would have been cloned, get most recent scrap on page
        scrap = [self.scrapsOnPaperState mostRecentScrap];
    } else {
        // this scrap was owned by this page and added back from a tap on the bezel
        scrap = scrapFromBezel;
    }
    [self.undoRedoManager addUndoItem:[MMUndoRedoAddScrapFromBezelItem itemForPage:self andScrapUUID:scrap.uuid andProperties:[scrap propertiesDictionary]]];
}

- (MMScissorResult*)completeScissorsCutWithPath:(UIBezierPath*)scissorPath {
    if (![self isStateLoaded] || ![self.scrapsOnPaperState isStateLoaded]) {
        return nil;
    }

    // track scissor cuts:
    [[MMStatTracker trackerWithName:kMPStatScissorSegments] trackValue:[scissorPath elementCount]];


    MMScissorResult* result = [super completeScissorsCutWithPath:scissorPath];

    if ([result.addedScraps count] || [result.removedScraps count]) {
        NSMutableArray* undoItems = [NSMutableArray array];
        if ([result didAddFillStroke]) {
            [undoItems addObject:[MMUndoRedoStrokeItem itemForPage:self]];
        }
        for (MMScrapView* scrap in result.addedScraps) {
            [undoItems addObject:[MMUndoRedoAddScrapItem itemForPage:self andScrapUUID:scrap.uuid andProperties:[scrap propertiesDictionary]]];
        }
        for (int i = 0; i < [result.removedScraps count]; i++) {
            MMScrapView* scrap = [result.removedScraps objectAtIndex:i];
            NSDictionary* props = [result.removedScrapProperties objectAtIndex:i];
            [undoItems addObject:[MMUndoRedoRemoveScrapItem itemForPage:self andScrapUUID:scrap.uuid andProperties:props]];
        }

        [self.undoRedoManager addUndoItem:[MMUndoRedoGroupItem itemForPage:self withItems:undoItems]];
    }

    return result;
}

- (void)addStandardStrokeUndoItem {
    [self.undoRedoManager addUndoItem:[MMUndoRedoStrokeItem itemForPage:self]];
}

- (void)didEndStrokeWithCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    [super didEndStrokeWithCoalescedTouch:coalescedTouch fromTouch:touch inJotView:jotView];
    [self addStandardStrokeUndoItem];
    [self debugPrintUndoStatus];
}

- (void)didCancelStroke:(JotStroke*)stroke withCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    [super didCancelStroke:stroke withCoalescedTouch:coalescedTouch fromTouch:touch inJotView:jotView];
    // no undo change needed
    [self debugPrintUndoStatus];
}

- (void)addUndoLevelAndContinueStroke {
    [super addUndoLevelAndContinueStroke];
    [self addStandardStrokeUndoItem];
}

#pragma mark - Paths

- (NSString*)undoStatePath {
    if (!undoStatePath) {
        undoStatePath = [[[self pagesPath] stringByAppendingPathComponent:@"undoRedo"] stringByAppendingPathExtension:@"plist"];
    }
    return undoStatePath;
}


#pragma mark - Debug

- (void)debugPrintUndoStatus {
    //    return;
    //    DebugLog(@"**********************************************************************");
    //    DebugLog(@"Undo status");
    //    DebugLog(@" page %@", self.uuid);
    //    DebugLog(@"   currentStroke: %p", self.drawableView.state.currentStroke);
    //    DebugLog(@"   undoable stack: %i", (int)[self.drawableView.state.stackOfStrokes count]);
    //    DebugLog(@"   undone stack:   %i", (int)[self.drawableView.state.stackOfUndoneStrokes count]);
    //    DebugLog(@"scraps:");
    //    for(MMScrapView* scrap in [self.scrapsOnPaper reverseObjectEnumerator]){
    //        DebugLog(@" scrap %@", scrap.uuid);
    //        DebugLog(@"   currentStroke: %p", scrap.state.drawableView.state.currentStroke);
    //        DebugLog(@"   undoable stack: %i", (int)[scrap.state.drawableView.state.stackOfStrokes count]);
    //        DebugLog(@"   undone stack:   %i", (int)[scrap.state.drawableView.state.stackOfUndoneStrokes count]);
    //    }
    //    DebugLog(@"**********************************************************************");
}

- (BOOL)hasEditsToSave {
    return [super hasEditsToSave] || [undoRedoManager hasEditsToSave];
}

@end
