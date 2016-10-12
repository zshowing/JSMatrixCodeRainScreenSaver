//
//  CodeRainView.m
//  CodeRain
//
//  Created by Shuo Zhang on 2016/10/6.
//  Copyright © 2016年 Jon Showing. All rights reserved.
//

#import "CodeRainView.h"
#import <QuartzCore/CAAnimation.h>

#define kJSCodeRainMaxGlowLength        3
#define kJSCodeRainSpeed                0.05
#define kJSCodeRainNewTrackComingLap    0.1
#define kJSCodeRainTrackSpacing         5
#define kJSCodeRainMinTrackLength       8
#define kJSCodeRainMaxTrackLength       40
#define kJSCodeRainCharacterSet         @"abcdefghijklmnopqrstuvwxzyABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

@implementation JSMatrixTrack
@synthesize positionX;

- (void)setPositionY:(UInt)positionY{
    _positionY = positionY;
    
    if (positionY > _totalLength){
        _topY += 1;
    }
}

-(CGFloat)positionX{
    return _trackNum * [JSMatrixDataSource capHeight];
}

- (instancetype)initWithLength: (UInt)length trackNum: (UInt)trackNumber{
    self = [super init];
    if (self){
        self.totalLength = length;
        self.glowLength = arc4random_uniform(MIN(kJSCodeRainMaxGlowLength, length));
        self.fadeLength = arc4random_uniform(length - self.glowLength);
        self.trackNum = trackNumber;
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:kJSCodeRainSpeed target:self selector:@selector(drop) userInfo:nil repeats:YES];
    }
    
    return self;
}

- (void)drop{
    self.positionY += 1;
    
    if (_topY > [JSMatrixDataSource maxNum] + _totalLength){
        [self.timer invalidate];
        _timer = nil;
        [[JSMatrixDataSource sharedDataSource] removeTrack:self];
        if ([_delegate respondsToSelector:@selector(trackNeedRemove)]) {
            [_delegate trackNeedRemove];
        }
    }else{
        if ([_delegate respondsToSelector:@selector(trackNeedUpdate:)]) {
            [_delegate trackNeedUpdate:self];
        }
    }
}

- (CGFloat)brightness:(CGFloat)currentTopY{
    NSInteger index = _positionY - currentTopY;
    CGFloat brightness = 1 - (CGFloat)index / (CGFloat)_totalLength;
    if (index < self.glowLength) {
        return brightness * 1.2;
    }else if (index > _totalLength - _fadeLength){
        return brightness * 0.4;
    }else{
        return brightness;
    }
}

@end

@implementation JSMatrixDataSource

+ (instancetype)sharedDataSource{
    static JSMatrixDataSource *sharedDataSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataSource = [[JSMatrixDataSource alloc] init];
    });
    
    return sharedDataSource;
}

+ (CGFloat)capHeight{
    static CGFloat capHeight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        capHeight = [NSFont fontWithName:@"Matrix Code NFI"
                                    size:19.0f].capHeight;
    });
    
    return capHeight;
}

+(CGSize)screenSize{
    static CGSize screenSize;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        screenSize = [[NSScreen mainScreen] frame].size;
    });
    
    return screenSize;
}

+ (NSDictionary *)getBrightnessAttributes: (CGFloat)brightness{
    static NSFont *font = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        font = [NSFont fontWithName:@"Matrix Code NFI"
                               size:19.0f];
    });
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeZero;
    shadow.shadowBlurRadius = 2.0f;
    shadow.shadowColor = [NSColor colorWithWhite:brightness alpha:brightness];
    return @{NSFontAttributeName: font,
             NSForegroundColorAttributeName: [NSColor colorWithHue:27.0/360.0 saturation:97.0/100.0 brightness:brightness alpha:1.0],
             NSShadowAttributeName: shadow};
}

+ (NSDictionary *)getStringAttrs{
    static NSDictionary *fontAttrDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowOffset = CGSizeZero;
        shadow.shadowBlurRadius = 4.0f;
        shadow.shadowColor = [NSColor colorWithWhite:1.0 alpha:0.7];
        fontAttrDict = @{NSFontAttributeName: [NSFont fontWithName:@"Matrix Code NFI"
                                                              size:20.0f],
                         NSForegroundColorAttributeName: [NSColor colorWithHue:127.0/360.0 saturation:97.0/100.0 brightness:1.0 alpha:1.0],
                         NSShadowAttributeName: shadow};
    });
    
    return fontAttrDict;
}

