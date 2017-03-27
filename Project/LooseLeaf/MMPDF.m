//
//  MMPDF.m
//  LooseLeaf
//
//  Created by Adam Wulf on 5/9/16.
//  Copyright © 2016 Milestone Made, LLC. All rights reserved.
//

#import "MMPDF.h"


@implementation MMPDF {
    NSUInteger pageCount;

    BOOL isEncrypted;
    NSString* password;
    
    CGPDFDocumentRef openedPDFDocRef;
    NSInteger numOpened;
}

@synthesize urlOnDisk;

+ (CGFloat)ppi {
    return 72;
}

- (instancetype)initWithURL:(NSURL*)url {
    if (self = [super init]) {
        urlOnDisk = url;

        CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)self.urlOnDisk);

        pageCount = CGPDFDocumentGetNumberOfPages(pdf);
        isEncrypted = CGPDFDocumentIsEncrypted(pdf);

        CGPDFDocumentRelease(pdf);

        if ([self isEncrypted]) {
            // try with a blank password. Apple Preview does this
            // to auto-open encrypted PDFs
            [self attemptToDecrypt:@""];
        }

        [self refreshTitle];
    }
    return self;
}

- (void)refreshTitle {
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)self.urlOnDisk);

    if (password) {
        const char* key = [password UTF8String];
        CGPDFDocumentUnlockWithPassword(pdf, key);
    }

    CGPDFDictionaryRef info = CGPDFDocumentGetInfo(pdf);

    if (info) {
        CGPDFStringRef outTitleString;
        CGPDFDictionaryGetString(info, [@"Title" cStringUsingEncoding:NSUTF8StringEncoding], &outTitleString);

        if (outTitleString) {
            _title = (NSString*)CFBridgingRelease(CGPDFStringCopyTextString(outTitleString));
        }
    }

    CGPDFDocumentRelease(pdf);
}

#pragma mark - Properties

- (BOOL)attemptToDecrypt:(NSString*)_password {
    BOOL success = password != nil;
    if (!password) {
        CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)self.urlOnDisk);

        const char* key = [_password UTF8String];
        success = CGPDFDocumentUnlockWithPassword(pdf, key);
        CGPDFDocumentRelease(pdf);

        if (success) {
            password = _password;
            [self refreshTitle];
        }
    }

    return success;
}

- (BOOL)isEncrypted {
    return isEncrypted && !password;
}

- (NSUInteger)pageCount {
    return pageCount;
}

- (CGSize)sizeForPage:(NSUInteger)page {
    // size isn't in the cache, so find out and return it
    // we dont' update the cache ourselves though.

    if (page >= pageCount) {
        page = pageCount - 1;
    }
    /*
     * Reference: http://www.cocoanetics.com/2010/06/rendering-pdf-is-easier-than-you-thought/
     */
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)self.urlOnDisk);

    if (password) {
        const char* key = [password UTF8String];
        CGPDFDocumentUnlockWithPassword(pdf, key);
    }

    CGPDFPageRef pageref = CGPDFDocumentGetPage(pdf, page + 1); // pdfs are index 1 at the start!

    CGRect mediaRect = CGPDFPageGetBoxRect(pageref, kCGPDFCropBox);

    CGPDFDocumentRelease(pdf);
    return mediaRect.size;
}

- (CGFloat)rotationForPage:(NSUInteger)page {
    // size isn't in the cache, so find out and return it
    // we dont' update the cache ourselves though.

    if (page >= pageCount) {
        page = pageCount - 1;
    }
    /*
     * Reference: http://www.cocoanetics.com/2010/06/rendering-pdf-is-easier-than-you-thought/
     */
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)self.urlOnDisk);

    if (password) {
        const char* key = [password UTF8String];
        CGPDFDocumentUnlockWithPassword(pdf, key);
    }

    CGPDFPageRef pageref = CGPDFDocumentGetPage(pdf, page + 1); // pdfs are index 1 at the start!

    CGPDFDictionaryRef info = CGPDFPageGetDictionary(pageref);
    CGPDFInteger rotation = 0;
    CGPDFDictionaryGetInteger(info, "Rotate", &rotation);

    CGPDFDocumentRelease(pdf);
    return rotation;
}

#pragma mark - Rendering

- (UIImage*)imageForPage:(NSUInteger)page withMaxDim:(CGFloat)maxDim {
    UIImage* image;
    @autoreleasepool {
        CGSize sizeOfPage = [self sizeForPage:page];

        CGFloat maxCurrDim = MAX(sizeOfPage.width, sizeOfPage.height);
        CGFloat ratio = maxDim / maxCurrDim;
        sizeOfPage.width *= ratio;
        sizeOfPage.height *= ratio;

        sizeOfPage.height = round(sizeOfPage.height);
        sizeOfPage.width = round(sizeOfPage.width);

        if (CGSizeEqualToSize(sizeOfPage, CGSizeZero)) {
            sizeOfPage = [UIScreen mainScreen].bounds.size;
        }


        UIGraphicsBeginImageContextWithOptions(sizeOfPage, NO, 0);
        CGContextRef cgContext = UIGraphicsGetCurrentContext();
        if (!cgContext) {
            @throw [NSException exceptionWithName:@"MemoryException" reason:@"Could not create an image context" userInfo:nil];
        }
        [[UIColor whiteColor] setFill];
        CGContextFillRect(cgContext, CGRectMake(0, 0, sizeOfPage.width, sizeOfPage.height));
        CGPDFDocumentRef pdfDocRef = [self openPDF];
        [self renderPage:page intoContext:cgContext withSize:sizeOfPage withPDFRef:pdfDocRef];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        [self closePDF];
    }
    return image;
}


// must call CGPDFDocumentRelease(pdf); yourself
- (CGPDFDocumentRef)openPDF {
    @synchronized (self) {
        if(!openedPDFDocRef){
            openedPDFDocRef = CGPDFDocumentCreateWithURL((__bridge CFURLRef)self.urlOnDisk);
            
            if (password) {
                const char* key = [password UTF8String];
                CGPDFDocumentUnlockWithPassword(openedPDFDocRef, key);
            }
            numOpened = 1;
        }else{
            numOpened += 1;
        }
        
        return openedPDFDocRef;
    }
}

-(void) closePDF{
    @synchronized (self) {
        numOpened -= 1;
        if(numOpened == 0){
            CGPDFDocumentRelease(openedPDFDocRef);
            openedPDFDocRef = NULL;
        }
    }
}

// must pass in the PDF ref that's generated from [openPDF]
// and CGPDFDocumentRelease after you've closed your own ctx
- (void)renderPage:(NSUInteger)page intoContext:(CGContextRef)ctx withSize:(CGSize)size withPDFRef:(CGPDFDocumentRef)pdf {
    @autoreleasepool {
        CGContextSaveGState(ctx);
        /*
         * Reference: http://www.cocoanetics.com/2010/06/rendering-pdf-is-easier-than-you-thought/
         */
        CGContextGetCTM(ctx);
        CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);

        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -size.height);
        CGPDFPageRef pageref = CGPDFDocumentGetPage(pdf, page + 1); // pdfs are index 1 at the start!

        CGRect mediaRect = CGPDFPageGetBoxRect(pageref, kCGPDFCropBox);
        CGContextScaleCTM(ctx, size.width / mediaRect.size.width, size.height / mediaRect.size.height);
        CGContextTranslateCTM(ctx, -mediaRect.origin.x, -mediaRect.origin.y);

        CGContextDrawPDFPage(ctx, pageref);

        CGContextRestoreGState(ctx);
    }
}


@end
