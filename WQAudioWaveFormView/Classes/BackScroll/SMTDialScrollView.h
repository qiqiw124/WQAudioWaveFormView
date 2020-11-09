//
//  SMTDialScrollView.h
//  TestDemo
//
//  Created by 祺祺 on 2020/7/2.
//  Copyright © 2020 祺祺. All rights reserved.
//
//刻度表滚动视图
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMTDialScrollView : UIView<UIAppearance>
/**
 * The current value in the scroll view
 */
@property (assign, nonatomic) float currentValue;

/**
 * The UIScrollViewDelegate for this class
 */
@property (assign, nonatomic) id<UIScrollViewDelegate> delegate;


#pragma mark - Generic Properties

/**
 * The number of minor ticks per major tick
 */
@property (assign, nonatomic) NSInteger minorTicksPerMajorTick UI_APPEARANCE_SELECTOR;

/**
 * The number of pixels/points between minor ticks
 */
@property (assign, nonatomic) NSInteger minorTickDistance UI_APPEARANCE_SELECTOR;

/**
 * The image to use as the background image
 */
@property (strong, nonatomic) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

/**
 * The image to overlay on top of the scroll dial
 */
@property (strong, nonatomic) UIColor *overlayColor UI_APPEARANCE_SELECTOR;


#pragma mark - Tick Label Properties

/**
 * The tick label stroke color
 */
@property (strong, nonatomic) UIColor *labelStrokeColor UI_APPEARANCE_SELECTOR;

/**
 * The width of the stroke line used to trace the Label text
 */
@property (assign, nonatomic) CGFloat labelStrokeWidth UI_APPEARANCE_SELECTOR;

/**
 * The tick label fill color
 */
@property (strong, nonatomic) UIColor *labelFillColor UI_APPEARANCE_SELECTOR;

/**
 * The tick label font
 */
@property (strong, nonatomic) UIFont *labelFont UI_APPEARANCE_SELECTOR;

#pragma mark - Minor Tick Properties

/**
 * The minor tick color
 */
@property (strong, nonatomic) UIColor *minorTickColor UI_APPEARANCE_SELECTOR;

/**
 * The length of the minor ticks
 */
@property (assign, nonatomic) CGFloat minorTickLength UI_APPEARANCE_SELECTOR;

/**
 * The length of the Major Tick
 */
@property (assign, nonatomic) CGFloat minorTickWidth UI_APPEARANCE_SELECTOR;

#pragma mark - Major Tick Properties

/**
 * The color of the Major Tick
 */
@property (strong, nonatomic) UIColor *majorTickColor UI_APPEARANCE_SELECTOR;

/**
 * The length of the Major Tick
 */
@property (assign, nonatomic) CGFloat majorTickLength UI_APPEARANCE_SELECTOR;

/**
 * The width of the Major Tick
 */
@property (assign, nonatomic) CGFloat majorTickWidth UI_APPEARANCE_SELECTOR;

#pragma mark - Shadow Properties

/**
 * The shadow color
 */
@property (strong, nonatomic) UIColor *shadowColor UI_APPEARANCE_SELECTOR;

/**
 * The shadow offset
 */
@property (assign, nonatomic) CGSize shadowOffset UI_APPEARANCE_SELECTOR;

/**
 * The shadow blur radius
 */
@property (assign, nonatomic) CGFloat shadowBlur UI_APPEARANCE_SELECTOR;

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
 设置滚动offset 以及当前选择的value
 */
-(void)setOffset:(float)offsetx currentValue:(float)newValue;


/**
 获取contentSize
 */
-(CGSize)contentSize;

/**
 获取 contentOffset
 */
-(CGPoint)contentOffset;
/**
 获取左侧偏移量
 */
-(NSInteger)leading;
/**
 获取宽度
 */
-(float)dialViewWidth;
@end

NS_ASSUME_NONNULL_END
