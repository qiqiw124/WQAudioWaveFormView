//
//  WQDialScrollView.h
//  TestDemo
//
//  Created by wqq on 2020/7/2.
//  Copyright © 2020 wqq. All rights reserved.
//
//刻度表滚动视图
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WQDialScrollView : UIView<UIAppearance>
/**
 * The UIScrollViewDelegate for this class
 */
@property (assign, nonatomic) id<UIScrollViewDelegate> delegate;


#pragma mark - Generic Properties

/**
 * The number of minor ticks per major tick
 */
@property (assign, nonatomic) NSInteger minorTicksPerMajorTick;

/**
 * The number of pixels/points between minor ticks
 */
@property (assign, nonatomic) NSInteger minorTickDistance;

/**
 * The image to use as the background image
 */
@property (strong, nonatomic) UIColor *backgroundColor;

/**
 * The image to overlay on top of the scroll dial
 */
@property (strong, nonatomic) UIColor *overlayColor;


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

@property (assign, nonatomic) CGFloat leading;

#pragma mark - Methods

/**
 * Method to set the range of values to display
 */
- (void)setDialRangeFrom:(float)from to:(float)to;
/**
 添加某个view
 */
-(void)insertWaveView:(UIView *)waveView;
-(void)initFactor:(float)factor;
/**
 重绘
 */
-(void)redrawView;
/**
 重新设置宽度
 */
-(void)resetDialViewWidth:(float)waveWidth;
/**
 获取contentSize
 */
-(CGSize)contentSize;

/**
 获取 contentOffset
 */
-(CGPoint)contentOffset;
/**
 获取宽度
 */
-(float)dialViewWidth;
@end

NS_ASSUME_NONNULL_END
