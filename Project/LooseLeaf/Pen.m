//
//  Pen.m
//  jotuiexample
//
//  Created by Adam Wulf on 12/18/12.
//  Copyright (c) 2012 Adonit. All rights reserved.
//

#import "Pen.h"
#import "Constants.h"
#import <JotUI/JotUI.h>
#import "MMTouchVelocityGestureRecognizer.h"

#define VELOCITY_CLAMP_MIN 20
#define VELOCITY_CLAMP_MAX 1000


@implementation Pen {
    BOOL shortStrokeEnding;
}

@synthesize minSize;
@synthesize maxSize;
@synthesize minAlpha;
@synthesize maxAlpha;
@synthesize velocity;
@synthesize color;

- (id)initWithMinSize:(CGFloat)_minSize andMaxSize:(CGFloat)_maxSize andMinAlpha:(CGFloat)_minAlpha andMaxAlpha:(CGFloat)_maxAlpha {
    if (self = [super init]) {
        minSize = _minSize;
        maxSize = _maxSize;
        minAlpha = _minAlpha;
        maxAlpha = _maxAlpha;

        defaultMinSize = minSize;
        defaultMaxSize = maxSize;
        color = [UIColor blackColor];
    }
    return self;
}

- (void)setColor:(UIColor*)_color {
    color = [_color colorWithAlphaComponent:1];
}

- (id)init {
    return [self initWithMinSize:1.6 andMaxSize:2.7 andMinAlpha:1.0 andMaxAlpha:1.0];
}

- (BOOL)shouldUseVelocity {
    return YES;
}

#pragma mark - Setters

- (void)setMinSize:(CGFloat)_minSize {
    if (_minSize < 1) {
        _minSize = 1;
    }
    minSize = _minSize;
}

- (void)setMaxSize:(CGFloat)_maxSize {
    if (_maxSize < 1) {
        _maxSize = 1;
    }
    maxSize = _maxSize;
}

#pragma mark - JotViewDelegate

/**
 * delegate method - a notification from the JotView
 * that a new touch is about to be processed. we should
 * reset all of our counters/etc to base values
 */
- (BOOL)willBeginStrokeWithCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    shortStrokeEnding = NO;
    velocity = 1;
    return YES;
}

/**
 * notification that the JotView is about to ask for
 * alpha/width info for this touch. let's update
 * our velocity model and state info for this new touch
 */
- (void)willMoveStrokeWithCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    velocity = [[MMTouchVelocityGestureRecognizer sharedInstance] normalizedVelocityForTouch:touch];
}

- (void)willEndStrokeWithCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch shortStrokeEnding:(BOOL)_shortStrokeEnding inJotView:(JotView *)jotView{
    shortStrokeEnding = _shortStrokeEnding;
}

/**
 * user is finished with a stroke. for our purposes
 * we don't need to do anything
 */
- (void)didEndStrokeWithCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    // noop
}

- (void)willCancelStroke:(JotStroke*)stroke withCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    // noop
}

/**
 * the user cancelled the touch
 */
- (void)didCancelStroke:(JotStroke*)stroke withCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    // noop
}

/**
 * we'll adjust the alpha of the ink
 * based on pressure or velocity.
 *
 * we could also adjust the color here too,
 * but for our demo adjusting only the alpha
 * is the look we're going for.
 */
- (UIColor*)colorForCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    if (coalescedTouch.type == UITouchTypeStylus) {
        CGFloat segmentAlpha = (maxAlpha + minAlpha) / 2.0;
        segmentAlpha *= coalescedTouch.force;
        if (segmentAlpha < minAlpha)
            segmentAlpha = minAlpha;
        if (segmentAlpha > maxAlpha)
            segmentAlpha = maxAlpha;

        UIColor* currColor = color;
        currColor = [UIColor colorWithCGColor:currColor.CGColor];
        UIColor* ret = [currColor colorWithAlphaComponent:segmentAlpha];
        return ret;
    } else if (self.shouldUseVelocity) {
        CGFloat segmentAlpha = (velocity - 1);
        if (segmentAlpha > 0)
            segmentAlpha = 0;
        segmentAlpha = minAlpha + ABS(segmentAlpha) * (maxAlpha - minAlpha);

        UIColor* currColor = color;
        currColor = [UIColor colorWithCGColor:currColor.CGColor];
        UIColor* ret = [currColor colorWithAlphaComponent:segmentAlpha];
        return ret;
    } else {
        CGFloat segmentAlpha = minAlpha + (maxAlpha - minAlpha) * coalescedTouch.force;
        segmentAlpha = MAX(minAlpha, MIN(maxAlpha, segmentAlpha));

        UIColor* ret = [color colorWithAlphaComponent:segmentAlpha];
        return ret;
    }
}

/**
 * the user has moved to this new touch point, and we need
 * to specify the width of the stroke at this position
 *
 * we'll use pressure data to determine width if we can, otherwise
 * we'll fall back to use velocity data
 */
- (CGFloat)widthForCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    if (coalescedTouch.type == UITouchTypeStylus) {
        CGFloat width = (maxSize + minSize) / 2.0;
        width *= coalescedTouch.force;
        if (width < minSize)
            width = minSize;
        if (width > maxSize)
            width = maxSize;

        return width;
    } else if (self.shouldUseVelocity) {
        CGFloat width = (velocity - 1);
        if (width > 0)
            width = 0;
        width = minSize + ABS(width) * (maxSize - minSize);
        if (width < 1)
            width = 1;

        if (shortStrokeEnding) {
            return maxSize;
        }

        return width;
    } else {
        CGFloat newWidth = minSize + (maxSize - minSize) * coalescedTouch.force;
        newWidth = MAX(minSize, MIN(maxSize, newWidth));
        return newWidth;
    }
}

- (JotBrushTexture*)textureForStroke {
    return [JotDefaultBrushTexture sharedInstance];
}

- (CGFloat)stepWidthForStroke {
    return .5;
}

- (BOOL)supportsRotation {
    return NO;
}

/**
 * we'll keep this pen fairly smooth, and using 0.75 gives
 * a good effect.
 *
 * 0 will be as if we just connected with straight lines,
 * 1 is as curvey as we can get,
 * > 1 is loopy
 * < 0 is knotty
 */
- (CGFloat)smoothnessForCoalescedTouch:(UITouch*)coalescedTouch fromTouch:(UITouch*)touch inJotView:(JotView *)jotView{
    return 0.75;
}

/**
 * the pen is a circle, so rotation isn't very
 * important for this pen. just return 0
 * and don't have any rotation
 */
- (CGFloat)rotationForSegment:(AbstractBezierPathElement*)segment fromPreviousSegment:(AbstractBezierPathElement*)previousSegment inJotView:(JotView *)jotView{
    return 0;
}

- (NSArray*)willAddElements:(NSArray*)elements toStroke:(JotStroke*)stroke fromPreviousElement:(AbstractBezierPathElement*)previousElement inJotView:(JotView *)jotView{
    return elements;
}

@end
