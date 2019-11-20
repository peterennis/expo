#import "ABI36_0_0RNGestureHandler.h"

#import "Handlers/ABI36_0_0RNNativeViewHandler.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

#import <ABI36_0_0React/ABI36_0_0UIView+React.h>

@interface UIGestureRecognizer (GestureHandler)
@property (nonatomic, readonly) ABI36_0_0RNGestureHandler *gestureHandler;
@end


@implementation UIGestureRecognizer (GestureHandler)

- (ABI36_0_0RNGestureHandler *)gestureHandler
{
    id delegate = self.delegate;
    if ([delegate isKindOfClass:[ABI36_0_0RNGestureHandler class]]) {
        return (ABI36_0_0RNGestureHandler *)delegate;
    }
    return nil;
}

@end

typedef struct ABI36_0_0RNGHHitSlop {
    CGFloat top, left, bottom, right, width, height;
} ABI36_0_0RNGHHitSlop;

static ABI36_0_0RNGHHitSlop ABI36_0_0RNGHHitSlopEmpty = { NAN, NAN, NAN, NAN, NAN, NAN };

#define ABI36_0_0RNGH_HIT_SLOP_GET(key) (prop[key] == nil ? NAN : [prop[key] doubleValue])
#define ABI36_0_0RNGH_HIT_SLOP_IS_SET(hitSlop) (!isnan(hitSlop.left) || !isnan(hitSlop.right) || \
                                        !isnan(hitSlop.top) || !isnan(hitSlop.bottom))
#define ABI36_0_0RNGH_HIT_SLOP_INSET(key) (isnan(hitSlop.key) ? 0. : hitSlop.key)

CGRect ABI36_0_0RNGHHitSlopInsetRect(CGRect rect, ABI36_0_0RNGHHitSlop hitSlop) {
    rect.origin.x -= ABI36_0_0RNGH_HIT_SLOP_INSET(left);
    rect.origin.y -= ABI36_0_0RNGH_HIT_SLOP_INSET(top);

    if (!isnan(hitSlop.width)) {
        if (!isnan(hitSlop.right)) {
            rect.origin.x = rect.size.width - hitSlop.width + ABI36_0_0RNGH_HIT_SLOP_INSET(right);
        }
        rect.size.width = hitSlop.width;
    } else {
        rect.size.width += (ABI36_0_0RNGH_HIT_SLOP_INSET(left) + ABI36_0_0RNGH_HIT_SLOP_INSET(right));
    }
    if (!isnan(hitSlop.height)) {
        if (!isnan(hitSlop.bottom)) {
            rect.origin.y = rect.size.height - hitSlop.height + ABI36_0_0RNGH_HIT_SLOP_INSET(bottom);
        }
        rect.size.height = hitSlop.height;
    } else {
        rect.size.height += (ABI36_0_0RNGH_HIT_SLOP_INSET(top) + ABI36_0_0RNGH_HIT_SLOP_INSET(bottom));
    }
    return rect;
}


@implementation ABI36_0_0RNGestureHandler {
    NSArray<NSNumber *> *_handlersToWaitFor;
    NSArray<NSNumber *> *_simultaneousHandlers;
    ABI36_0_0RNGHHitSlop _hitSlop;
}

- (instancetype)initWithTag:(NSNumber *)tag
{
    if ((self = [super init])) {
        _tag = tag;
        _lastState = ABI36_0_0RNGestureHandlerStateUndetermined;
        _hitSlop = ABI36_0_0RNGHHitSlopEmpty;
    }
    return self;
}