+ (NSString *)getCharacter{
    NSInteger randomNum = arc4random_uniform((uint32_t)kJSCodeRainCharacterSet.length);
    return [NSString stringWithFormat:@"%C", [kJSCodeRainCharacterSet characterAtIndex:randomNum]];
}

+ (UInt)trackNum{
    static UInt num;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        num = ceilf([NSScreen mainScreen].frame.size.width / [JSMatrixDataSource capHeight]);
    });
    return num;
}

+ (UInt)maxNum{
    static UInt num;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        num = ceilf([NSScreen mainScreen].frame.size.height / [JSMatrixDataSource capHeight]);
    });
    return num;
}

- (instancetype) init{
    self = [super init];
    if (self) {
        NSMutableArray *charactersArray = [NSMutableArray array];
        for (int i = 0; i < [JSMatrixDataSource trackNum]; i ++) {
            NSMutableArray *track = [NSMutableArray array];
            for (int j = 0; j < [JSMatrixDataSource maxNum]; j ++) {
                [track addObject:[JSMatrixDataSource getCharacter]];
            }
            [charactersArray addObject:track];
        }
        
        self.characters = [NSArray arrayWithArray:charactersArray];
        charactersArray = nil;
        
        self.currentTracks = [NSMutableSet set];
        
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(changeCharacter) userInfo:nil repeats:YES];
    }
    return self;
}

-(NSArray<NSNumber *> *)availableTracks{
    NSMutableSet *set = [NSMutableSet set];
    for (int i = 0; i < [JSMatrixDataSource trackNum]; i ++) {
        [set addObject:@(i)];
    }
    
    for (JSMatrixTrack *track in _currentTracks) {
        if (track.topY <= kJSCodeRainTrackSpacing) {
            [set removeObject:@(track.trackNum)];
        }
    }
    
    return [set allObjects];
}

- (void)addTrack:(JSMatrixTrack *)track{
    [self.currentTracks addObject:track];
}

- (void)removeTrack:(JSMatrixTrack *)track{
    [self.currentTracks removeObject:track];
}

- (void)changeCharacter{
    for (int trackIndex = 0; trackIndex < [JSMatrixDataSource trackNum]; trackIndex ++) {
        if (arc4random_uniform(10) < 4.0) {
            int randNum = arc4random_uniform([JSMatrixDataSource maxNum]);
            _characters[trackIndex][randNum] = [JSMatrixDataSource getCharacter];
        }
    }
}

@end

@implementation JSMatrixTrackGenerator

- (JSMatrixTrack *)getTrack{
    NSArray *availableTracks = [JSMatrixDataSource sharedDataSource].availableTracks;
    NSInteger randNum = arc4random_uniform((u_int32_t)availableTracks.count);
    
    return [[JSMatrixTrack alloc] initWithLength:arc4random_uniform(kJSCodeRainMaxTrackLength - kJSCodeRainMinTrackLength) + kJSCodeRainMinTrackLength
                                        trackNum:(UInt)[availableTracks[randNum] integerValue]];
}

- (void)begin{
    [NSTimer scheduledTimerWithTimeInterval:kJSCodeRainNewTrackComingLap target:self selector:@selector(produceTrack) userInfo:nil repeats:YES];
}

- (void)produceTrack{
    if ([_delegate respondsToSelector: @selector(didGeneratedNewTrack:)]){
        [_delegate didGeneratedNewTrack:[self getTrack]];
    }
}

@end

@interface JSMatrixTrackLayer (){
    JSMatrixTrack *track;
    NSAttributedString *attrString;
    CAGradientLayer *backGradientLayer;
}

@end

@implementation JSMatrixTrackLayer

- (instancetype)init{
    self = [super init];
    if (self) {
        self.drawsAsynchronously = YES;
        self.wrapped = YES;
        self.alignmentMode = kCAAlignmentCenter;
        self.truncationMode = kCATruncationNone;
        self.contentsScale = [NSScreen mainScreen].backingScaleFactor;
        self.opaque = YES;
        self.backgroundColor = [NSColor blackColor].CGColor;
        
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.colors = @[(__bridge id)[NSColor whiteColor].CGColor, (__bridge id)[[NSColor whiteColor] colorWithAlphaComponent:0].CGColor];
        self.gradientLayer.startPoint = CGPointMake(0.5, 0);
        self.gradientLayer.endPoint = CGPointMake(0.5, 1);
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn",
                                           [NSNull null], @"onOrderOut",
                                           [NSNull null], @"sublayers",
                                           [NSNull null], @"contents",
                                           [NSNull null], @"bounds",
                                           [NSNull null], @"position",
                                           nil];
        self.gradientLayer.actions = newActions;
//        [self addSublayer:self.gradientLayer];
        self.mask = self.gradientLayer;
        
        backGradientLayer = [CAGradientLayer layer];
        backGradientLayer.colors = @[(__bridge id)[NSColor clearColor].CGColor, (__bridge id)[NSColor colorWithHue:127.0/360.0 saturation:97.0/100.0 brightness:0.5 alpha:0.3].CGColor];
        backGradientLayer.startPoint = CGPointMake(0.5, 1);
        backGradientLayer.endPoint = CGPointMake(0.5, 0);
        backGradientLayer.zPosition = -1;
        [self addSublayer:backGradientLayer];
    }
    return self;
}

