//
//  MMImageImporter.m
//  LooseLeaf
//
//  Created by Adam Wulf on 5/21/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMInboxManager.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "NSURL+UTI.h"
#import "MMPDFInboxItem.h"
#import "MMImageInboxItem.h"
#import "MMInboxItem+Protected.h"
#import "NSString+UUID.h"
#import "Constants.h"
#import "NSArray+MapReduce.h"
#import "NSFileManager+DirectoryOptimizations.h"
#include <CommonCrypto/CommonDigest.h>
#import "Mixpanel.h"


@implementation MMInboxManager {
    NSString* pdfInboxFolderPath;
    NSMutableArray<MMInboxItem*>* contents;
}

@synthesize delegate;

static MMInboxManager* _instance = nil;

+ (MMInboxManager*)sharedInstance {
    if (!_instance) {
        _instance = [[MMInboxManager alloc] init];
    }
    return _instance;
}

- (id)init {
    if (self = [super init]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadContents];
        });
    }
    return self;
}

- (NSString*)pdfInboxFolderPath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* documentsPath = [NSFileManager documentsPath];
        pdfInboxFolderPath = [documentsPath stringByAppendingPathComponent:@"PDFInbox"];
        [NSFileManager ensureDirectoryExistsAtPath:pdfInboxFolderPath];
    });
    return pdfInboxFolderPath;
}

#pragma mark - Dispatch Queue

static dispatch_queue_t fileSystemQueue;

+ (dispatch_queue_t)fileSystemQueue {
    if (!fileSystemQueue) {
        fileSystemQueue = dispatch_queue_create("com.milestonemade.looseleaf.inboxFileSystemQueue", DISPATCH_QUEUE_SERIAL);
    }
    return fileSystemQueue;
}

- (NSString*)shaForURL:(NSURL*)url {
    CC_SHA1_CTX ctx;
    CC_SHA1_Init(&ctx);
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];

    uint8_t buffer[2048];
    NSInputStream* inStream = [[NSInputStream alloc] initWithURL:url];
    [inStream open];

    do {
        NSInteger bytesRead = [inStream read:buffer maxLength:2048];
        if (bytesRead != -1) {
            CC_SHA1_Update(&ctx, buffer, (CC_LONG)bytesRead);
        } else {
            [[Mixpanel sharedInstance] track:kMPEventCrashAverted properties:@{ @"Error": [[inStream streamError] description] }];
            return nil;
        }
    } while ([inStream hasBytesAvailable]);

    [inStream close];

    CC_SHA1_Final(digest, &ctx);

    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;
}

- (MMInboxItem*)inboxItemForSha:(NSString*)sha {
    for (MMInboxItem* item in contents) {
        NSString* filename = [[[item urlOnDisk] lastPathComponent] stringByDeletingPathExtension];
        if ([filename isEqualToString:sha]) {
            return item;
        }
    }

    return nil;
}

#pragma mark - Protected Methods

- (NSURL*)moveURLIntoInbox:(NSURL*)itemURL withSha:(NSString*)sha {
    NSString* ourInbox = [self pdfInboxFolderPath];

    __block NSURL* foundURL = nil;

    [[NSFileManager defaultManager] enumerateDirectory:ourInbox withBlock:^(NSURL* item, NSUInteger totalItemCount) {
        NSString* filename = [[item lastPathComponent] stringByDeletingPathExtension];
        if ([filename isEqualToString:sha]) {
            foundURL = item;
        }
    } andErrorHandler:nil];

    if (foundURL) {
        return foundURL;
    }

    NSString* itemName = [sha stringByAppendingPathExtension:[itemURL pathExtension]];
    ourInbox = [ourInbox stringByAppendingPathComponent:itemName];
    NSURL* ourInboxURL = [[NSURL alloc] initFileURLWithPath:ourInbox];

    NSError* err = nil;
    [[NSFileManager defaultManager] moveItemAtURL:itemURL toURL:ourInboxURL error:&err];
    return ourInboxURL;
}

// process the item, and then remove it from disk
// if appropriate
- (void)processInboxItem:(NSURL*)itemURL fromApp:(NSString*)sourceApplication {
    NSString* uti = [itemURL universalTypeID];

    NSString* sha = [self shaForURL:itemURL] ?: [[NSUUID UUID] UUIDString];

    MMInboxItem* existingItem = [self inboxItemForSha:sha];

    if ([existingItem isKindOfClass:[MMImageInboxItem class]]) {
        [self.delegate didProcessIncomingImage:(MMImageInboxItem*)existingItem fromURL:[existingItem urlOnDisk] fromApp:sourceApplication];
    } else if ([existingItem isKindOfClass:[MMPDFInboxItem class]]) {
        [self.delegate didProcessIncomingPDF:(MMPDFInboxItem*)existingItem fromURL:[existingItem urlOnDisk] fromApp:sourceApplication];
    } else if (UTTypeConformsTo((__bridge CFStringRef)(uti), kUTTypeImage)) {
        NSURL* ourInboxURL = [self moveURLIntoInbox:itemURL withSha:sha];
        MMImageInboxItem* importedImage = [[MMImageInboxItem alloc] initWithURL:ourInboxURL];
        @synchronized(self) {
            [contents insertObject:importedImage atIndex:0];
        }
        [self.delegate didProcessIncomingImage:importedImage fromURL:itemURL fromApp:sourceApplication];
    } else if (UTTypeConformsTo((__bridge CFStringRef)(uti), kUTTypePDF)) {
        [itemURL hash];

        NSURL* ourInboxURL = [self moveURLIntoInbox:itemURL withSha:sha];

        MMPDFInboxItem* importedPDF = [[MMPDFInboxItem alloc] initWithURL:ourInboxURL];
        @synchronized(self) {
            [contents insertObject:importedPDF atIndex:0];
        }
        [self.delegate didProcessIncomingPDF:importedPDF fromURL:ourInboxURL fromApp:sourceApplication];
    } else {
        [self.delegate failedToProcessIncomingURL:itemURL fromApp:sourceApplication];
    }
}