- (void)configure:(NSDictionary *)config
{
    _handlersToWaitFor = [ABI36_0_0RCTConvert NSNumberArray:config[@"waitFor"]];
    _simultaneousHandlers = [ABI36_0_0RCTConvert NSNumberArray:config[@"simultaneousHandlers"]];

    id prop = config[@"enabled"];
    if (prop != nil) {
        self.enabled = [ABI36_0_0RCTConvert BOOL:prop];
    } else {
        self.enabled = YES;
    }

    prop = config[@"shouldCancelWhenOutside"];
    if (prop != nil) {
        _shouldCancelWhenOutside = [ABI36_0_0RCTConvert BOOL:prop];
    } else {
        _shouldCancelWhenOutside = NO;
    }

    prop = config[@"hitSlop"];
    if ([prop isKindOfClass:[NSNumber class]]) {
        _hitSlop.left = _hitSlop.right = _hitSlop.top = _hitSlop.bottom = [prop doubleValue];
    } else if (prop != nil) {
        _hitSlop.left = _hitSlop.right = ABI36_0_0RNGH_HIT_SLOP_GET(@"horizontal");
        _hitSlop.top = _hitSlop.bottom = ABI36_0_0RNGH_HIT_SLOP_GET(@"vertical");
        _hitSlop.left = ABI36_0_0RNGH_HIT_SLOP_GET(@"left");
        _hitSlop.right = ABI36_0_0RNGH_HIT_SLOP_GET(@"right");
        _hitSlop.top = ABI36_0_0RNGH_HIT_SLOP_GET(@"top");
        _hitSlop.bottom = ABI36_0_0RNGH_HIT_SLOP_GET(@"bottom");
        _hitSlop.width = ABI36_0_0RNGH_HIT_SLOP_GET(@"width");
        _hitSlop.height = ABI36_0_0RNGH_HIT_SLOP_GET(@"height");
        if (isnan(_hitSlop.left) && isnan(_hitSlop.right) && !isnan(_hitSlop.width)) {
            ABI36_0_0RCTLogError(@"When width is set one of left or right pads need to be defined");
        }
        if (!isnan(_hitSlop.width) && !isnan(_hitSlop.left) && !isnan(_hitSlop.right)) {
            ABI36_0_0RCTLogError(@"Cannot have all of left, right and width defined");
        }
        if (isnan(_hitSlop.top) && isnan(_hitSlop.bottom) && !isnan(_hitSlop.height)) {
            ABI36_0_0RCTLogError(@"When height is set one of top or bottom pads need to be defined");
        }
        if (!isnan(_hitSlop.height) && !isnan(_hitSlop.top) && !isnan(_hitSlop.bottom)) {
            ABI36_0_0RCTLogError(@"Cannot have all of top, bottom and height defined");
        }
    }
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.recognizer.enabled = enabled;
}

- (void)bindToView:(UIView *)view
{
    view.userInteractionEnabled = YES;
    self.recognizer.delegate = self;
    [view addGestureRecognizer:self.recognizer];
}

- (void)unbindFromView
{
    [self.recognizer.view removeGestureRecognizer:self.recognizer];
    self.recognizer.delegate = nil;
}

- (ABI36_0_0RNGestureHandlerEventExtraData *)eventExtraData:(UIGestureRecognizer *)recognizer
{
    return [ABI36_0_0RNGestureHandlerEventExtraData
            forPosition:[recognizer locationInView:recognizer.view]
            withAbsolutePosition:[recognizer locationInView:recognizer.view.window]
            withNumberOfTouches:recognizer.numberOfTouches];
}

- (void)handleGesture:(UIGestureRecognizer *)recognizer
{
    ABI36_0_0RNGestureHandlerEventExtraData *eventData = [self eventExtraData:recognizer];
    [self sendEventsInState:self.state forViewWithTag:recognizer.view.ABI36_0_0ReactTag withExtraData:eventData];
}

- (void)sendEventsInState:(ABI36_0_0RNGestureHandlerState)state
           forViewWithTag:(nonnull NSNumber *)ABI36_0_0ReactTag
            withExtraData:(ABI36_0_0RNGestureHandlerEventExtraData *)extraData
{
    id touchEvent = [[ABI36_0_0RNGestureHandlerEvent alloc] initWithRactTag:ABI36_0_0ReactTag
                                                        handlerTag:_tag
                                                             state:state
                                                         extraData:extraData];

    if (state != _lastState) {
        if (state == ABI36_0_0RNGestureHandlerStateEnd && _lastState != ABI36_0_0RNGestureHandlerStateActive) {
            [self.emitter sendStateChangeEvent:[[ABI36_0_0RNGestureHandlerStateChange alloc] initWithRactTag:ABI36_0_0ReactTag
                                                                                         handlerTag:_tag
                                                                                              state:ABI36_0_0RNGestureHandlerStateActive
                                                                                          prevState:_lastState
                                                                                          extraData:extraData]];
            _lastState = ABI36_0_0RNGestureHandlerStateActive;
        }
        id stateEvent = [[ABI36_0_0RNGestureHandlerStateChange alloc] initWithRactTag:ABI36_0_0ReactTag
                                                                  handlerTag:_tag
                                                                       state:state
                                                                   prevState:_lastState
                                                                   extraData:extraData];
        [self.emitter sendStateChangeEvent:stateEvent];
        _lastState = state;
    }

    if (state == ABI36_0_0RNGestureHandlerStateActive) {
        [self.emitter sendTouchEvent:touchEvent];
    }
}