/*
- (void)drawInContext:(CGContextRef)ctx{
    CGSize size = [JSMatrixDataSource characterSize];
    NSArray *characters = [[JSMatrixDataSource sharedDataSource] characters][track.trackNum];
    
    NSRange range = NSMakeRange(0, track.positionY);
    if (track.positionY > track.totalLength){
        if (track.positionY < [JSMatrixDataSource maxNum]){
            range = NSMakeRange(track.topY, MIN(track.totalLength, [JSMatrixDataSource maxNum] - track.topY));
        }else{
            range = NSMakeRange(track.topY, [JSMatrixDataSource maxNum] - track.topY);
        }
    }
    
    CGFloat topY = track.topY;
    
    [NSGraphicsContext saveGraphicsState];
    
    NSGraphicsContext *currentContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
    [NSGraphicsContext setCurrentContext:currentContext];
    for (NSString *character in [characters subarrayWithRange:range]) {
        CGRect rect = CGRectMake(0,
                                 [NSScreen mainScreen].frame.size.height - topY * [JSMatrixDataSource characterSize].height,
                                 size.width, size.height);
        NSDictionary *attr = [JSMatrixDataSource getBrightnessAttributes:[track brightness:topY]];
        [character drawInRect: rect
               withAttributes: attr];
        topY += 1;
    }
    [NSGraphicsContext restoreGraphicsState];
}*/

-(void)trackNeedUpdate:(JSMatrixTrack *)_track{
    track = _track;
    
    if (self.string == nil) {
        NSArray *characters = [[JSMatrixDataSource sharedDataSource] characters][track.trackNum];
        NSString *trackString = [characters componentsJoinedByString:@""];
        attrString = [[NSMutableAttributedString alloc] initWithString:trackString
                                                            attributes: [JSMatrixDataSource getStringAttrs]];
        self.string = attrString;
    }
    
    if (arc4random_uniform(10) > 7){
        self.contents = nil;        // Force the layer to clear its content
        [self setNeedsDisplay];     // Then mark the layer needs redraw
        
        NSArray *characters = [[JSMatrixDataSource sharedDataSource] characters][track.trackNum];
        NSString *trackString = [characters componentsJoinedByString:@""];
        self.string = [[NSMutableAttributedString alloc] initWithString:trackString
                                                             attributes: [JSMatrixDataSource getStringAttrs]];
    }
    
    CGRect newFrame = CGRectMake(0, [JSMatrixDataSource screenSize].height - track.topY * [JSMatrixDataSource capHeight], self.bounds.size.width, track.totalLength * [JSMatrixDataSource capHeight]);
    
    self.gradientLayer.frame = newFrame;
    backGradientLayer.frame = newFrame;
}

