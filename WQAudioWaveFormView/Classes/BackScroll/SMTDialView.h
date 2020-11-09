//
//  SMTDialView.h
//  TestDemo
//
//  Created by 祺祺 on 2020/7/2.
//  Copyright © 2020 祺祺. All rights reserved.
//
//刻度表承载的view
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMTDialView : UIView<UIAppearance>
{
    int count;

}
#pragma mark - Methods

/**
 * 间隔相同，根据宽度绘制
 */
- (void)setDialRangeFrom:(float)from to:(float)to width:(CGFloat)width;

#pragma mark - Dial Properties
@property (assign, nonatomic) float factor;

@property (assign, nonatomic) CGFloat leading;

/**
 * The maximum value to display in the dial
 */
@property (assign, readonly, nonatomic) CGFloat minimum;

/**
 * The minimum value to display in the dial
 */
@property (assign, readonly, nonatomic) CGFloat maximum;

/**
 * The number of minor ticks per major tick
 */
@property (assign, nonatomic) NSInteger minorTicksPerMajorTick;

/**
 * The number of pixels/points between minor ticks
 */
@property (assign, nonatomic) CGFloat minorTickDistance;

/**
 * The image to use as the background image
 */
@property (strong, nonatomic) UIColor *backColor;

#pragma mark - Tick Label Properties

/**
 * The tick label stroke color
 */
@property (strong, nonatomic) UIColor *labelStrokeColor;

/**
 * The width of the stroke line used to trace the Label text
 */
@property (assign, nonatomic) CGFloat labelStrokeWidth;

/**
 * The tick label fill color
 */
@property (strong, nonatomic) UIColor *labelFillColor;

/**
 * The tick label font
 */
@property (strong, nonatomic) UIFont *labelFont;

#pragma mark - Minor Tick Properties

/**
 * The minor tick color
 */
@property (strong, nonatomic) UIColor *minorTickColor;

/**
 * The length of the minor ticks
 */
@property (assign, nonatomic) CGFloat minorTickLength;

/**
 * The length of the Major Tick
 */
@property (assign, nonatomic) CGFloat minorTickWidth;

#pragma mark - Major Tick Properties

/**
 * The color of the Major Tick
 */
@property (strong, nonatomic) UIColor *majorTickColor;

/**
 * The length of the Major Tick
 */
@property (assign, nonatomic) CGFloat majorTickLength;

/**
 * The width of the Major Tick
 */
@property (assign, nonatomic) CGFloat majorTickWidth;

#pragma mark - Shadow Properties

/**
 * The shadow color
 */
@property (strong, nonatomic) UIColor *shadowColor;

/**
 * The shadow offset
 */
@property (assign, nonatomic) CGSize shadowOffset;

/**
 * The shadow blur radius
 */
@property (assign, nonatomic) CGFloat shadowBlur;


-(void)initFactor:(float)factor;
-(void)redrawView;
@end

NS_ASSUME_NONNULL_END
