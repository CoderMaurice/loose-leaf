//
//  MMPageCacheManagerDelegate.h
//  LooseLeaf
//
//  Created by Adam Wulf on 4/21/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMPaperView;

@protocol MMPageCacheManagerDelegate <NSObject>

- (BOOL)isPageInVisibleStack:(MMPaperView*)page;

- (MMPaperView*)getPageBelow:(MMPaperView*)page;

- (NSArray*)findPagesInVisibleRowsOfListView;

- (NSArray*)pagesInCurrentBezelGesture;

- (BOOL)isShowingPageView;

- (BOOL)isShowingListView;

- (BOOL)isShowingCollapsedView:(NSString*)stackUUID;

- (NSInteger)countAllPages;

@end