/*
- (void)trackSyncorouslyNeedUpdate:(JSMatrixTrack *)_track{
    track = _track;
    
    [self setNeedsDisplay];
}


- (void)trackAsyncorouslyNeedUpdate:(JSMatrixTrack *)_track{
    track = _track;
    
    NSArray *characters = [[JSMatrixDataSource sharedDataSource] characters][track.trackNum];
    
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSRange range = NSMakeRange(0, track.positionY);
        if (track.positionY > track.totalLength){
            if (track.positionY < [JSMatrixDataSource maxNum]){
                range = NSMakeRange(track.topY, MIN(track.totalLength, [JSMatrixDataSource maxNum] - track.topY));
            }else{
                range = NSMakeRange(track.topY, [JSMatrixDataSource maxNum] - track.topY);
            }
        }
        
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, size.width, [NSScreen mainScreen].frame.size.height, 8, 0, space, kCGImageAlphaPremultipliedLast);
        CGContextSaveGState(ctx);
        
        NSImage* im = [[NSImage alloc] initWithSize:CGSizeMake(size.width, [NSScreen mainScreen].frame.size.height)];
        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
                                 initWithBitmapDataPlanes:NULL
                                 pixelsWide:size.width
                                 pixelsHigh:[NSScreen mainScreen].frame.size.height
                                 bitsPerSample:8
                                 samplesPerPixel:4
                                 hasAlpha:YES
                                 isPlanar:NO
                                 colorSpaceName:NSCalibratedRGBColorSpace
                                 bytesPerRow:0
                                 bitsPerPixel:0];
        
        [im addRepresentation:rep];
        
        [im lockFocus];
        
        CGFloat topY = track.topY;
        
        for (NSString *character in [characters subarrayWithRange:range]) {
            CGRect rect = CGRectMake(0,
                                     [NSScreen mainScreen].frame.size.height - topY * [JSMatrixDataSource characterSize].height,
                                     size.width, size.height);
            NSDictionary *attr = [JSMatrixDataSource getBrightnessAttributes:[track brightness:topY]];
            [character drawInRect: rect
                   withAttributes: attr];
            topY += 1;
        }
        
        [im unlockFocus];
        CGContextRestoreGState(ctx);
        CGContextRelease(ctx);
        CGColorSpaceRelease(space);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.contents = im;
        });
    });
}*/

-(void)trackNeedRemove{
    [self removeFromSuperlayer];
}

@end

@implementation JSMatrixCamera



@end

@implementation CodeRainView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.generator = [[JSMatrixTrackGenerator alloc] init];
        self.generator.delegate = self;
        self.generator.datasource = self;
        [self.generator begin];
        
        self.layer.drawsAsynchronously = YES;
        
        _containerLayer = [[CALayer alloc] init];
        _containerLayer.drawsAsynchronously = YES;
        _containerLayer.frame = self.bounds;
        [self setLayer:_containerLayer];
        [self setWantsLayer:YES];
        [self.layer setBackgroundColor:[NSColor blackColor].CGColor];
        
//        CATransform3D transform = CATransform3DIdentity;
//        transform.m34 = -1.0/500.0;
//        _containerLayer.sublayerTransform = transform;
        
//        [NSTimer scheduledTimerWithTimeInterval:8.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
//            NSInteger mode = arc4random_uniform(5);
//            
//            CATransform3D transform;
//            switch (mode) {
//                case 0:
//                    transform = CATransform3DMakeRotation(M_PI_4 / 4, 0, 1, 0);
//                    break;
//                case 1:
//                    transform = CATransform3DMakeRotation(-M_PI_4 / 4, 0, 1, 0);
//                    break;
//                case 2:
//                    transform = CATransform3DMakeRotation(M_PI_4 / 4, 1, 0, 0);
//                    break;
//                case 3:
//                    transform = CATransform3DMakeRotation(-M_PI_4 / 4, 1, 0, 0);
//                    break;
//                default:
//                    transform = CATransform3DMakeRotation(-M_PI_4 / 4, 1, 0, 0);
//                    break;
//            }
//            
//            CABasicAnimation *animation = [CABasicAnimation animation];
//            animation.keyPath = @"transform";
//            animation.fromValue = [NSValue valueWithCATransform3D: _containerLayer.presentationLayer.transform];
//            animation.toValue = [NSValue valueWithCATransform3D:transform];
//            animation.duration = 5.0f;
//            [_containerLayer addAnimation:animation forKey:@"transform"];
//            
//        }];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)animateOneFrame
{
    
}

-(void)setFrameSize:(NSSize)newSize{
    [super setFrameSize:newSize];
    
    if (newSize.width > 0 && newSize.height > 0) {
        [self.layer setFrame:CGRectMake(0, 0, newSize.width, newSize.height)];
    }
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

# pragma mark - JSMatrixGenerator Methods

- (NSArray<NSNumber *> *)avaliableTracks{
    return [[JSMatrixDataSource sharedDataSource] availableTracks];
}

-(void)didGeneratedNewTrack:(JSMatrixTrack *)track{
    [[JSMatrixDataSource sharedDataSource] addTrack:track];
    JSMatrixTrackLayer *trackLayer = [[JSMatrixTrackLayer alloc] init];
    trackLayer.frame = CGRectMake(track.positionX, 0, [JSMatrixDataSource capHeight], [NSScreen mainScreen].frame.size.height);
    track.delegate = trackLayer;
//    trackLayer.zPosition = arc4random_uniform(100);
    [_containerLayer addSublayer:trackLayer];
}

@end
