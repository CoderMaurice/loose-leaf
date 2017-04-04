//
//  MMBackgroundedPaperView.h
//  LooseLeaf
//
//  Created by Adam Wulf on 2/25/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import "MMUndoablePaperView.h"

typedef enum : NSInteger {
    ExportRotationBackgroundDefault = 0,
    ExportRotationLandscapeLeft,
    ExportRotationPortrait,
    ExportRotationLandscapeRight
} ExportRotation;

@class MMBackgroundPatternView;

@interface MMBackgroundedPaperView : MMUndoablePaperView

@property (nonatomic, assign) ExportRotation idealExportRotation;
@property (nonatomic, strong) MMBackgroundPatternView* ruledOrGridBackgroundView;

- (UIImage*)pageBackgroundTexture;

- (NSString*)backgroundTexturePath;

-(ExportRotation) idealExportRotation;

// saves the file at the input URL as the background's original
// asset file. This is useful for a background that is set as
// a UIImage but was generated from a PDF
- (void)saveOriginalBackgroundTextureFromURL:(NSURL*)originalAssetURL;

- (void)exportVisiblePageToPDF:(void (^)(NSURL* urlToPDF))completionBlock;

- (void)exportVisiblePageToImage:(void (^)(NSURL* urlToImage))completionBlock;

+ (void)writeBackgroundImageToDisk:(UIImage*)img backgroundTexturePath:(NSString*)backgroundTexturePath;

+ (void)writeThumbnailImagesToDisk:(UIImage*)img thumbnailPath:(NSString*)thumbnailPath scrappedThumbnailPath:(NSString*)scrappedThumbnailPath;

@end