// remove the item from disk on our disk queue
- (void)removeInboxItem:(NSURL*)itemURL onComplete:(void (^)(BOOL err))onComplete {
    __block MMInboxItem* inboxItemToRemove = nil;
    [contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        MMInboxItem* inboxItem = obj;
        if ([[inboxItem urlOnDisk] isEqual:itemURL]) {
            inboxItemToRemove = inboxItem;
        }
    }];
    [contents removeObject:inboxItemToRemove];
    DebugLog(@"removing inbox item: %@ contents now has %d items", inboxItemToRemove, (int)[contents count]);
    dispatch_async([MMInboxManager fileSystemQueue], ^{
        @autoreleasepool {
            //Clean up the inbox once the file has been processed
            BOOL error = NO;
            if (inboxItemToRemove) {
                @synchronized(self) {
                    error = [inboxItemToRemove deleteAssets];
                }
            }
            if (onComplete) {
                onComplete(error);
            }
        }
    });
}


#pragma mark - Inbox items

- (void)loadContents {
    @synchronized(self) {
        if (contents) {
            @throw [NSException exceptionWithName:@"InboxManagerException" reason:@"contents cannot load twice" userInfo:nil];
        }
        contents = [NSMutableArray array];

        NSURL* pdfInboxFolder = [[NSURL alloc] initFileURLWithPath:[self pdfInboxFolderPath]];
        NSDirectoryEnumerator* dir = [[NSFileManager defaultManager] enumeratorAtURL:pdfInboxFolder
                                                          includingPropertiesForKeys:@[NSURLPathKey, kURLAddedToDirectoryKey]
                                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                        errorHandler:nil];

        for (NSURL* url in [dir allObjects]) {
            NSString* uti = [url universalTypeID];
            if (UTTypeConformsTo((__bridge CFStringRef)(uti), kUTTypeImage)) {
                [contents addObject:[[MMImageInboxItem alloc] initWithURL:url]];
            } else if (UTTypeConformsTo((__bridge CFStringRef)(uti), kUTTypePDF)) {
                [contents addObject:[[MMPDFInboxItem alloc] initWithURL:url]];
            }
        }
        [contents sortUsingComparator:^NSComparisonResult(MMInboxItem* obj1, MMInboxItem* obj2) {
            NSDate* dt1 = nil;
            NSDate* dt2 = nil;
            [[obj1 urlOnDisk] getResourceValue:&dt1 forKey:kURLAddedToDirectoryKey error:nil];
            [[obj2 urlOnDisk] getResourceValue:&dt2 forKey:kURLAddedToDirectoryKey error:nil];
            return [dt2 compare:dt1];
        }];

        [self cleanup];
    }
}

- (NSInteger)itemsInInboxCount {
    return [contents count];
}

- (MMInboxItem*)itemAtIndex:(NSInteger)idx {
    return [contents objectAtIndex:idx];
}

- (NSInteger)indexOfItem:(MMInboxItem*)item {
    return [contents indexOfObject:item];
}

- (void)cleanup {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            NSArray* legitContents = [[contents copy] map:^id(MMInboxItem* obj, NSUInteger index) {
                return [obj cachedAssetsPath];
            }];

            NSMutableArray* pathsToRemove = [NSMutableArray array];

            [[NSFileManager defaultManager] enumerateDirectory:[MMInboxItem cacheDirectory] withBlock:^(NSURL* item, NSUInteger totalItemCount) {
                NSString* itemPath = [[item URLByResolvingSymlinksInPath] path];
                if (![legitContents containsObject:itemPath]) {
                    [pathsToRemove addObject:itemPath];
                }
            } andErrorHandler:nil];

            [pathsToRemove enumerateObjectsUsingBlock:^(NSString* _Nonnull pathToRemove, NSUInteger idx, BOOL* _Nonnull stop) {
                NSError* errorCache = nil;
                [[NSFileManager defaultManager] removeItemAtPath:pathToRemove error:&errorCache];
            }];
        }
    });
}

@end
