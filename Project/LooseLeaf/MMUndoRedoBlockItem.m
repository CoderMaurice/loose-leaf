//
//  MMUndoRedoBlockItem.m
//  LooseLeaf
//
//  Created by Adam Wulf on 7/2/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMUndoRedoBlockItem.h"
#import "Constants.h"
#import <JotUI/JotUI.h>

@implementation MMUndoRedoBlockItem{
    void (^_undoBlock)();
    void (^_redoBlock)();
    
    // YES if the item can undo,
    // NO if it can redo
    BOOL canUndo;
}

+(MMUndoRedoBlockItem*) itemWithUndoBlock:(void(^)())undoBlock andRedoBlock:(void(^)())redoBlock{
    return [[MMUndoRedoBlockItem alloc] initWithUndoBlock:undoBlock andRedoBlock:redoBlock];
}

/** Initialize with the provided block. */
- (id) initWithUndoBlock:(void(^)())undoBlock andRedoBlock:(void(^)())redoBlock {
    if ((self = [super init]) == nil)
        return nil;
    
    /* Blocks must be copied */
    _undoBlock = [undoBlock copy];
    _redoBlock = [redoBlock copy];
    canUndo = YES;
    
    return self;
}

-(void) undo{
    CheckMainThread;
    if(canUndo){
        canUndo = NO;
        _undoBlock();
    }else{
        @throw [NSException exceptionWithName:@"MMUndoInconsistencyException" reason:@"undo item is already undone" userInfo:nil];
    }
}

-(void) redo{
    CheckMainThread;
    if(!canUndo){
        canUndo = YES;
        _redoBlock();
    }else{
        @throw [NSException exceptionWithName:@"MMUndoInconsistencyException" reason:@"redo item is already redone" userInfo:nil];
    }
}

-(void) finalizeUndoneState{
    NSLog(@"finalizeUndoneState");
}

-(void) finalizeRedoneState{
    NSLog(@"finalizeRedoneState");
}

#pragma mark - Save and Load

-(NSDictionary*) asDictionary{
    @throw [NSException exceptionWithName:@"CannotSaveItemException" reason:@"This class cannot be serialized to a dictionary" userInfo:nil];
}

-(id) initFromDictionary:(NSDictionary*)dict forPage:(MMUndoablePaperView*)page{
    @throw [NSException exceptionWithName:@"CannotLoadItemException" reason:@"This class cannot be initialized from a dictionary" userInfo:nil];
}

@end