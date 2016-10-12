//
//  CodeRainView.h
//  CodeRain
//
//  Created by Shuo Zhang on 2016/10/6.
//  Copyright © 2016年 Jon Showing. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <QuartzCore/CATextLayer.h>
#import <QuartzCore/CAGradientLayer.h>
#import <QuartzCore/CATransaction.h>

@class CodeRainView;
@class JSMatrixTrack;

@protocol JSMatrixTrackDelegate <NSObject>
- (void)trackNeedUpdate:(JSMatrixTrack *)track;
- (void)trackNeedRemove;
@end

@interface JSMatrixTrack : NSObject
@property (nonatomic, assign) UInt glowLength;
@property (nonatomic, assign) UInt fadeLength;
@property (nonatomic, assign) UInt totalLength;
@property (nonatomic, assign) UInt positionY;
@property (nonatomic, assign) UInt trackNum;
@property (nonatomic, assign) CGFloat positionX;
@property (nonatomic, assign) UInt topY;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak) id<JSMatrixTrackDelegate> delegate;
- (CGFloat)brightness:(CGFloat)currentTopY;
@end

@protocol JSMatrixTrackGeneratorDelegate <NSObject>
- (void)didGeneratedNewTrack:(JSMatrixTrack *)track;
@end

@protocol JSMatrixTrackGeneratorDataSource <NSObject>
- (NSArray<NSNumber *> *)avaliableTracks;
@end

@interface JSMatrixTrackGenerator : NSObject
@property (weak, nonatomic) id<JSMatrixTrackGeneratorDelegate> delegate;
@property (weak, nonatomic) id<JSMatrixTrackGeneratorDataSource> datasource;
@end

@interface JSMatrixDataSource : NSObject

+ (instancetype)sharedDataSource;
+ (NSDictionary *)getBrightnessAttributes: (CGFloat)brightness;
+ (CGFloat)capHeight;
+ (UInt)trackNum;
+ (UInt)maxNum;
+ (CGSize)screenSize;
+ (NSDictionary *)getStringAttrs;

- (NSArray<NSNumber *> *)availableTracks;
- (void)addTrack: (JSMatrixTrack *)track;
- (void)removeTrack: (JSMatrixTrack *)track;

@property (nonatomic, strong) NSString *charactersSet;
@property (nonatomic, strong) NSMutableSet<JSMatrixTrack *> *currentTracks;
@property (nonatomic, strong) NSArray<NSMutableArray<NSString *> *> *characters;

@end

@interface JSMatrixTrackLayer : CATextLayer<JSMatrixTrackDelegate>
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CALayer *maskLayer;
@end

@interface JSMatrixCamera : NSObject

@end

@interface CodeRainView : ScreenSaverView<JSMatrixTrackGeneratorDataSource, JSMatrixTrackGeneratorDelegate>

@property (nonatomic, strong) JSMatrixTrackGenerator *generator;
@property (nonatomic, strong) CALayer *containerLayer;
@end