- (ABI36_0_0RNGestureHandlerState)state
{
    switch (_recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStatePossible:
            return ABI36_0_0RNGestureHandlerStateBegan;
        case UIGestureRecognizerStateEnded:
            return ABI36_0_0RNGestureHandlerStateEnd;
        case UIGestureRecognizerStateFailed:
            return ABI36_0_0RNGestureHandlerStateFailed;
        case UIGestureRecognizerStateCancelled:
            return ABI36_0_0RNGestureHandlerStateCancelled;
        case UIGestureRecognizerStateChanged:
            return ABI36_0_0RNGestureHandlerStateActive;
    }
    return ABI36_0_0RNGestureHandlerStateUndetermined;
}

#pragma mark UIGestureRecognizerDelegate

+ (ABI36_0_0RNGestureHandler *)findGestureHandlerByRecognizer:(UIGestureRecognizer *)recognizer
{
    ABI36_0_0RNGestureHandler *handler = recognizer.gestureHandler;
    if (handler != nil) {
        return handler;
    }

    // We may try to extract "DummyGestureHandler" in case when "otherGestureRecognizer" belongs to
    // a native view being wrapped with "NativeViewGestureHandler"
    UIView *ABI36_0_0ReactView = recognizer.view;
    while (ABI36_0_0ReactView != nil && ABI36_0_0ReactView.ABI36_0_0ReactTag == nil) {
        ABI36_0_0ReactView = ABI36_0_0ReactView.superview;
    }

    for (UIGestureRecognizer *recognizer in ABI36_0_0ReactView.gestureRecognizers) {
        if ([recognizer isKindOfClass:[ABI36_0_0RNDummyGestureRecognizer class]]) {
            return recognizer.gestureHandler;
        }
    }

    return nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    ABI36_0_0RNGestureHandler *handler = [ABI36_0_0RNGestureHandler findGestureHandlerByRecognizer:otherGestureRecognizer];
    if ([handler isKindOfClass:[ABI36_0_0RNNativeViewGestureHandler class]]) {
        for (NSNumber *handlerTag in handler->_handlersToWaitFor) {
            if ([_tag isEqual:handlerTag]) {
                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([_handlersToWaitFor count]) {
        ABI36_0_0RNGestureHandler *handler = [ABI36_0_0RNGestureHandler findGestureHandlerByRecognizer:otherGestureRecognizer];
        if (handler != nil) {
            for (NSNumber *handlerTag in _handlersToWaitFor) {
                if ([handler.tag isEqual:handlerTag]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (_recognizer.state == UIGestureRecognizerStateBegan && _recognizer.state == UIGestureRecognizerStatePossible) {
        return YES;
    }
    if ([_simultaneousHandlers count]) {
        ABI36_0_0RNGestureHandler *handler = [ABI36_0_0RNGestureHandler findGestureHandlerByRecognizer:otherGestureRecognizer];
        if (handler != nil) {
            for (NSNumber *handlerTag in _simultaneousHandlers) {
                if ([handler.tag isEqual:handlerTag]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)reset
{
    _lastState = ABI36_0_0RNGestureHandlerStateUndetermined;
}

 - (BOOL)containsPointInView
 {
     CGPoint pt = [_recognizer locationInView:_recognizer.view];
     CGRect hitFrame = ABI36_0_0RNGHHitSlopInsetRect(_recognizer.view.bounds, _hitSlop);
     return CGRectContainsPoint(hitFrame, pt);
 }

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    [self reset];
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // If hitSlop is set we use it to determine if a given gesture recognizer should start processing
    // touch stream. This only works for negative values of hitSlop as this method won't be triggered
    // unless touch startes in the bounds of the attached view. To acheve similar effect with positive
    // values of hitSlop one should set hitSlop for the underlying view. This limitation is due to the
    // fact that hitTest method is only available at the level of UIView
    if (ABI36_0_0RNGH_HIT_SLOP_IS_SET(_hitSlop)) {
        CGPoint location = [touch locationInView:gestureRecognizer.view];
        CGRect hitFrame = ABI36_0_0RNGHHitSlopInsetRect(gestureRecognizer.view.bounds, _hitSlop);
        return CGRectContainsPoint(hitFrame, location);
    }
    return YES;
}

@end
